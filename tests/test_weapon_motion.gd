extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
const Ready = preload("res://tests/weapon_ready.gd")
var failures := 0
var player: Player

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func box(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	root.add_child(body)
	body.position = pos
	return body

func ticks(count: int) -> void:
	for tick in count: await physics_frame

func wrist() -> Vector3:
	return player.rig.skeleton.get_bone_global_pose(3).origin

func wrist_motion(reference: Transform3D) -> float:
	var current := player.rig.skeleton.get_bone_global_pose(3)
	return current.origin.distance_to(reference.origin) + .1 * current.basis.get_rotation_quaternion().angle_to(reference.basis.get_rotation_quaternion())

func reset(weapon: int = 0) -> void:
	for action in ["forward", "sprint", "aim", "crouch", "jump", "fire"]: Input.action_release(action)
	if is_instance_valid(player): player.free()
	player = Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_active(true)
	player.equip(weapon)
	check(Ready.wait_for(player, weapon), "motion fixture reaches final READY")
	await ticks(20)

func look(relative: Vector2, screen: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.screen_relative = screen
	player._unhandled_input(event)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: run with X11 and --rendering-driver dummy to exercise captured mouse input")
		quit(2)
		return
	for action in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "fire", "aim", "weapon1", "weapon2", "reload", "scan", "interact"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var floor_body := box(Vector3(0, -.5, 0), Vector3(200, 1, 200))
	await physics_frame
	await reset()
	var neutral := wrist()
	Input.action_press("forward")
	var camera_min := INF
	var camera_max := -INF
	var moving_extent := 0.0
	for tick in 80:
		await physics_frame
		camera_min = minf(camera_min, player.camera.position.y)
		camera_max = maxf(camera_max, player.camera.position.y)
		moving_extent = maxf(moving_extent, wrist().distance_to(neutral))
	check(player.global_position.z < -3 and player.is_on_floor(), "walking fixture traverses real floor")
	check(moving_extent > .001, "real walking animates local wrist")
	check(camera_max - camera_min < .0001, "walking leaves camera height stable: range=%f" % (camera_max - camera_min))
	Input.action_release("forward")
	var before_stop := wrist()
	await ticks(1)
	check(wrist().distance_to(before_stop) < .005, "releasing movement does not snap wrist bob")
	await ticks(100)
	check(wrist().distance_to(neutral) < .001, "stopped player returns wrist to rest")
	var wall := box(Vector3(0, 1.5, -2), Vector3(10, 3, .3))
	player.teleport(Vector3.ZERO)
	await ticks(5)
	Input.action_press("forward")
	Input.action_press("sprint")
	await ticks(100)
	var blocked_origin := player.global_position
	var blocked_wrist := wrist()
	var blocked_extent := 0.0
	for tick in 60:
		await physics_frame
		blocked_extent = maxf(blocked_extent, wrist().distance_to(blocked_wrist))
	check(player.global_position.distance_to(blocked_origin) < .001, "wall fixture blocks actual displacement despite held movement")
	check(blocked_extent < .0005, "blocked movement stops periodic wrist bob: range=%f" % blocked_extent)
	check(absf(wrist().x - neutral.x) < .001, "blocked sprint returns local wrist to rest pose")
	wall.free()
	var response: Array[float] = []
	for weapon in [0, 1]:
		await reset(weapon)
		var rest_x := wrist().x
		Input.action_press("forward")
		Input.action_press("sprint")
		await ticks(4)
		var early := absf(wrist().x - rest_x)
		await ticks(80)
		var settled := absf(wrist().x - rest_x)
		check(settled > .005, "sprint has measurable weapon pose")
		response.append(early / maxf(settled, .000001))
		var run_x := absf(wrist().x - rest_x)
		var speed := Vector2(player.velocity.x, player.velocity.z).length()
		var before_shot := player.rig.muzzle.position
		check(player.fire(), "sprint inertia does not delay urgent fire")
		check(player.rig.muzzle.position.distance_to(before_shot) > .001 and (player._d9_flash if weapon == 0 else player._arc_pulse).global_position.distance_to(player.rig._weapons[weapon].get_node("Muzzle").global_position) < .0001, "new recoil recomposes muzzle at delta zero in the same shot")
		await ticks(3)
		check(absf(wrist().x - rest_x) < run_x * .95, "urgent fire reduces sprint pose")
		check(Vector2(player.velocity.x, player.velocity.z).length() >= speed - .01, "urgent fire preserves sprint movement speed")
		Input.action_press("aim")
		await ticks(30)
		check(wrist().x < rest_x - .06, "aim overrides sprint pose without waiting for motion to settle")
		var camera_basis := player.camera.global_basis
		player._shot_time = 0
		check(player.fire() and player.camera.global_basis.is_equal_approx(camera_basis), "aimed fire leaves camera ray orientation unchanged")
	check(response[0] > response[1] + .03, "D9 normalized sprint response is faster than ARC: D9=%f ARC=%f" % [response[0], response[1]])
	await reset()
	neutral = wrist()
	var neutral_pose := player.rig.skeleton.get_bone_global_pose(3)
	look(Vector2.ZERO, Vector2(20, -10))
	check(is_equal_approx(player.rotation.y, -.04) and is_equal_approx(player.camera.rotation.x, .02), "look uses screen_relative even when relative is zero")
	await ticks(2)
	var look_peak := wrist_motion(neutral_pose)
	check(look_peak > .0001, "applied gaze creates local wrist inertia")
	var previous := look_peak
	var bounded := true
	for tick in 100:
		await physics_frame
		var distance := wrist_motion(neutral_pose)
		bounded = bounded and distance < .06
		previous = distance
	check(bounded and previous < .0001, "gaze cessation returns to rest without unbounded motion")
	player.camera.rotation.x = 1.45
	look(Vector2(0, -10000), Vector2(0, -10000))
	await ticks(3)
	check(is_equal_approx(player.camera.rotation.x, 1.45) and wrist_motion(neutral_pose) < .0001, "clamped-away pitch contributes no gaze impulse")
	look(Vector2(-10000, 10000), Vector2(-10000, 10000))
	await ticks(2)
	check(wrist_motion(neutral_pose) < .06, "extreme applied gaze remains bounded")
	var poses: Array[Transform3D] = []
	for bone in player.rig.skeleton.get_bone_count(): poses.append(player.rig.skeleton.get_bone_global_pose(bone))
	var muzzle := player.rig.muzzle.transform
	for repeat in 20: player.rig.update_visual(0, player._view_frame)
	var same := player.rig.muzzle.transform.is_equal_approx(muzzle)
	for bone in poses.size(): same = same and player.rig.skeleton.get_bone_global_pose(bone).is_equal_approx(poses[bone])
	check(same, "repeated update_visual zero leaves every bone and muzzle unchanged")
	player.teleport(Vector3.ZERO)
	await ticks(3)
	check(wrist_motion(neutral_pose) < .0001, "teleport purges gaze motion")
	Input.action_press("crouch")
	await ticks(20)
	check(player.camera.position.y < 1.0, "camera still follows crouch height")
	Input.action_release("crouch")
	await ticks(20)
	check(absf(player.camera.position.y - 1.58) < .001, "standing restores camera height")
	var step_body := box(Vector3(0, .125, -1), Vector3(2, .25, 1))
	Input.action_press("forward")
	var highest := 0.0
	var step_motion := 0.0
	for tick in 50:
		await physics_frame
		highest = maxf(highest, player.position.y)
		step_motion = maxf(step_motion, wrist().distance_to(neutral))
	check(highest > .2 and player.position.z < -1.5 and step_motion > .001, "real step climb retains horizontal movement presentation")
	Input.action_release("forward")
	step_body.free()
	await ticks(60)
	Input.action_press("jump")
	await ticks(3)
	Input.action_release("jump")
	check(not player.is_on_floor() and player.position.y > .1, "jump fixture leaves the floor")
	await ticks(12)
	var air_wrist := wrist()
	await ticks(5)
	check(wrist().distance_to(air_wrist) < .001, "airborne player without horizontal motion has no walking oscillation")
	await ticks(60)
	check(absf(player.camera.position.y - 1.58) < .001, "landing adds no camera bob impulse")
	player.free()
	floor_body.free()
	await create_timer(.3).timeout
	print("WEAPON MOTION FAILURES: ", failures)
	quit(1 if failures else 0)
