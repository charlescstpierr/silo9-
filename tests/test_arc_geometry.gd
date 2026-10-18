extends SceneTree
const Rig = preload("res://scripts/fps_rig.gd")
const Handling = preload("res://scripts/weapon_handling.gd")
const HandMesh = preload("res://scripts/fps_hand_mesh.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
func check(value: bool,label: String) -> void:
	if not value:
		print("FAIL: ",label)
		failures += 1
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var rig := Rig.new()
	root.add_child(rig)
	await process_frame
	rig.equip(1)
	var frame := Rig.ViewFrame.new()
	var cycle := Handling.new()
	cycle.state = State.new()
	cycle.state.energy = 10
	cycle.state.cells = 10
	cycle.select(1)
	for tick in 100:
		if cycle.ready and cycle.weapon_index == 1: break
		cycle.advance(.01, true)
	check(cycle.ready and cycle.weapon_index == 1, "ARC selection prepared before all 602 gesture samples")
	frame.reload = cycle.view
	var cell: Node3D = rig._weapons[1].get_node("ArcCell")
	var latch: Node3D = rig._weapons[1].get_node("ArcLatch")
	var seated := cell.position
	cycle.request_cell(true)
	var previous_cell := Vector3.ZERO
	var previous_latch := Vector3.ZERO
	var previous_hand := Vector3.ZERO
	var max_step := 0.0
	var max_contact_error := 0.0
	var min_palm := INF
	var max_palm := 0.0
	var min_finger := INF
	var max_finger := 0.0
	var visible_pocket := false
	for sample in 602:
		if sample > 0: cycle.advance(.005,true)
		rig.update_visual(.005,frame)
		var hand := rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(20)
		if sample > 0:
			max_step = maxf(max_step,previous_hand.distance_to(hand.origin))
			max_step = maxf(max_step,previous_cell.distance_to(cell.global_position))
			max_step = maxf(max_step,previous_latch.distance_to(latch.global_position))
		previous_cell = cell.global_position
		previous_latch = latch.global_position
		previous_hand = hand.origin
		for side in 2:
			var shoulder := rig.skeleton.get_bone_global_pose(1+side*17).origin
			var elbow := rig.skeleton.get_bone_global_pose(2+side*17).origin
			var wrist := rig.skeleton.get_bone_global_pose(3+side*17).origin
			check(absf(shoulder.distance_to(elbow)-.32)<.0001 and absf(elbow.distance_to(wrist)-.30)<.0001,"limbs retain lengths during ARC gesture")
		if rig.left_in_contact:
			max_contact_error = maxf(max_contact_error,hand.origin.distance_to(rig.active_left_grip.global_position))
		if cycle.view.gesture in [Handling.Gesture.CELL_EXTRACT,Handling.Gesture.CELL_INSERT,Handling.Gesture.UNLOCK,Handling.Gesture.LOCK] and sample % 10 == 0:
			var part := latch if cycle.view.gesture in [Handling.Gesture.UNLOCK,Handling.Gesture.LOCK] else cell
			var distance := ray_distance(hand*Vector3(0,.04,0),hand.basis.z,part)
			min_palm = minf(min_palm,distance)
			max_palm = maxf(max_palm,distance)
			for finger in 4:
				var tip := hand*HandMesh.finger_path(finger,1)[5]
				var finger_distance := mesh_distance(tip,part)
				min_finger = minf(min_finger,finger_distance)
				max_finger = maxf(max_finger,finger_distance)
		check(rig.muzzle.global_position.distance_to((rig._weapons[1].get_node("Muzzle") as Marker3D).global_position)<.0001,"muzzle follows every ARC tick")
		if absf(cycle._time-Handling.ARC.reload_duration*.47)<.003:
			visible_pocket = not below_frustum(cell,90)
	check(rig.calibration_valid,"all ARC targets reachable")
	check(max_step < .015,"cell/latch/wrist continuous under 15mm per 5ms: %f"%max_step)
	check(max_contact_error < .002,"active ARC hand grip contact: %f"%max_contact_error)
	check(min_palm > .012 and max_palm < .032,"palm meets actual ARC mesh within glove thickness: %f to %f"%[min_palm,max_palm])
	check(max_finger < .022,"actual finger pads wrap ARC mesh within 22mm: %f to %f"%[min_finger,max_finger])
	check(not visible_pocket,"cell identity can change only below bottom frustum")
	check(cell.position.is_equal_approx(seated) and latch.rotation.is_zero_approx(),"ready restores ARC seated parts")
	for time in [.15,.4,.65,.9,1.2,1.5,1.9,2.25,2.5,2.8]:
		cycle.state.energy = 10
		cycle.state.cells = 1
		check(cycle.request_cell(true),"cancellation fixture starts actual operation")
		cycle.advance(time,true)
		rig.update_visual(.01,frame)
		var held_cell := cell.transform
		var held_latch := latch.transform
		var held_hand := rig.skeleton.get_bone_global_pose(20)
		cycle.cancel()
		cycle.advance(.08,true)
		rig.update_visual(.08,frame)
		check(cell.transform.is_equal_approx(held_cell) and latch.transform.is_equal_approx(held_latch),"cancel freezes actual ARC pieces")
		check(rig.skeleton.get_bone_global_pose(20).is_equal_approx(held_hand),"cancel freezes actual ARC wrist")
		cycle.advance(.08,false)
		rig.update_visual(0,frame)
		for fov in [60.0,76.0,90.0]:
			for part: Node3D in [cell,latch,rig._weapons[1].get_node("ArcSocket")]:
				check(below_frustum(part,fov),"all ARC AABB corners below lower frustum before restore, FOV %s time %s"%[fov,time])
		rig.restore_reload_parts()
		cycle.advance(.2,true)
		rig.update_visual(.2,frame)
	print("ARC GEOMETRY max_step_m=",max_step," contact_m=",max_contact_error," palm_m=",min_palm,"..",max_palm," finger_m=",min_finger,"..",max_finger," failures=",failures)
	rig.queue_free()
	await process_frame
	quit(1 if failures else 0)

func below_frustum(part: Node3D, fov: float) -> bool:
	for node in part.find_children("*","MeshInstance3D",true,false):
		for corner in 8:
			var point: Vector3 = node.global_transform*node.mesh.get_aabb().get_endpoint(corner)
			if point.z >= -.05 or point.y >= point.z*tan(deg_to_rad(fov)*.5): return false
	return true

func ray_distance(origin: Vector3, direction: Vector3, part: Node3D) -> float:
	var closest := INF
	for node in part.find_children("*","MeshInstance3D",true,false):
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i in range(0,indices.size(),3):
				var hit: Variant = Geometry3D.ray_intersects_triangle(origin,direction,mesh.global_transform*vertices[indices[i]],mesh.global_transform*vertices[indices[i+1]],mesh.global_transform*vertices[indices[i+2]])
				if hit is Vector3: closest = minf(closest,origin.distance_to(hit))
	return closest

func mesh_distance(point: Vector3, part: Node3D) -> float:
	var closest := INF
	for node in part.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for index in range(0,indices.size(),3):
				var a: Vector3 = node.global_transform*vertices[indices[index]]
				var b: Vector3 = node.global_transform*vertices[indices[index+1]]
				var c: Vector3 = node.global_transform*vertices[indices[index+2]]
				var normal := (b-a).cross(c-a).normalized()
				var projected := point-normal*(point-a).dot(normal)
				var inside := true
				for edge: Array in [[a,b],[b,c],[c,a]]:
					inside = inside and (edge[1]-edge[0]).cross(projected-edge[0]).dot(normal) >= -.0000001
					closest = minf(closest,point.distance_to(Geometry3D.get_closest_point_to_segment(point,edge[0],edge[1])))
				if inside: closest = minf(closest,point.distance_to(projected))
	return closest
