extends SceneTree
const Visual = preload("res://scripts/weapon_visual.gd")
const Rig = preload("res://scripts/fps_rig.gd")
const HandMesh = preload("res://scripts/fps_hand_mesh.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		print("FAIL: ",label)
		failures += 1
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for electric in [false,true]:
		var gun := Visual.build(electric)
		for marker in ["GripRight","GripLeft","Muzzle"]:
			check(gun.get_node_or_null(marker) is Marker3D,"named attachment "+marker)
		gun.free()
	var rig := Rig.new()
	root.add_child(rig)
	await process_frame
	check(rig.skeleton.get_bone_count() == 35,"35 declared deform bones")
	rig.position = Vector3(1,2,3)
	rig.rotation = Vector3(.2,-.3,.1)
	var frame := Rig.ViewFrame.new()
	var max_position := 0.0
	var max_angle := 0.0
	for weapon in 2:
		rig.equip(weapon)
		for pose in 3:
			frame.pose = pose
			for phase in 31:
				frame.reload_progress = float(phase)/30
				frame.recoil = .045 if phase % 2 == 0 else 0.0
				frame.bob = sin(phase)*.008
				rig.update_visual(.05,frame)
				var gun: Node3D = rig._weapons[weapon]
				for side in 2:
					if side == 1 and not rig.left_in_contact:
						continue
					var hand: Transform3D = rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(3+side*17)
					var grip := gun.get_node("GripRight" if side == 0 else "GripLeft") as Marker3D
					max_position = maxf(max_position,hand.origin.distance_to(grip.global_position))
					max_angle = maxf(max_angle,hand.basis.get_rotation_quaternion().angle_to(grip.global_basis.orthonormalized().get_rotation_quaternion()))
					var shoulder: Vector3 = rig.skeleton.get_bone_global_pose(1+side*17).origin
					var elbow: Vector3 = rig.skeleton.get_bone_global_pose(2+side*17).origin
					var wrist: Vector3 = rig.skeleton.get_bone_global_pose(3+side*17).origin
					check(absf(shoulder.distance_to(elbow)-Rig.UPPER_LENGTH)<.0001,"upper length fixed")
					check(absf(elbow.distance_to(wrist)-Rig.FOREARM_LENGTH)<.0001,"forearm length fixed")
				check(rig.muzzle.global_position.distance_to((gun.get_node("Muzzle") as Marker3D).global_position)<.0001,"muzzle current in same tick")
				check(gun.visible and not rig._weapons[1-weapon].visible,"logical weapon selected immediately")
	check(max_position <= .002,"contact <=2mm measured %f"%max_position)
	check(max_angle <= deg_to_rad(2),"orientation <=2deg measured %f"%rad_to_deg(max_angle))
	check(rig.calibration_valid,"all sampled IK targets reachable")
	var frame_reload := Rig.ViewFrame.new()
	var max_handling := 0.0
	var max_support_error := 0.0
	rig.equip(0)
	rig.reset_pose()
	for needs_rack in [false,true]:
		frame_reload.reload_requires_rack = needs_rack
		for pose in 3:
			frame_reload.pose = pose
			for phase in 101:
				frame_reload.reload_progress = phase/100.0
				frame_reload.recoil = .035 if phase%2 == 0 else 0.0
				rig.update_visual(.02,frame_reload)
				check(rig.calibration_valid,"full reload targets stay reachable")
				if rig.handling_contact:
					var hand := rig.skeleton.get_bone_global_pose(20)
					max_handling = maxf(max_handling,hand.origin.distance_to(rig.handling_target.origin))
					var support := palm_support_distance(rig,0)
					max_support_error = maxf(max_support_error,absf(support-.019))
				if not needs_rack:
					check(absf(rig._weapons[0].get_node("Slide").position.z + .048 - frame_reload.recoil/.035*.035)<.001,"tactical reload does not rack")
	check(max_handling < .002,"handling wrist contact <=2mm")
	check(max_support_error < .012,"palm contacts physical magazine or slide surface: error %f" % max_support_error)
	print("RELOAD handling_error=",max_handling," palm_surface_error=",max_support_error)
	for index in 10:
		rig.equip(index%2)
		rig.update_visual(.01,frame)
		rig.reset_pose()
		check(rig.left_in_contact,"reset cancels free hand transition")
		check(rig._settle == 0.0 and rig._pose_offset == Vector3.ZERO,"reset removes obsolete transition")
	check(rig.calibration_valid,"rapid equipment keeps IK targets reachable")
	rig.equip(1)
	rig.reset_pose()
	var support_distance := palm_support_distance(rig)
	check(absf(support_distance-.022) < .008,"ARC palm meets actual support geometry measured %f"%support_distance)
	for weapon in 2:
		rig.equip(weapon)
		for progress in [-1.0,.28,.60,.85,.90]:
			frame_reload.reload_progress = progress
			frame_reload.reload_requires_rack = true
			frame_reload.pose = Rig.ViewFrame.Pose.REST
			frame_reload.recoil = 0.0
			rig.update_visual(.3,frame_reload)
			for side in 2:
				for finger in 4:
					var path := HandMesh.finger_path(finger,side)
					for sample in range(2,6):
						var base := 1+side*17+3+finger*3
						var bone := base+mini(sample/2,2)
						var previous := base+mini((sample-1)/2,2)
						var rest_point: Vector3 = rig._rest_wrists[side]*path[sample]
						var point: Vector3 = rig.skeleton.get_bone_global_pose(bone)*rig.skeleton.get_bone_global_rest(bone).affine_inverse()*rest_point*.8
						point += rig.skeleton.get_bone_global_pose(previous)*rig.skeleton.get_bone_global_rest(previous).affine_inverse()*rest_point*.2
						check(not inside_weapon(rig._weapons[weapon],rig.global_transform*point),"finger center outside weapon %d phase %.2f side %d finger %d sample %d" % [weapon,progress,side,finger,sample])
	var wrist_before := rig.skeleton.get_bone_global_pose(20)
	check(not rig._pose_arm(1,Transform3D(Basis.IDENTITY,Vector3(10,10,10))),"unreachable calibration rejected")
	check(rig.skeleton.get_bone_global_pose(20).is_equal_approx(wrist_before),"unreachable target cannot stretch arm")
	print("RIG max_contact_m=",max_position," max_angle_deg=",rad_to_deg(max_angle)," failures=",failures)
	rig.queue_free()
	await process_frame
	quit(1 if failures else 0)

func palm_support_distance(rig: SiloFpsRig, weapon: int = 1) -> float:
	var hand := rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(20)
	var origin := hand*Vector3(0,.04,0)
	var direction := hand.basis*Vector3(0,0,1)
	var closest := INF
	for child in rig._weapons[weapon].find_children("*","MeshInstance3D",true,false):
		var mesh_node := child as MeshInstance3D
		if not mesh_node.is_visible_in_tree():
			continue
		for surface in mesh_node.mesh.get_surface_count():
			var arrays := mesh_node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i in range(0,indices.size(),3):
				var a := mesh_node.global_transform*vertices[indices[i]]
				var b := mesh_node.global_transform*vertices[indices[i+1]]
				var c := mesh_node.global_transform*vertices[indices[i+2]]
				var hit: Variant = Geometry3D.ray_intersects_triangle(origin,direction,a,b,c)
				if hit is Vector3:
					closest = minf(closest,origin.distance_to(hit))
	return closest

func inside_weapon(gun: Node3D, point: Vector3) -> bool:
	var direction := Vector3(.73,.39,.56).normalized()
	var hits := 0
	for child: MeshInstance3D in gun.find_children("*","MeshInstance3D",true,false):
		if not child.is_visible_in_tree():
			continue
		for surface in child.mesh.get_surface_count():
			var arrays := child.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for index in range(0,indices.size(),3):
				var a: Vector3 = child.global_transform*vertices[indices[index]]
				var b: Vector3 = child.global_transform*vertices[indices[index+1]]
				var c: Vector3 = child.global_transform*vertices[indices[index+2]]
				var hit: Variant = Geometry3D.ray_intersects_triangle(point,direction,a,b,c)
				if hit is Vector3:
					hits += 1
	return hits%2 == 1
