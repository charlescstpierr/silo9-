extends SceneTree

const Rig = preload("res://scripts/fps_rig.gd")
const HandMesh = preload("res://scripts/fps_hand_mesh.gd")
const State = preload("res://scripts/run_state.gd")
const REFERENCE := "res://tests/fixtures/fps_geometry_98f2d4a.json"
const FAMILIES := ["paint_d9", "paint_arc", "steel", "insulator", "contacts", "signal_d9", "signal_arc", "glove", "cloth"]
var failures := 0
var passes := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ", label)
	if ok: passes += 1
	else: failures += 1

func run() -> void:
	var rig := Rig.new()
	root.add_child(rig)
	var geometry := geometry_snapshot(rig)
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
	check(JSON.parse_string(JSON.stringify(geometry)) == reference.geometry, "expanded triangles, normals, skin weights/bones, transforms and markers preserve baseline")
	for slot in 2:
		var meshes := mesh_nodes(rig._weapons[slot])
		check(surface_count(meshes) <= [11, 18][slot], "weapon %d surface budget" % slot)
		inspect_uv(meshes, "weapon %d including mixed primitive batches" % slot, true)
	check(surface_count([rig.arms]) == 2, "arms retain two surfaces")
	inspect_uv([rig.arms], "actual glove and cloth", false)
	var vertices := 0
	var triangles := 0
	for surface in rig.arms.mesh.get_surface_count():
		var arrays := rig.arms.mesh.surface_get_arrays(surface)
		vertices += arrays[Mesh.ARRAY_VERTEX].size()
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
	check(vertices <= 24000 and triangles <= 16000, "arm vertex and triangle budgets")
	inspect_loft_seam()
	var second := Rig.new()
	root.add_child(second)
	var materials := materials_in(rig)
	var second_materials := materials_in(second)
	for id in second_materials: materials[id] = second_materials[id]
	inspect_materials(materials)
	second.free()
	var before := resource_snapshot(rig)
	var stable := true
	var frame := Rig.ViewFrame.new()
	for weapon in 2:
		rig.equip(weapon)
		var cycle := Rig.Reload.new()
		cycle.state = State.new()
		cycle.state.energy = 20
		cycle.weapon_index = weapon
		if weapon == 0: cycle.begin(true, 2.6, 3.25)
		else: check(cycle.request_cell(true), "cell manipulation starts")
		for tick in 90:
			cycle.advance(.05, true)
			frame.reload = cycle.view
			frame.aim_weight = float(tick % 30) / 29.0
			frame.energy = cycle.state.energy
			rig.update_visual(.05, frame)
			stable = stable and resource_snapshot(rig) == before
	check(stable, "mesh/material/texture identities and stored material properties remain stable through reload, cell, ADS and equip")
	rig.free()
	await process_frame
	print("FPS MATERIALS passes=", passes, " failures=", failures)
	quit(1 if failures else 0)

func mesh_nodes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): result.append_array(mesh_nodes(child))
	return result

func surface_count(nodes: Array) -> int:
	var count := 0
	for node: MeshInstance3D in nodes: count += node.mesh.get_surface_count()
	return count

func inspect_uv(nodes: Array, label: String, check_faces: bool) -> void:
	var missing := 0
	var nonfinite := 0
	var collapsed := 0
	var discontinuous := 0
	for node: MeshInstance3D in nodes:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			if uv.size() != vertices.size():
				missing += 1
				continue
			for point in uv:
				if not point.is_finite(): nonfinite += 1
			var face_points := {}
			for offset in range(0, indices.size(), 3):
				var a := indices[offset]
				var b := indices[offset + 1]
				var c := indices[offset + 2]
				if absf((uv[b] - uv[a]).cross(uv[c] - uv[a])) <= 1e-12: collapsed += 1
				# Native cylinder seams are intentional; only flat-shaded faces share a projection.
				if not check_faces or not normals[a].is_equal_approx(normals[b]) or not normals[a].is_equal_approx(normals[c]): continue
				for index in [a, b, c]:
					var key := str(quantized([vertices[index], normals[index]]))
					if face_points.has(key) and uv[index].distance_to(face_points[key]) > .00001: discontinuous += 1
					face_points[key] = uv[index]
	check(missing == 0, "%s UV cardinality (missing surfaces=%d)" % [label, missing])
	check(missing == 0 and nonfinite == 0 and collapsed == 0, "%s finite, nondegenerate mapping (bad values=%d, collapsed triangles=%d)" % [label, nonfinite, collapsed])
	if check_faces: check(missing == 0 and discontinuous == 0, "%s shared flat-face UV continuity (conflicts=%d)" % [label, discontinuous])

func inspect_loft_seam() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	HandMesh._loft(tool, [Vector3.ZERO, Vector3(0, .1, 0), Vector3(0, .25, 0)], [Vector2(.04, .03), Vector2(.035, .025), Vector2(.03, .02)], [1, 2, 3], Transform3D.IDENTITY)
	tool.index()
	var mesh := tool.commit()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var mapped := uv.size() == vertices.size()
	var ring_uv: Array[Dictionary] = [{}, {}, {}]
	var narrow := mapped
	var length_ratio := false
	if mapped:
		for i in vertices.size():
			# Ignore caps: they have axial normals and intentionally independent planar UVs.
			if absf(arrays[Mesh.ARRAY_NORMAL][i].y) > .5: continue
			var ring := 0 if is_zero_approx(vertices[i].y) else (1 if vertices[i].y < .2 else 2)
			var point := str(quantized([vertices[i]]))
			if not ring_uv[ring].has(point): ring_uv[ring][point] = []
			ring_uv[ring][point].append(uv[i])
		for offset in range(0, indices.size(), 3):
			var a := indices[offset]
			var b := indices[offset + 1]
			var c := indices[offset + 2]
			if absf(arrays[Mesh.ARRAY_NORMAL][a].y) > .5: continue
			var span := maxf(uv[a].x, maxf(uv[b].x, uv[c].x)) - minf(uv[a].x, minf(uv[b].x, uv[c].x))
			narrow = narrow and span > 0 and span <= .25
		var v0: Vector2 = ring_uv[0].values()[0][0]
		var v1: Vector2 = ring_uv[1].values()[0][0]
		var v2: Vector2 = ring_uv[2].values()[0][0]
		length_ratio = absf((v1.y - v0.y) * 1.5 - (v2.y - v1.y)) < .00001 and absf(v1.y - v0.y) > .00001
	var seams := 0
	for ring: Dictionary in ring_uv:
		for values: Array in ring.values():
			var min_u := INF
			var max_u := -INF
			for point: Vector2 in values:
				min_u = minf(min_u, point.x)
				max_u = maxf(max_u, point.x)
			if is_equal_approx(max_u - min_u, 1.0): seams += 1
	check(mapped and seams == 3 and narrow, "loft duplicates each ring seam and last angular slice stays narrow")
	check(length_ratio, "loft longitudinal UV follows unequal rest lengths")

func materials_in(rig: Node) -> Dictionary:
	var materials := {}
	for node in mesh_nodes(rig):
		for surface in node.mesh.get_surface_count():
			var material := node.get_active_material(surface)
			materials[material.get_instance_id()] = material
	return materials

func inspect_materials(materials: Dictionary) -> void:
	var families: Array[String] = []
	var textures := {}
	var native_opaque := true
	var ordinary_dark := true
	var signal_emission := true
	var metal_split := true
	for material: Material in materials.values():
		if not material is StandardMaterial3D:
			native_opaque = false
			continue
		var name := material.resource_path.get_file().get_basename()
		if not families.has(name): families.append(name)
		native_opaque = native_opaque and material.next_pass == null and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not material.normal_enabled and not material.ao_enabled
		if name.begins_with("signal_"):
			signal_emission = signal_emission and material.emission_enabled and is_equal_approx(material.emission_energy_multiplier, .8)
		else:
			ordinary_dark = ordinary_dark and (not material.emission_enabled or material.emission_energy_multiplier == 0 or material.emission == Color.BLACK)
		if name in ["steel", "contacts"]: metal_split = metal_split and material.metallic > 0
		elif name in ["paint_d9", "paint_arc", "insulator", "glove", "cloth"]: metal_split = metal_split and material.metallic == 0
		for property: Dictionary in material.get_property_list():
			var value: Variant = material.get(property.name)
			if value is Texture2D: textures[value.get_instance_id()] = value
	check(materials.size() <= 9, "at most nine shared materials across two independently built rigs (actual=%d)" % materials.size())
	check(families.size() == FAMILIES.size() and FAMILIES.all(func(name: String) -> bool: return name in families), "nine authored material families actually bound to meshes")
	check(native_opaque, "native opaque materials without extra passes, AO or normal maps")
	check(ordinary_dark, "ordinary materials add no unlit emission")
	check(signal_emission and "signal_d9" in families and "signal_arc" in families, "D9 and ARC signals retain .8 emission")
	check(metal_split and "steel" in families and "contacts" in families, "metal and dielectric families retain distinct physical response")
	var dimensions_ok := true
	var texel_bytes := 0
	for texture: Texture2D in textures.values():
		var width := texture.get_width()
		var height := texture.get_height()
		dimensions_ok = dimensions_ok and width > 0 and height > 0 and width <= 256 and height <= 256
		while width > 0 and height > 0:
			texel_bytes += width * height * 4
			if width == 1 and height == 1: break
			width = maxi(1, width / 2)
			height = maxi(1, height / 2)
	check(textures.size() <= 6 and dimensions_ok and texel_bytes <= 2.1 * 1024 * 1024, "unique texture dimensions/count and conservative RGBA8 full-mip texel budget")
	print("TEXTURES unique=", textures.size(), " estimated_full_mip_bytes=", texel_bytes, " (not measured VRAM; mip presence requires renderer evidence)")

func resource_snapshot(rig: Node) -> Dictionary:
	var snapshot := {}
	for node in mesh_nodes(rig): snapshot[str(node.get_instance_id())] = node.mesh.get_instance_id()
	var materials := materials_in(rig)
	for id in materials:
		var material: Material = materials[id]
		var properties := {}
		for property: Dictionary in material.get_property_list():
			if not property.usage & PROPERTY_USAGE_STORAGE: continue
			var value: Variant = material.get(property.name)
			properties[property.name] = value.get_instance_id() if value is Resource else value
		snapshot[str(id)] = properties
	return snapshot

func quantized(values: Array) -> PackedInt64Array:
	var result := PackedInt64Array()
	for value: Variant in values:
		if value is Vector3:
			for component in [value.x, value.y, value.z]: result.append(roundi(component * 1000000))
		elif value is Transform3D:
			result.append_array(quantized([value.basis.x, value.basis.y, value.basis.z, value.origin]))
		else: result.append(roundi(float(value) * 1000000))
	return result

func geometry_snapshot(rig: Node) -> Dictionary:
	var snapshot := {}
	capture_node(rig, "rig", snapshot)
	return snapshot

func capture_node(node: Node, path: String, snapshot: Dictionary) -> void:
	if node is Node3D: snapshot[path] = str(quantized([node.transform]))
	if node is Marker3D: snapshot[path + "/marker"] = str(node.name)
	if node is Skeleton3D:
		for bone in node.get_bone_count():
			snapshot[path + "/bone%d" % bone] = [str(node.get_bone_name(bone)), node.get_bone_parent(bone), str(quantized([node.get_bone_rest(bone)]))]
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var expanded := PackedInt64Array()
			for index: int in arrays[Mesh.ARRAY_INDEX]:
				expanded.append_array(quantized([arrays[Mesh.ARRAY_VERTEX][index], arrays[Mesh.ARRAY_NORMAL][index]]))
				if arrays[Mesh.ARRAY_BONES] != null:
					for influence in 4:
						expanded.append(arrays[Mesh.ARRAY_BONES][index * 4 + influence])
						expanded.append_array(quantized([arrays[Mesh.ARRAY_WEIGHTS][index * 4 + influence]]))
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(expanded.to_byte_array())
			snapshot[path + "/surface%d" % surface] = {"expanded_indices": arrays[Mesh.ARRAY_INDEX].size(), "geometry_sha256": hash.finish().hex_encode()}
	for index in node.get_child_count(): capture_node(node.get_child(index), path + "/%d" % index, snapshot)
