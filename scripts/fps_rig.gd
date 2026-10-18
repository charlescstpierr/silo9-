class_name SiloFpsRig
extends Node3D

const Visual = preload("res://scripts/weapon_visual.gd")
const HandMesh = preload("res://scripts/fps_hand_mesh.gd")
const UPPER_LENGTH := 0.32
const FOREARM_LENGTH := 0.30
const MAGAZINE_RELEASE := .16
const MAGAZINE_SEATED := .74
const SLIDE_CLOSED := .92
const SHOULDERS: Array[Vector3] = [Vector3(.23,-.40,.04),Vector3(-.16,-.40,-.04)]

class ViewFrame extends RefCounted:
	enum Pose { REST, RUN, AIM }
	var pose: Pose = Pose.REST
	var reload_progress: float = -1.0
	var reload_requires_rack: bool = false
	var energy_fraction: float = 1.0
	var recoil: float = 0.0
	var bob: float = 0.0

var muzzle: Marker3D
var skeleton: Skeleton3D
var arms: MeshInstance3D
var weapon_index := 0
var left_in_contact := true
var calibration_valid := true
var handling_contact := false
var handling_target := Transform3D.IDENTITY
var recovering: bool:
	get: return _recovery_time > 0.0
var _recovery_time := 0.0
var _last_reload_progress := -1.0
var _frozen_frame: ViewFrame
var _textured_materials: Array[StandardMaterial3D] = []
var _arc_emissive: Array[StandardMaterial3D] = []
var _mount: Node3D
var _attachment: BoneAttachment3D
var _weapons: Array[Node3D] = []
var _rest_wrists: Array[Transform3D] = []
var _rest_elbows: Array[Vector3] = []
var _pose_offset := Vector3.ZERO
var _settle := 0.0
var _left_from := Transform3D.IDENTITY
var _frame := ViewFrame.new()

func _ready() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	_add_bone("Root", -1, Transform3D.IDENTITY)
	for index in 2:
		var gun := Visual.build(index == 1)
		_weapons.append(gun)
	var gun_transform := Transform3D(Basis.IDENTITY,Vector3(.19,-.16,-.34))*_weapons[0].transform
	for side in 2:
		var grip := _weapons[0].get_node("GripRight" if side == 0 else "GripLeft") as Marker3D
		var wrist := gun_transform*grip.transform
		wrist.basis = wrist.basis.orthonormalized()
		_rest_wrists.append(wrist)
		var elbow := solve_elbow(SHOULDERS[side],wrist.origin,side)
		_rest_elbows.append(elbow)
		var base := 1+side*17
		var prefix := "Right" if side == 0 else "Left"
		_add_bone(prefix+"Upper",0,Transform3D(Basis.IDENTITY,SHOULDERS[side]))
		_add_bone(prefix+"Forearm",base,Transform3D(Basis.IDENTITY,elbow))
		_add_bone(prefix+"Hand",base+1,wrist)
		for finger in 4:
			var path := HandMesh.finger_path(finger, side)
			for joint in 3:
				_add_bone(prefix+"Finger%d_%d"%[finger,joint],base+2 if joint == 0 else base+2+finger*3+joint,wrist*Transform3D(Basis.IDENTITY,path[joint*2]))
		var thumb := HandMesh.thumb_path(side)
		_add_bone(prefix+"Thumb0",base+2,wrist*Transform3D(Basis.IDENTITY,thumb[1]))
		_add_bone(prefix+"Thumb1",base+15,wrist*Transform3D(Basis.IDENTITY,thumb[3]))
	arms = HandMesh.build(skeleton,_rest_wrists,_rest_elbows,SHOULDERS)
	skeleton.add_child(arms)
	_attachment = BoneAttachment3D.new()
	_attachment.bone_name = "RightHand"
	skeleton.add_child(_attachment)
	_mount = Node3D.new()
	_mount.name = "WeaponMount"
	_attachment.add_child(_mount)
	for gun in _weapons:
		_mount.add_child(gun)
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	add_child(muzzle)
	equip(0)
	reset_pose()
	for mesh_node: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface in mesh_node.mesh.get_surface_count():
			var material := mesh_node.get_active_material(surface) as StandardMaterial3D
			if material != null and material.normal_texture != null and not _textured_materials.has(material):
				_textured_materials.append(material)
			if material != null and material.normal_texture == null and _weapons[1].is_ancestor_of(mesh_node) and not _arc_emissive.has(material):
				_arc_emissive.append(material)

func _add_bone(label: String, parent: int, global_rest: Transform3D) -> void:
	var index := skeleton.get_bone_count()
	skeleton.add_bone(label)
	skeleton.set_bone_parent(index,parent)
	var local := global_rest if parent < 0 else skeleton.get_bone_global_rest(parent).affine_inverse()*global_rest
	skeleton.set_bone_rest(index,local)
	skeleton.set_bone_pose_position(index,local.origin)
	skeleton.set_bone_pose_rotation(index,local.basis.get_rotation_quaternion())

func equip(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return
	_left_from = skeleton.get_bone_global_pose(20)
	_settle = 0.22
	weapon_index = index
	for slot in _weapons.size():
		_weapons[slot].visible = slot == index
	var gun := _weapons[index]
	var contact := gun.transform*(gun.get_node("GripRight") as Marker3D).transform
	contact.basis = contact.basis.orthonormalized()
	_mount.transform = contact.affine_inverse()
	update_visual(0.0,_frame)

func reset_pose() -> void:
	if _last_reload_progress > 0.0 and _last_reload_progress < 1.0 and not recovering:
		_frozen_frame = ViewFrame.new()
		_frozen_frame.reload_progress = _last_reload_progress
		_frozen_frame.reload_requires_rack = _frame.reload_requires_rack
		_frozen_frame.energy_fraction = _frame.energy_fraction
		_recovery_time = .38
		return
	if recovering:
		return
	_settle = 0.0
	_pose_offset = Vector3.ZERO
	_frame = ViewFrame.new()
	update_visual(0.0,_frame)

func set_quality(low: bool) -> void:
	for material in _textured_materials:
		material.normal_enabled = not low
		material.roughness_texture = null if low else load("res://assets/industrial/weave_roughness.png" if material == arms.mesh.surface_get_material(0) or material == arms.mesh.surface_get_material(1) else "res://assets/industrial/worn_steel_roughness.png")

func update_visual(delta: float, frame: ViewFrame) -> void:
	_frame = frame
	if recovering:
		_recovery_time = maxf(0.0,_recovery_time-delta)
		var elapsed := .38-_recovery_time
		if elapsed < .16:
			position.y = -.75*smoothstep(0.0,.16,elapsed)
			frame = _frozen_frame
		else:
			position.y = -.75*(1.0-smoothstep(.16,.38,elapsed))
			frame = ViewFrame.new()
			_settle = 0.0
			_pose_offset = Vector3.ZERO
	else:
		position.y = 0.0
	_last_reload_progress = frame.reload_progress
	_settle = maxf(0.0,_settle-delta)
	var target := Vector3.ZERO
	if frame.pose == ViewFrame.Pose.RUN:
		target = Vector3(.025,-.035,.025)
	elif frame.pose == ViewFrame.Pose.AIM:
		target = Vector3(-.14,.045,-.035)
	_pose_offset = _pose_offset.lerp(target,1.0-exp(-delta*14.0))
	var progress := frame.reload_progress if weapon_index == 0 else -1.0
	var reload_weight := sin(clampf(progress,0,1)*PI) if progress >= 0 else 0.0
	var wrist := _rest_wrists[0]
	if weapon_index == 1:
		wrist.origin.z += .035
	var kick := clampf(frame.recoil/.035,0.0,1.0)
	wrist.origin += _pose_offset + Vector3(frame.bob*.5-reload_weight*.07,frame.bob+reload_weight*.11,frame.recoil)
	wrist.basis = Basis.from_euler(Vector3(-kick*.10,0,reload_weight*.42-kick*.035))*wrist.basis
	if not _pose_arm(0,wrist):
		return
	skeleton.force_update_all_bone_transforms()
	_attachment.transform = wrist
	var gun := _weapons[weapon_index]
	var gun_pose := wrist*_mount.transform*gun.transform
	var left := gun_pose*(gun.get_node("GripLeft") as Marker3D).transform
	left.basis = left.basis.orthonormalized()
	left_in_contact = _settle <= 0.0
	handling_contact = false
	var opening := 0.0
	if weapon_index == 0:
		var magazine := gun.get_node("Magazine") as Node3D
		var spare := gun.get_node("SpareMagazine") as Node3D
		var slide := gun.get_node("Slide") as Node3D
		var seated := Vector3(0,-.122,.089)
		var pocket := seated + Vector3(-.06,-.64,.13)
		magazine.position = seated
		spare.position = pocket
		magazine.visible = progress < .5 or progress >= 1.0
		spare.visible = progress >= .5 and progress < 1.0
		slide.position.z = -.048 + kick*.035
		if progress >= 0 and progress < 1:
			left_in_contact = false
			var grip := (gun.get_node("MagazineGrip") as Marker3D).transform
			var offset := Vector3.ZERO
			if progress < .48:
				var extracted := seated + Vector3(0,-.22,.025)
				magazine.position = seated.lerp(extracted,_ease(progress,MAGAZINE_RELEASE,.34)).lerp(pocket,_ease(progress,.34,.48))
				offset = magazine.position-seated
			else:
				magazine.position = pocket
				spare.position = pocket.lerp(seated,_ease(progress,.50,MAGAZINE_SEATED))
				offset = spare.position-seated
			grip.origin += offset
			var contact := gun_pose*grip
			contact.basis = contact.basis.orthonormalized()
			if progress < MAGAZINE_RELEASE:
				left = left.interpolate_with(contact,_ease(progress,0,MAGAZINE_RELEASE))
				opening = sin(_ease(progress,0,MAGAZINE_RELEASE)*PI)*.7
			elif progress <= MAGAZINE_SEATED:
				left = contact
				handling_contact = true
			elif frame.reload_requires_rack:
				var rack := (gun.get_node("RackGrip") as Marker3D).transform
				var pull := _ease(progress,.82,.88)*(1.0-_ease(progress,.88,SLIDE_CLOSED))
				slide.position.z = -.048 + pull*.055
				rack.origin.z += pull*.055
				var rack_contact := gun_pose*rack
				rack_contact.basis = rack_contact.basis.orthonormalized()
				if progress < .82:
					left = contact.interpolate_with(rack_contact,_ease(progress,MAGAZINE_SEATED,.82))
					opening = sin(_ease(progress,MAGAZINE_SEATED,.82)*PI)
				elif progress < SLIDE_CLOSED:
					left = rack_contact
					handling_contact = true
				else:
					left = rack_contact.interpolate_with(left,_ease(progress,SLIDE_CLOSED,1.0))
					opening = sin(_ease(progress,SLIDE_CLOSED,1.0)*PI)*.5
			else:
				left = contact.interpolate_with(left,_ease(progress,MAGAZINE_SEATED,1.0))
				opening = sin(_ease(progress,MAGAZINE_SEATED,1.0)*PI)*.5
			handling_target = left
	else:
		for material in _arc_emissive:
			material.emission_energy_multiplier = .08 + frame.energy_fraction*.8 + kick*2.0
	if _settle > 0.0 and progress < 0:
		var t := 1.0-_settle/.22
		left = _left_from.interpolate_with(left,smoothstep(0,1,t))
		left.origin += Vector3(-.025, -.025, .015)*sin(t*PI)
	if not _pose_arm(1,left):
		return
	for side in 2:
		var base := 1+side*17
		for finger in 4:
			for joint in 3:
				var curl := -opening*.36 if side == 1 else (kick*.13 if finger == 0 else 0.0)
				skeleton.set_bone_pose_rotation(base+3+finger*3+joint,Quaternion(Vector3.RIGHT,curl))
		skeleton.set_bone_pose_rotation(base+15,Quaternion(Vector3.UP,opening*.22 if side == 1 else 0.0))
	skeleton.force_update_all_bone_transforms()
	var mouth := gun_pose*(gun.get_node("Muzzle") as Marker3D).transform
	mouth.basis = mouth.basis.orthonormalized()
	muzzle.transform = mouth

static func reload_cues(previous: float, current: float, needs_rack: bool) -> PackedStringArray:
	var cues := PackedStringArray()
	if previous < MAGAZINE_RELEASE and current >= MAGAZINE_RELEASE:
		cues.append("mag_out")
	if previous < MAGAZINE_SEATED and current >= MAGAZINE_SEATED:
		cues.append("mag_in")
	if needs_rack and previous < SLIDE_CLOSED and current >= SLIDE_CLOSED:
		cues.append("rack")
	return cues

static func _ease(progress: float, start: float, end: float) -> float:
	return smoothstep(0.0,1.0,clampf((progress-start)/(end-start),0.0,1.0))

func _pose_arm(side: int, wrist: Transform3D) -> bool:
	var base := 1+side*17
	var shoulder := SHOULDERS[side]
	var distance := shoulder.distance_to(wrist.origin)
	if distance >= UPPER_LENGTH+FOREARM_LENGTH-.001 or distance <= absf(UPPER_LENGTH-FOREARM_LENGTH)+.001:
		calibration_valid = false
		return false
	var elbow := solve_elbow(shoulder,wrist.origin,side)
	var upper_basis := Basis(Quaternion((_rest_elbows[side]-shoulder).normalized(),(elbow-shoulder).normalized()))
	var forearm_basis := Basis(Quaternion((_rest_wrists[side].origin-_rest_elbows[side]).normalized(),(wrist.origin-elbow).normalized()))
	_set_global(base,Transform3D(upper_basis,shoulder))
	_set_global(base+1,Transform3D(forearm_basis,elbow))
	_set_global(base+2,wrist)
	return true

func _set_global(index: int, pose: Transform3D) -> void:
	var parent := skeleton.get_bone_parent(index)
	var local := skeleton.get_bone_global_pose(parent).affine_inverse()*pose
	skeleton.set_bone_pose_position(index,local.origin)
	skeleton.set_bone_pose_rotation(index,local.basis.get_rotation_quaternion())

static func solve_elbow(shoulder: Vector3, wrist: Vector3, side: int) -> Vector3:
	var direction := wrist-shoulder
	var distance := clampf(direction.length(),.021,UPPER_LENGTH+FOREARM_LENGTH-.001)
	direction = direction.normalized() if direction.length_squared() > .000001 else Vector3.FORWARD
	var pole := Vector3(.6 if side == 0 else -.6,-1,.1).slide(direction).normalized()
	if pole.length_squared() < .01:
		pole = Vector3.RIGHT.slide(direction).normalized()
	var along := (UPPER_LENGTH*UPPER_LENGTH-FOREARM_LENGTH*FOREARM_LENGTH+distance*distance)/(2*distance)
	return shoulder+direction*along+pole*sqrt(maxf(0,UPPER_LENGTH*UPPER_LENGTH-along*along))
