extends SceneTree
const Visual = preload("res://scripts/robot_visual.gd")
func _initialize() -> void:
	Visual._prepare()
	var failures := 0
	for crawler: bool in [false, true]:
		for label: String in ["legs", "remains"]:
			var meshes: Array[ArrayMesh] = Visual._leg_geometry(crawler) if label == "legs" else Visual._remains_geometry(crawler)
			var positive := 0
			var negative := 0
			for mesh: ArrayMesh in meshes:
				var arrays := mesh.surface_get_arrays(0)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				for triangle in range(0, indices.size(), 3):
					var a: int = indices[triangle]
					var b: int = indices[triangle + 1]
					var c: int = indices[triangle + 2]
					var dot: float = (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).dot(normals[a] + normals[b] + normals[c])
					if dot > 0.000001: positive += 1
					if dot < -0.000001: negative += 1
			print(crawler, " ", label, " positive=", positive, " negative=", negative)
			if positive > 0: failures += 1
	print("WINDING: ", failures, " failures")
	quit(1 if failures else 0)
