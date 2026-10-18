class_name SiloWorldArt
extends Node3D

const Spec = preload("res://scripts/data/circuit_spec.gd")
const PowerMaterials = preload("res://scripts/data/power_materials.gd")
var power_materials: PowerMaterials
var palette: Dictionary = {}
var batches: Dictionary = {}
var asset_batches: Dictionary = {}
var prepared_meshes: Dictionary = {}
var prepared_materials: Dictionary = {}
var surfaces: Dictionary = {}
var decor_groups: Array[MeshInstance3D] = []
var core_rotor: Node3D
var mesh_box := BoxMesh.new()
var mesh_pipe := CylinderMesh.new()
var mesh_ring := TorusMesh.new()
var textured_materials: Array[StandardMaterial3D] = []
var original_roughness: Dictionary = {}
var original_normal: Dictionary = {}

func prepare_materials(base: Dictionary) -> void:
	palette = base
	for key in ["wall", "floor", "steel", "dark", "yellow", "teal"]:
		var kind: String = "panel" if key == "wall" else ("deck" if key == "floor" else "alloy")
		var material: StandardMaterial3D = base[key]
		var tint: Color = material.albedo_color
		if kind == "alloy":
			material.roughness = 0.75
			material.metallic = 0.12
			continue
		material.albedo_color = Color.WHITE if key in ["wall", "floor", "steel"] else tint.lightened(0.2)
		material.albedo_texture = load("res://assets/industrial/painted_panel_v2.png") if key == "wall" else load("res://assets/industrial/" + kind + "_albedo.png")
		material.normal_enabled = key != "wall"
		material.normal_texture = null if key == "wall" else load("res://assets/industrial/" + kind + "_normal.png")
		material.normal_scale = 0.35
		material.roughness_texture = null if key == "wall" else load("res://assets/industrial/" + kind + "_roughness.png")
		material.roughness = 0.8
		material.metallic = 0.32
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * (0.45 if key == "wall" else 0.7)
		textured_materials.append(material)
	var grate := StandardMaterial3D.new()
	grate.albedo_texture = load("res://assets/industrial/grate_albedo.png")
	grate.normal_enabled = true
	grate.normal_texture = load("res://assets/industrial/grate_normal.png")
	grate.normal_scale = 0.3
	grate.roughness = 0.8
	grate.metallic = 0.3
	grate.uv1_triplanar = true
	grate.uv1_world_triplanar = true
	grate.uv1_scale = Vector3.ONE
	palette["grate"] = grate
	textured_materials.append(grate)
	for entry in [["paint", "e1d4ad"], ["rust", "ed8741"], ["rubber", "142b48"]]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(entry[1])
		material.roughness = 0.88
		palette[entry[0]] = material

func build() -> void:
	mesh_pipe.top_radius = 0.5
	mesh_pipe.bottom_radius = 0.5
	mesh_pipe.height = 1.0
	mesh_pipe.radial_segments = 12
	mesh_pipe.rings = 1
	mesh_ring.inner_radius = 0.84
	mesh_ring.outer_radius = 1.0
	mesh_ring.rings = 32
	mesh_ring.ring_segments = 6
	_floor_plane()
	_room_shells()
	_lift_panels()
	_walls_and_deck()
	_frames()
	_machines()
	_reactor()
	_flush()
	_flush_assets()
	_commit_surfaces()

func _part(shape: String, pos: Vector3, size: Vector3, material: String, angles: Vector3 = Vector3.ZERO) -> void:
	var bucket: int = clampi(int((-pos.z + 10.0) / 20.0), 0, 4)
	var key: String = str(bucket) + ":" + shape + ":" + material + ":" + str(Spec.at_z(pos.z))
	if not batches.has(key): batches[key] = []
	var basis := Basis.from_euler(angles).scaled_local(size)
	batches[key].append(Transform3D(basis, pos))

func _asset(name: String, pos: Vector3, scale_value: Vector3 = Vector3.ONE, angles: Vector3 = Vector3.ZERO) -> void:
	var bucket: int = clampi(int((-pos.z + 10.0) / 20.0), 0, 4)
	var key: String = str(bucket) + ":" + name + ":" + str(Spec.at_z(pos.z))
	if not asset_batches.has(key): asset_batches[key] = []
	asset_batches[key].append(Transform3D(Basis.from_euler(angles).scaled_local(scale_value), pos))

func _floor_plane() -> void:
	var material: StandardMaterial3D = palette["floor"].duplicate()
	material.uv1_triplanar = false
	material.uv1_world_triplanar = false
	material.uv1_scale = Vector3.ONE
	textured_materials.append(material)
	for section in [Vector2(6,8),Vector2(-6,16),Vector2(-24,20),Vector2(-44,20),Vector2(-66,24)]:
		var plane := PlaneMesh.new()
		plane.size = Vector2(20,section.y)
		var arrays: Array = plane.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv := PackedVector2Array()
		for vertex in vertices:
			uv.append(Vector2((vertex.x + 10) * 0.7, (vertex.z + section.x + 78) * 0.7))
		arrays[Mesh.ARRAY_TEX_UV] = uv
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.material_override = material
		instance.position = Vector3(0,0.005,section.x)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func _room_shells() -> void:
	for section in [Vector2(6,8),Vector2(-6,16),Vector2(-24,20),Vector2(-44,20),Vector2(-66,24)]:
		for side in [-1.0,0.0,1.0]:
			var shell := MeshInstance3D.new()
			shell.mesh = mesh_box
			shell.position = Vector3(side * 10,5.2 if side == 0 else 2.5,section.x)
			shell.scale = Vector3(20,0.4,section.y) if side == 0 else Vector3(0.5,5,section.y)
			shell.material_override = palette["dark"] if side == 0 else palette["wall"]
			add_child(shell)

func _lift_panels() -> void:
	for side in [-1.0,1.0]:
		for z in [3.6,5.8,8.0]:
			_part("box", Vector3(side * 4.575,2.1,z), Vector3(0.06,3.7,1.9), "wall")
		for z in [2.6,4.7,6.9,9.2]:
			_part("box", Vector3(side * 4.5,2.2,z), Vector3(0.2,4.0,0.14), "steel")
		_part("box", Vector3(side * 4.53,0.4,6), Vector3(0.12,0.45,7.2), "rubber")
		_part("box", Vector3(side * 4.5,4.05,6), Vector3(0.2,0.16,7.3), "steel")
		_part("box", Vector3(side * 4.45,2.95,6), Vector3(0.08,0.05,6.6), "cyan")
	_part("box", Vector3(4.43,1.5,4), Vector3(0.1,2.2,1.5), "rubber")
	_part("box", Vector3(4.35,2.5,4), Vector3(0.2,0.12,1.7), "steel")
	_part("box", Vector3(4.3,2.38,4), Vector3(0.08,0.06,1.25), "cyan")

func _walls_and_deck() -> void:
	for z in range(-76, 1, 4):
		for side in [-1.0, 1.0]:
			var angle: float = PI if side > 0 else 0.0
			var wall_name: String = "WallAstra_Straight_Window" if z > -14 else "WallAstra_Straight"
			_asset(wall_name, Vector3(side * (7.65 if z > -14 else 8.1), 0, z), Vector3.ONE, Vector3(0,angle,0))
			if z < -14 and z > -34:
				_asset("TopCables_Straight", Vector3(side * 7.7,0,z), Vector3.ONE, Vector3(0,angle,0))
			else:
				_part("box", Vector3(side * 9.55,3.8,z), Vector3(0.12,1.1,3.7), "grate")
			_part("box", Vector3(side * 9.4,0.25,z), Vector3(0.26,0.5,3.9), "rubber")
			_part("box", Vector3(side * 9.5,3.05,z), Vector3(0.3,0.2,3.9), "steel")
			_part("box", Vector3(side * 4.2,4.58,z), Vector3(1.0,0.12,3.9), "grate")
			for dz in [-1.6,1.6]:
				_part("box", Vector3(side * 4.2,4.75,z + dz), Vector3(1.25,0.09,0.12), "steel")
			if z % 8 == 0:
				_part("box", Vector3(side * 4.75,4.25,z), Vector3(0.12,1.2,0.12), "steel")
			_part("pipe", Vector3(side * 8.6,3.7,z), Vector3(0.28,4.0,0.28), "teal", Vector3(PI/2,0,0))
			_part("pipe", Vector3(side * 8.6,4.15,z), Vector3(0.38,4.0,0.38), "steel", Vector3(PI/2,0,0))
			_part("pipe", Vector3(side * 8.6,4.15,z + 1.8), Vector3(0.5,0.14,0.5), "rubber", Vector3(PI/2,0,0))
		if z < -54:
			_part("box", Vector3(0,0.018,z), Vector3(3.8,0.025,3.85), "grate")
	for z in [6,-5,-22,-42,-63,-73]:
		_part("box", Vector3(0,4.82,z), Vector3(4.35,0.24,0.65), "rubber")
		for x in [-1.6,-0.8,0.0,0.8,1.6]:
			_part("box", Vector3(x,4.62,z), Vector3(0.045,0.12,0.45), "steel")

func _frames() -> void:
	for z in [2.0,-14.0,-34.0,-54.0]:
		_asset("Door_Frame_SquareTall", Vector3(0,-0.6,z), Vector3(2.05,1.05,1.0))
		for side in [-1.0,1.0]:
			for x in [4.3,6.6,8.8]:
				_part("box", Vector3(side * x,1.9,z + 0.3), Vector3(2.0,3.4,0.12), "wall")
				_part("box", Vector3(side * x,0.37,z + 0.4), Vector3(1.8,0.2,0.1), "rubber")
				_part("box", Vector3(side * x,3.35,z + 0.4), Vector3(1.8,0.12,0.12), "steel")
			_asset("Prop_Vent_Big", Vector3(side * 6.3,1.6,z + 0.42), Vector3.ONE, Vector3(PI/2,0,0))

func _machines() -> void:
	for z in [-6,-19,-29,-40,-49,-62]:
		var side: float = -1.0 if int(z) % 2 == 0 else 1.0
		for edge in [-1.05,1.05]:
			_part("box", Vector3(side * 6.6 + edge,0.8,z + 1.29), Vector3(0.07,1.4,0.05), "steel")
		_part("box", Vector3(side * 6.6,1.65,z), Vector3(2.35,0.08,2.55), "grate")
		_asset("Prop_Computer", Vector3(side * 6.6,1.68,z), Vector3(0.8,0.8,0.8))
		_part("pipe", Vector3(side * 7.2,2.8,z - 0.7), Vector3(0.14,2.3,0.14), "rust")
	_part("pipe", Vector3(6.6,1.97,-29.4), Vector3(0.55,1.45,0.55), "steel", Vector3(0,0,PI/2))
	for x in [5.95,7.25]:
		_part("pipe", Vector3(x,1.97,-29.4), Vector3(0.72,0.16,0.72), "yellow", Vector3(0,0,PI/2))
	_part("box", Vector3(6.15,1.82,-28.25), Vector3(0.6,0.28,0.4), "yellow", Vector3(0,-0.25,0))
	_part("box", Vector3(6.15,2.08,-28.25), Vector3(0.09,0.28,0.55), "steel", Vector3(0,-0.25,0))
	_part("box", Vector3(7.1,1.76,-28.55), Vector3(0.75,0.14,0.15), "steel", Vector3(0,0.6,0))
	_part("box", Vector3(7.35,1.79,-28.72), Vector3(0.3,0.14,0.35), "yellow", Vector3(0,0.6,0))
	for x in [5.5,7.7]:
		for z in [-29.9,-28.1]:
			_part("pipe", Vector3(x,0.22,z), Vector3(0.38,0.16,0.38), "rubber", Vector3(0,0,PI/2))
	_part("box", Vector3(5.8,1.72,-29.3), Vector3(0.6,0.12,0.75), "steel")
	for x in [5.5,6.1]:
		_part("box", Vector3(x,1.98,-29.3), Vector3(0.06,0.45,0.75), "yellow")
	_part("box", Vector3(5.8,1.98,-29.65), Vector3(0.6,0.45,0.06), "yellow")
	_part("pipe", Vector3(5.8,1.93,-29.3), Vector3(0.22,0.3,0.22), "teal")
	_part("pipe", Vector3(7.6,2.8,-27.2), Vector3(0.12,3.3,0.12), "rust", Vector3(PI/2,0,0))
	_part("box", Vector3(4.8,4.7,-27), Vector3(1.5,0.2,0.45), "rubber")
	_part("box", Vector3(4.8,4.57,-27), Vector3(1.3,0.06,0.24), "glow")
	for side in [-1.0,1.0]:
		for z in [-38,-46,-51]:
			for y in [0.55,1.25,1.95,2.65]:
				_part("box", Vector3(side * 8.28,y,z), Vector3(0.05,0.55,2.4), "grate")
				for dz in [-0.85,-0.6,-0.35]:
					_part("box", Vector3(side * 8.23,y + 0.14,z + dz), Vector3(0.06,0.04,0.07), "cyan")
	for z in [-20,-28]:
		for side in [-1.0,1.0]:
			_part("pipe", Vector3(side * 8.9,1.25,z), Vector3(0.65,2.5,0.65), "steel")
			for y in [0.2,2.2]:
				_part("pipe", Vector3(side * 8.9,y,z), Vector3(0.78,0.13,0.78), "yellow")
	for z in [-4,-10]:
		for side in [-1.0,1.0]:
			_part("box", Vector3(side * 9.5,1.1,z), Vector3(0.15,1.7,2.8), "paint")
			_part("box", Vector3(side * 9.4,1.1,z), Vector3(0.06,0.18,2.8), "teal")

func _reactor() -> void:
	for side in [-1.0,1.0]:
		for z in [-63,-68,-74]:
			for y in [0.15,0.6,3.8,4.25]:
				_part("ring", Vector3(side * 7.5,y,z), Vector3(1.35,1.1,1.35), "steel")
			for x in [-0.75,0.75]:
				_part("pipe", Vector3(side * 7.5+x,2.2,z + 1.08), Vector3(0.12,3.9,0.12), "steel")
			_part("box", Vector3(side * 7.5,2.2,z+1.04), Vector3(1.55,3.4,0.08), "grate")
			_part("box", Vector3(side * 7.5,2.2,z+1.1), Vector3(0.08,3.0,0.09), "danger")
	for y in [0.7,2.4,3.6]:
		_part("ring", Vector3(0,y,-72), Vector3(1.35,0.7,1.35), "steel")
	for angle in [0.0,PI/2,PI,PI*1.5]:
		var x: float = sin(angle)*1.3
		var z: float = -72 + cos(angle)*1.3
		_part("pipe", Vector3(x,2.1,z), Vector3(0.12,2.9,0.12), "steel")
	_part("pipe", Vector3(0,4.3,-72), Vector3(0.65,1.4,0.65), "steel")
	_part("ring", Vector3(0,0.62,-72), Vector3(1.6,0.5,1.6), "cyan")
	_part("box", Vector3(0,3.5,-77.65), Vector3(8.5,2.6,0.12), "grate")

func _flush() -> void:
	for key: String in batches:
		var parts: PackedStringArray = key.split(":")
		var mesh: Mesh = mesh_box if parts[1] == "box" else (mesh_pipe if parts[1] == "pipe" else mesh_ring)
		_make_batch(mesh, batches[key], int(parts[0]), palette[parts[2]], parts[2] not in ["glow","cyan","danger","floor","wall","grate"], StringName(parts[3]))
	batches.clear()

func _make_batch(mesh: Mesh, transforms: Array, bucket: int, material: Material = null, casts_shadow: bool = true, circuit: StringName = &"") -> void:
	var origin := Vector3(0,0,-bucket*20.0)
	for surface in mesh.get_surface_count():
		var surface_material: Material = material if material != null else mesh.surface_get_material(surface)
		if surface_material == null: continue
		surface_material = power_materials.for_sector(surface_material, circuit)
		var key: String = str(bucket) + ":" + str(surface_material.get_instance_id()) + ":" + str(casts_shadow)
		if not surfaces.has(key):
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			builder.set_material(surface_material)
			surfaces[key] = {"builder":builder,"origin":origin,"shadow":casts_shadow}
		var builder: SurfaceTool = surfaces[key].builder
		for transform: Transform3D in transforms:
			var local: Transform3D = transform
			local.origin -= origin
			builder.append_from(mesh, surface, local)

func _commit_surfaces() -> void:
	for record: Dictionary in surfaces.values():
		var builder: SurfaceTool = record.builder
		var instance := MeshInstance3D.new()
		instance.mesh = builder.commit()
		instance.position = record.origin
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if record.shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = 44.0
		add_child(instance)
		decor_groups.append(instance)
	surfaces.clear()

func _flush_assets() -> void:
	for key: String in asset_batches:
		var parts: PackedStringArray = key.split(":")
		var path: String = "res://assets/quaternius/" + parts[1] + ".gltf"
		if not ResourceLoader.exists(path): continue
		var scene := load(path) as PackedScene
		if scene == null: continue
		var source := scene.instantiate()
		for child in source.find_children("*", "MeshInstance3D", true, false):
			var source_transform: Transform3D = child.transform
			var ancestor: Node = child.get_parent()
			while ancestor != source and ancestor is Node3D:
				source_transform = ancestor.transform * source_transform
				ancestor = ancestor.get_parent()
			var transforms: Array = []
			for transform: Transform3D in asset_batches[key]:
				transforms.append(transform * source_transform)
			_make_batch(_local_mesh(child.mesh), transforms, int(parts[0]), null, not parts[1].begins_with("Wall"), StringName(parts[2]))
		source.free()
	asset_batches.clear()

func _local_mesh(source: Mesh) -> Mesh:
	if prepared_meshes.has(source): return prepared_meshes[source]
	var copy: Mesh = source.duplicate()
	for surface in source.get_surface_count():
		var material: Material = source.surface_get_material(surface)
		if material is StandardMaterial3D:
			copy.surface_set_material(surface, _local_material(material))
	prepared_meshes[source] = copy
	return copy

func _local_material(source: StandardMaterial3D) -> StandardMaterial3D:
	var normal_path: String = source.normal_texture.resource_path if source.normal_texture != null else ""
	var albedo_path: String = source.albedo_texture.resource_path if source.albedo_texture != null else ""
	var key: String = source.resource_name + "|" + normal_path + "|" + albedo_path
	if prepared_materials.has(key): return prepared_materials[key]
	var local: StandardMaterial3D = source.duplicate()
	var name: String = source.resource_name
	if name.contains("Trim"):
		local.albedo_texture = null
		local.roughness_texture = null
		local.metallic_texture = null
		local.ao_enabled = false
		local.metallic = 0.08
		local.roughness = 0.8
		local.normal_scale = 0.25
		local.albedo_color = Color("397ca0")
		if name.contains("02"): local.albedo_color = Color("ed8741")
		if name.contains("03"): local.albedo_color = Color("8ab7c5")
		if name.contains("Dark"): local.albedo_color = Color("142b48")
		if name.contains("Cables"): local.albedo_color = Color("5fe0cf")
	textured_materials.append(local)
	prepared_materials[key] = local
	return local

func build_console(parent: Node3D) -> void:
	var scene := load("res://assets/quaternius/Prop_Computer.gltf") as PackedScene
	if scene == null: return
	for child in parent.get_children():
		if child is MeshInstance3D: child.queue_free()
	var console := scene.instantiate() as Node3D
	console.position = Vector3(0,0.1,-0.025)
	console.scale = Vector3(0.85,0.68,0.72)
	for child in console.find_children("*", "MeshInstance3D", true, false):
		child.mesh = _local_mesh(child.mesh)
	parent.add_child(console)

func build_core(parent: Node3D) -> void:
	for child in parent.get_children():
		if child is MeshInstance3D: child.queue_free()
	core_rotor = Node3D.new()
	core_rotor.position.y = 0.7
	parent.add_child(core_rotor)
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.27
	sphere.height = 0.54
	sphere.radial_segments = 20
	sphere.rings = 10
	orb.mesh = sphere
	orb.material_override = palette["cyan"]
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core_rotor.add_child(orb)
	for angle in [0.0,PI/2]:
		var bracket := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.3
		ring.outer_radius = 0.35
		ring.rings = 24
		ring.ring_segments = 6
		bracket.mesh = ring
		bracket.material_override = palette["steel"]
		bracket.rotation = Vector3(PI/2,angle,0)
		core_rotor.add_child(bracket)

func _process(delta: float) -> void:
	if is_instance_valid(core_rotor) and core_rotor.is_visible_in_tree():
		core_rotor.rotation.y += delta * 0.35

func set_quality(low: bool) -> void:
	for group in decor_groups:
		group.visibility_range_end = 32.0 if low else 44.0
	for material in textured_materials:
		if not original_roughness.has(material):
			original_roughness[material] = material.roughness_texture
			original_normal[material] = material.normal_enabled
		material.normal_enabled = original_normal[material] and not low
		material.roughness_texture = null if low else original_roughness[material]
