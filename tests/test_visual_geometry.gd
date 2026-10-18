extends SceneTree
const Visual = preload("res://scripts/weapon_visual.gd")
const Rig = preload("res://scripts/fps_rig.gd")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for electric in [false,true]:
		var model := Visual.build(electric)
		inspect(model,0)
		model.free()
	var rig := Rig.new()
	root.add_child(rig)
	await process_frame
	var count := inspect(rig.arms,rig.skeleton.get_bone_count())
	if count.x > 24000 or count.y > 16000 or rig.arms.mesh.get_surface_count() != 2:
		failures += 1
	print("HANDS vertices=",count.x," triangles=",count.y," bones=",rig.skeleton.get_bone_count()," surfaces=",rig.arms.mesh.get_surface_count())
	rig.queue_free()
	await process_frame
	print("GEOMETRY FAILURES: ",failures)
	quit(1 if failures else 0)
func inspect(node: Node, bone_count: int) -> Vector2i:
	var total := Vector2i.ZERO
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var valid := not vertices.is_empty() and not indices.is_empty() and indices.size()%3 == 0
			var used := {}
			for index in indices:
				valid = valid and index >= 0 and index < vertices.size()
				used[index] = true
			if used.size() != vertices.size():
				print("UNREFERENCED ",node.name," ",vertices.size()-used.size())
			valid = valid and used.size() == vertices.size()
			for vertex in vertices:
				valid = valid and vertex.is_finite()
			for normal in normals:
				valid = valid and normal.is_finite() and absf(normal.length()-1) < .01
			if valid:
				for triangle in range(0,indices.size(),3):
					var a := vertices[indices[triangle]]
					var b := vertices[indices[triangle+1]]
					var c := vertices[indices[triangle+2]]
					if (b-a).cross(c-a).length_squared() <= 1e-16:
						print("DEGENERATE ", node.name, " ",triangle," points=",a,b,c)
					valid = valid and (b-a).cross(c-a).length_squared() > 1e-16
			if bone_count > 0:
				var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				valid = valid and bones.size() == vertices.size()*4 and weights.size() == bones.size()
				for vertex in vertices.size():
					var weight_sum := 0.0
					for influence in 4:
						var offset := vertex*4+influence
						valid = valid and bones[offset]>=0 and bones[offset]<bone_count and is_finite(weights[offset]) and weights[offset]>=0
						weight_sum += weights[offset]
					valid = valid and absf(weight_sum-1)<.0001
			if not valid:
				print("FAIL: invalid geometry ",node.name," surface=",surface)
				failures += 1
			total += Vector2i(vertices.size(),indices.size()/3)
	for child in node.get_children():
		total += inspect(child,bone_count)
	return total
