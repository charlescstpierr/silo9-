class_name SiloFpsHandMesh
extends RefCounted

const SIDES := 12
const GLOVE = preload("res://assets/fps/materials/glove.tres")
const CLOTH = preload("res://assets/fps/materials/cloth.tres")

static func build(skeleton: Skeleton3D, wrists: Array[Transform3D], elbows: Array[Vector3], shoulders: Array[Vector3]) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	for surface_index in 2:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.set_material(GLOVE if surface_index == 0 else CLOTH)
		for side in 2:
			var base := 1 + side * 17
			var wrist := wrists[side]
			var elbow_local := wrist.affine_inverse() * elbows[side]
			if surface_index == 1:
				var centers: Array[Vector3] = []
				var sizes: Array[Vector2] = []
				var bones: Array[int] = []
				var shoulder_local := wrist.affine_inverse() * shoulders[side]
				for i in 6:
					var t := float(i) / 6.0
					centers.append(shoulder_local.lerp(elbow_local,t))
					sizes.append(Vector2(.062,.055).lerp(Vector2(.049,.042),t))
					bones.append(base)
				for i in 9:
					var t := float(i) / 8.0
					centers.append(elbow_local.lerp(Vector3(0,-0.025,0),t))
					sizes.append(Vector2(0.049,0.042).lerp(Vector2(0.034,0.025),t) * (1.0 + sin(t * PI * 5.0) * 0.025))
					bones.append(base+1)
				_loft(tool, centers, sizes, bones, wrist, true)
			else:
				var centers: Array[Vector3] = [Vector3(0,-0.025,0),Vector3.ZERO,Vector3(0,0.019,0.002),Vector3(0,0.043,0),Vector3(0,0.065,0),Vector3(0,0.073,0)]
				var sizes: Array[Vector2] = [Vector2(.034,.025),Vector2(.031,.022),Vector2(.039,.023),Vector2(.042,.022),Vector2(.040,.019),Vector2(.034,.014)]
				var bones: Array[int] = [base+1,base+2,base+2,base+2,base+2,base+2]
				_loft(tool, centers, sizes, bones, wrist)
				for finger in 4:
					var path := finger_path(finger, side)
					var radii: Array[Vector2] = []
					var ids: Array[int] = []
					for j in path.size():
						var radius: float = [0.0105,0.011,0.010,0.0085][finger] * [1.0,1.03,.89,.84,.71,.42][j]
						radii.append(Vector2(radius,radius*.86))
						ids.append(base+3+finger*3+mini(j/2,2))
					_loft(tool,path,radii,ids,wrist)
				var thumb := thumb_path(side)
				_loft(tool,thumb,[Vector2(.019,.019),Vector2(.017,.016),Vector2(.014,.013),Vector2(.012,.011),Vector2(.006,.006)],[base+2,base+15,base+15,base+16,base+16],wrist)
		tool.index()
		tool.commit(mesh)
	var instance := MeshInstance3D.new()
	instance.name = "ArmsMesh"
	instance.mesh = mesh
	instance.skin = skeleton.create_skin_from_rest_transforms()
	instance.skeleton = NodePath("..")
	instance.layers = 2
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.custom_aabb = AABB(Vector3(-1,-1,-1),Vector3(2,2,2))
	return instance

static func finger_path(finger: int, side: int) -> Array[Vector3]:
	var x: float = [-.029,-.009,.012,.030][finger] * (-1.0 if side == 0 else 1.0)
	if finger == 0 and side == 0:
		return [Vector3(x,.067,0),Vector3(x,.095,.002),Vector3(x,.116,.015),Vector3(x,.126,.034),Vector3(x,.126,.051),Vector3(x,.117,.058)]
	var length: float = [.071,.082,.077,.060][finger]
	var y: float = .067 - (.008 if finger == 3 else 0.0)
	return [Vector3(x,y,0),Vector3(x,y+length*.31,.002),Vector3(x,y+length*.48,.014),Vector3(x,y+length*.49,.036),Vector3(x,y+length*.35,.055),Vector3(x,y+length*.16,.061)]

static func thumb_path(side: int) -> Array[Vector3]:
	var result: Array[Vector3] = [Vector3(-.027,.016,.008),Vector3(-.046,.028,.012),Vector3(-.052,.048,.017),Vector3(-.047,.069,.019),Vector3(-.035,.083,.018)]
	if side == 0:
		for index in result.size():
			result[index].x *= -1.0
	return result

static func _loft(tool: SurfaceTool, centers: Array[Vector3], sizes: Array[Vector2], bones: Array[int], transform: Transform3D, align_cuff: bool = false) -> void:
	var rings: Array[PackedVector3Array] = []
	var lengths: Array[float] = [0.0]
	for i in centers.size():
		if i > 0: lengths.append(lengths[-1] + centers[i].distance_to(centers[i-1]))
		var tangent := (centers[mini(i+1,centers.size()-1)] - centers[maxi(0,i-1)]).normalized()
		if i == centers.size()-1 and align_cuff:
			tangent = Vector3.UP
		var right := Vector3.RIGHT.slide(tangent).normalized()
		if right.length_squared() < .1:
			right = Vector3.UP.slide(tangent).normalized()
		var depth := right.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for j in SIDES:
			var angle := j * TAU / SIDES
			ring.append(centers[i] + right*cos(angle)*sizes[i].x + depth*sin(angle)*sizes[i].y)
		rings.append(ring)
	for i in rings.size()-1:
		for j in SIDES:
			var next := j+1
			for vertex: Vector2i in [Vector2i(i,j),Vector2i(i,next),Vector2i(i+1,next),Vector2i(i,j),Vector2i(i+1,next),Vector2i(i+1,j)]:
				var layer := vertex.x
				var point := rings[layer][vertex.y % SIDES]
				var normal := (point-centers[layer]).normalized()
				tool.set_normal(transform.basis * normal)
				tool.set_uv(Vector2(float(vertex.y) / SIDES, lengths[layer] * 8.0))
				tool.set_color(Color.WHITE * (0.95 + 0.05*cos(vertex.y * TAU / SIDES)))
				tool.set_bones(PackedInt32Array([bones[layer],bones[maxi(0,layer-1)],0,0]))
				tool.set_weights(PackedFloat32Array([.8,.2,0,0]))
				tool.add_vertex(transform * point)
	for end in [0,rings.size()-1]:
		var outward := (centers[end]-centers[1 if end == 0 else end-1]).normalized()
		var right := (rings[end][0] - centers[end]).normalized()
		var depth := (rings[end][SIDES / 4] - centers[end]).normalized()
		for j in SIDES:
			var points: Array = [centers[end],rings[end][(j+1)%SIDES],rings[end][j]] if end == 0 else [centers[end],rings[end][j],rings[end][(j+1)%SIDES]]
			for point in points:
				tool.set_normal(transform.basis*outward)
				var offset: Vector3 = point - centers[end]
				tool.set_uv(Vector2(offset.dot(right), offset.dot(depth)) * 8.0)
				tool.set_color(Color.WHITE)
				tool.set_bones(PackedInt32Array([bones[end],0,0,0]))
				tool.set_weights(PackedFloat32Array([1,0,0,0]))
				tool.add_vertex(transform*point)
