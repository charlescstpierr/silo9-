extends SceneTree
const Rig = preload("res://scripts/fps_rig.gd")
const Reload = preload("res://scripts/d9_reload.gd")
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
	var frame := Rig.ViewFrame.new()
	var cycle := Reload.new()
	frame.reload = cycle.view
	var magazine: Node3D = rig._weapons[0].get_node("Magazine")
	var slide: Node3D = rig._weapons[0].get_node("Slide")
	var seated := magazine.position
	check(not magazine.find_children("*","MeshInstance3D",true,false).is_empty(),"magazine owns visible meshes")
	check(not slide.find_children("*","MeshInstance3D",true,false).is_empty(),"slide owns visible meshes")
	cycle.begin(true,2.6,3.25)
	var previous_mag := Vector3.ZERO
	var previous_hand := Vector3.ZERO
	var max_step := 0.0
	var max_contact_error := 0.0
	var min_palm := INF
	var max_palm := 0.0
	for sample in 651:
		if sample > 0: cycle.advance(.005,true)
		rig.update_visual(.005,frame)
		var hand := rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(20)
		if sample > 0:
			max_step = maxf(max_step,previous_hand.distance_to(hand.origin))
			max_step = maxf(max_step,previous_mag.distance_to(magazine.global_position))
		previous_mag = magazine.global_position
		previous_hand = hand.origin
		for side in 2:
			var shoulder := rig.skeleton.get_bone_global_pose(1+side*17).origin
			var elbow := rig.skeleton.get_bone_global_pose(2+side*17).origin
			var wrist := rig.skeleton.get_bone_global_pose(3+side*17).origin
			check(absf(shoulder.distance_to(elbow)-.32)<.0001 and absf(elbow.distance_to(wrist)-.30)<.0001,"limbs retain lengths during gesture")
		if rig.left_in_contact:
			max_contact_error = maxf(max_contact_error,hand.origin.distance_to(rig.active_left_grip.global_position))
		if cycle.view.gesture in [Reload.Gesture.EXTRACT,Reload.Gesture.INSERT,Reload.Gesture.RACK_PULL] and sample % 10 == 0:
			var distance := palm_distance(hand,magazine if cycle.view.gesture != Reload.Gesture.RACK_PULL else slide)
			min_palm = minf(min_palm,distance)
			max_palm = maxf(max_palm,distance)
		check(rig.muzzle.global_position.distance_to((rig._weapons[0].get_node("Muzzle") as Marker3D).global_position)<.0001,"muzzle follows every gesture tick")
	check(rig.calibration_valid,"all reload targets reachable")
	check(max_step < .015,"piece and wrist continuous under 15mm per 5ms: %f"%max_step)
	check(max_contact_error < .002,"active hand grip contact: %f"%max_contact_error)
	check(min_palm > .012 and max_palm < .032,"palm meets actual mesh within glove thickness: %f to %f"%[min_palm,max_palm])
	check(magazine.position.is_equal_approx(seated) and slide.position.is_zero_approx(),"ready restores seated parts")
	for time in [.4,1.0,1.7,2.25,2.55,2.75,3.0]:
		cycle.begin(true,2.6,3.25)
		cycle.advance(time,true)
		rig.update_visual(.01,frame)
		var held_mag := magazine.transform
		var held_hand := rig.skeleton.get_bone_global_pose(20)
		cycle.cancel()
		cycle.advance(.08,true)
		rig.update_visual(.08,frame)
		check(magazine.transform.is_equal_approx(held_mag),"cancel freezes actual piece")
		check(rig.skeleton.get_bone_global_pose(20).is_equal_approx(held_hand),"cancel freezes actual wrist")
		cycle.advance(.08,false)
		rig.update_visual(0,frame)
		for fov in [60.0,76.0,90.0]:
			for aspect in [4.0/3.0,16.0/9.0,21.0/9.0]:
				for part: Node3D in [magazine,slide]:
					for node in part.find_children("*","MeshInstance3D",true,false):
						var mesh := node as MeshInstance3D
						for corner in 8:
							var point := mesh.global_transform*mesh.mesh.get_aabb().get_endpoint(corner)
							var in_frame: bool = point.z < -.05 and absf(point.y)<-point.z*tan(deg_to_rad(fov)*.5) and absf(point.x)<-point.z*tan(deg_to_rad(fov)*.5)*aspect
							check(not in_frame,"hidden reset lies outside supported view")
		rig.restore_reload_parts()
		cycle.advance(.2,true)
		rig.update_visual(.2,frame)
	print("D9 GEOMETRY max_step_m=",max_step," contact_m=",max_contact_error," palm_m=",min_palm,"..",max_palm," failures=",failures)
	rig.queue_free()
	await process_frame
	quit(1 if failures else 0)

func palm_distance(hand: Transform3D,part: Node3D) -> float:
	var origin := hand*Vector3(0,.04,0)
	var direction := hand.basis*Vector3(0,0,1)
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
