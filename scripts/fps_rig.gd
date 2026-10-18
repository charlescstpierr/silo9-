class_name SiloFpsRig
extends Node3D

const Visual = preload("res://scripts/weapon_visual.gd")
const Reload = preload("res://scripts/d9_reload.gd")
const HandMesh = preload("res://scripts/fps_hand_mesh.gd")
const UPPER_LENGTH := 0.32
const FOREARM_LENGTH := 0.30
const SHOULDERS: Array[Vector3] = [Vector3(.23,-.40,.04),Vector3(-.16,-.40,-.04)]

class ViewFrame extends RefCounted:
	enum Pose { REST, RUN, AIM }
	var pose: Pose = Pose.REST
	var reload := Reload.View.new()
	var recoil: float = 0.0
	var bob: float = 0.0

var muzzle: Marker3D
var skeleton: Skeleton3D
var arms: MeshInstance3D
var weapon_index := 0
var left_in_contact := true
var calibration_valid := true
var _mount: Node3D
var _attachment: BoneAttachment3D
var _weapons: Array[Node3D] = []
var _rest_wrists: Array[Transform3D] = []
var _rest_elbows: Array[Vector3] = []
var _pose_offset := Vector3.ZERO
var _settle := 0.0
var _left_from := Transform3D.IDENTITY
var _frame := ViewFrame.new()
var _magazine: Node3D
var _slide: Node3D
var _seat := Vector3.ZERO
var active_left_grip: Marker3D
var _last_lower := 0.0

func _ready() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	_add_bone("Root", -1, Transform3D.IDENTITY)
	for index in 2:
		var gun := Visual.build(index == 1)
		_weapons.append(gun)
	_magazine = _weapons[0].get_node("Magazine")
	_slide = _weapons[0].get_node("Slide")
	_seat = _magazine.position
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
	_settle = 0.0
	_pose_offset = Vector3.ZERO
	_frame = ViewFrame.new()
	restore_reload_parts()
	update_visual(0.0,_frame)

func restore_reload_parts() -> void:
	_magazine.position = _seat
	_slide.position = Vector3.ZERO
	_settle = 0.0

func update_visual(delta: float, frame: ViewFrame) -> void:
	_frame = frame
	var lower := frame.reload.lower
	skeleton.position.y = -lower*1.15
	if frame.reload.motion == Reload.Motion.LOWER_ABORT:
		muzzle.position.y -= (lower-_last_lower)*1.15
		_last_lower = lower
		return
	_last_lower = lower
	_settle = maxf(0.0,_settle-delta)
	var target := Vector3.ZERO
	if frame.pose == ViewFrame.Pose.RUN:
		target = Vector3(.025,-.035,.025)
	elif frame.pose == ViewFrame.Pose.AIM:
		target = Vector3(-.14,.045,-.035)
	_pose_offset = _pose_offset.lerp(target,1.0-exp(-delta*14.0))
	var gesture := frame.reload.gesture
	var t := smoothstep(0,1,frame.reload.fraction)
	var manipulating := frame.reload.motion == Reload.Motion.RELOAD
	var amount := 0.0
	if manipulating:
		amount = t if gesture == Reload.Gesture.REACH else (1.0-t if gesture == Reload.Gesture.RETURN else 1.0)
	var wrist := _rest_wrists[0]
	wrist.origin += _pose_offset*(1.0-amount) + Vector3(0,frame.bob,frame.recoil)*(1.0-amount)
	wrist.origin += Vector3(-.07,.10,.05)*amount
	wrist.basis = Basis(Vector3.FORWARD,deg_to_rad(22)*amount)*wrist.basis
	if not _pose_arm(0,wrist):
		return
	skeleton.force_update_all_bone_transforms()
	_attachment.transform = wrist
	var gun := _weapons[weapon_index]
	var gun_pose := wrist*_mount.transform*gun.transform
	var support := gun.get_node("GripLeft") as Marker3D
	var left := gun_pose*support.transform
	active_left_grip = support
	left_in_contact = _settle <= 0.0
	if manipulating:
		left = _reload_pose(gun_pose,frame.reload,t,left)
	elif not left_in_contact:
		var blend := 1.0-_settle/.22
		left = _left_from.interpolate_with(left,smoothstep(0,1,blend))
		left.origin += Vector3(-.025, -.025, .015)*sin(blend*PI)
	left.basis = left.basis.orthonormalized()
	if not _pose_arm(1,left):
		return
	_pose_fingers(amount,gesture,t)
	if not manipulating:
		skeleton.set_bone_pose_rotation(5,Quaternion(Vector3.RIGHT,clampf(frame.recoil/.045,0,1)*.13))
	skeleton.force_update_all_bone_transforms()
	var mouth := gun_pose*(gun.get_node("Muzzle") as Marker3D).transform
	mouth.basis = mouth.basis.orthonormalized()
	mouth.origin += skeleton.position
	muzzle.transform = mouth

func _reload_pose(gun_pose: Transform3D, view: Reload.View, t: float, support: Transform3D) -> Transform3D:
	var extracted := _seat+Vector3(0,-.17,.038)
	var pocket := Vector3(-.20,-.64,.22)
	_magazine.position = _seat
	_slide.position = Vector3.ZERO
	match view.gesture:
		Reload.Gesture.EXTRACT:
			_magazine.position = _seat.lerp(extracted,t)
		Reload.Gesture.STOW:
			_magazine.position = extracted.lerp(pocket,t)
		Reload.Gesture.FETCH:
			_magazine.position = pocket.lerp(extracted,t)
		Reload.Gesture.INSERT:
			_magazine.position = extracted.lerp(_seat,t)
		Reload.Gesture.RACK_PULL:
			_slide.position.z = .045*t
		Reload.Gesture.RACK_RELEASE:
			_slide.position.z = .045*(1.0-t)
	var magazine_grip := _magazine.get_node("Grip") as Marker3D
	var slide_grip := _slide.get_node("Grip") as Marker3D
	var mag_hand := gun_pose*_magazine.transform*magazine_grip.transform
	var slide_hand := gun_pose*_slide.transform*slide_grip.transform
	left_in_contact = true
	active_left_grip = magazine_grip
	match view.gesture:
		Reload.Gesture.REACH:
			left_in_contact = t >= 1.0
			return support.interpolate_with(mag_hand,t)
		Reload.Gesture.RACK_REACH:
			left_in_contact = false
			return mag_hand.interpolate_with(slide_hand,t)
		Reload.Gesture.RACK_PULL, Reload.Gesture.RACK_RELEASE:
			active_left_grip = slide_grip
			return slide_hand
		Reload.Gesture.RETURN:
			left_in_contact = t >= 1.0
			active_left_grip = _weapons[0].get_node("GripLeft")
			return (slide_hand if view.empty else mag_hand).interpolate_with(support,t)
	return mag_hand

func _pose_fingers(amount: float, gesture: Reload.Gesture, t: float) -> void:
	for side in 2:
		for bone in range(4+side*17,18+side*17):
			skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_rest(bone).basis.get_rotation_quaternion())
	for bone in [4,5,6]:
		skeleton.set_bone_pose_rotation(bone,Quaternion(Vector3.RIGHT,-.22*amount))
	var open := 0.0
	if gesture == Reload.Gesture.REACH or gesture == Reload.Gesture.RACK_REACH or gesture == Reload.Gesture.RETURN:
		open = sin(t*PI)*amount
	for finger in 4:
		skeleton.set_bone_pose_rotation(21+finger*3,Quaternion(Vector3.RIGHT,-.15*open))
		skeleton.set_bone_pose_rotation(22+finger*3,Quaternion(Vector3.RIGHT,-.25*open))
	skeleton.set_bone_pose_rotation(33,Quaternion(Vector3.UP,.16*open))

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
