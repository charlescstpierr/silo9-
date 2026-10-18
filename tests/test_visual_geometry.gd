extends SceneTree
const Visual = preload("res://scripts/weapon_visual.gd")
func _initialize() -> void:
	var failures := 0
	for electric in [false, true]:
		var model := Visual.build(electric)
		for child: MeshInstance3D in model.get_children():
			var mesh := child.mesh
			var arrays := mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var used: Dictionary = {}
			for index in indices:
				used[index] = true
			var valid: bool = indices.size() == 0 or used.size() == vertices.size()
			for normal in normals:
				valid = valid and normal.is_finite() and absf(normal.length() - 1.0) < 0.01
			print("WEAPON ", electric, " surface ", child.get_index(), " vertices=", vertices.size(), " indices=", indices.size(), " referenced=", used.size(), " valid=", valid)
			if not valid:
				failures += 1
		model.free()
	print("GEOMETRY FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
