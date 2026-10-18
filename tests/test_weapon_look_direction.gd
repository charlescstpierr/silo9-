extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
var player: Player

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1

func ticks(count: int) -> void:
	for tick in count: await physics_frame

func look(pixels: float) -> void:
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(0,pixels)
	player._unhandled_input(event)

func wrist_y() -> float:
	return player.rig.skeleton.get_bone_global_pose(3).origin.y

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: applied gaze requires captured X11 mouse")
		quit(2)
		return
	for action in ["forward","back","left","right","sprint","jump","crouch","fire","aim","weapon1","weapon2","reload","scan","interact"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200,1,200)
	shape.shape = box
	floor_body.add_child(shape)
	root.add_child(floor_body)
	floor_body.position.y = -.5
	player = Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_active(true)
	for weapon in [0,1]:
		player.equip(weapon)
		for tick in 100:
			await physics_frame
			if player.reload_cycle.ready and player.weapon_index == weapon: break
		assert(player.reload_cycle.ready and player.weapon_index == weapon)
		for pixels in [-20.0,20.0]:
			Input.action_release("aim")
			player.teleport(Vector3.ZERO)
			await ticks(3)
			var rest := wrist_y()
			look(pixels)
			var pitch := player.camera.rotation.x
			await ticks(2)
			var rest_offset := wrist_y()-rest
			check(absf(pitch) > .01 and rest_offset*pitch < 0, "vertical lag opposes applied pitch: weapon=%d pixels=%f offset=%f"%[weapon,pixels,rest_offset])
			player.teleport(Vector3.ZERO)
			Input.action_press("aim")
			await ticks(60)
			var aimed := wrist_y()
			look(pixels)
			pitch = player.camera.rotation.x
			await ticks(2)
			var aimed_offset := wrist_y()-aimed
			check(aimed_offset*pitch < 0, "aimed vertical lag opposes applied camera pitch")
			check(absf(aimed_offset) < absf(rest_offset)*.4, "aim attenuates vertical lag")
			Input.action_release("aim")
			player.teleport(Vector3.ZERO)
			await ticks(3)
			player.camera.rotation.x = 1.45 if pixels < 0 else -1.45
			var clamped := wrist_y()
			look(pixels*100)
			await ticks(2)
			check(absf(wrist_y()-clamped) < .00001, "clamped-away pitch contributes no lag")
	player.free()
	floor_body.free()
	await create_timer(.2).timeout
	quit(1 if failures else 0)
