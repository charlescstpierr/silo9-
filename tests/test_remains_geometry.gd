extends SceneTree

const Visual = preload("res://scripts/robot_visual.gd")
var failures: int = 0

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func inverted_triangles(mesh: ArrayMesh) -> int:
	var inverted := 0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for triangle in range(0, indices.size(), 3):
			var a: int = indices[triangle]
			var b: int = indices[triangle + 1]
			var c: int = indices[triangle + 2]
			var geometric: Vector3 = (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
			if geometric.dot(normals[a] + normals[b] + normals[c]) > 0.000001:
				inverted += 1
	return inverted

func _initialize() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var resources: Dictionary = {}
	var materials: Dictionary = {}
	for crawler: bool in [false, true]:
		for repetition in 3:
			var trace := Node3D.new()
			scene.add_child(trace)
			Visual.build_remains(trace, crawler)
			var geometry := trace.find_children("*", "MeshInstance3D", true, false)
			check(not geometry.is_empty() and geometry.size() <= 3, "each remains silhouette uses at most three meshes")
			check(trace.find_children("*", "CollisionObject3D", true, false).is_empty() and trace.find_children("*", "Timer", true, false).is_empty() and trace.find_children("*", "Light3D", true, false).is_empty(), "remains have no collision, timer or light")
			check(not trace.is_processing() and not trace.is_physics_processing(), "remains have no per-frame callbacks")
			for instance: MeshInstance3D in geometry:
				var mesh := instance.mesh as ArrayMesh
				check(mesh != null and mesh.get_surface_count() == 1, "generated geometry is a single-surface ArrayMesh")
				if mesh == null: continue
				check(mesh.surface_get_array_index_len(0) > 0 and mesh.surface_get_array_index_len(0) % 3 == 0, "generated triangle index buffer is complete")
				check(inverted_triangles(mesh) == 0, "actual generated triangles agree with their outward normals")
				check(instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and instance.visibility_range_end == 45, "remains disable shadows and use 45m local visibility")
				resources[mesh.get_instance_id()] = mesh
				materials[instance.material_override.get_instance_id()] = true
	check(resources.size() <= 6 and materials.size() <= 3, "six carcasses share at most six meshes and three materials")
	var original: ArrayMesh = resources.values()[0]
	var arrays: Array = original.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for triangle in range(0, indices.size(), 3):
		var second: int = indices[triangle + 1]
		indices[triangle + 1] = indices[triangle + 2]
		indices[triangle + 2] = second
	arrays[Mesh.ARRAY_INDEX] = indices
	var reversed := ArrayMesh.new()
	reversed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	check(inverted_triangles(reversed) > 0, "negative control catches deliberately reversed real triangles")
	check(inverted_triangles(original) == 0, "negative control leaves shared mesh resource unchanged")
	scene.free()
	print("REMAINS GEOMETRY: ", failures, " failures")
	quit(1 if failures else 0)
