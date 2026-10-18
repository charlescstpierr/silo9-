extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func space(down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame

func run() -> void:
	for action: String in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "interact", "fire", "reload", "scan", "weapon1", "weapon2", "aim"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var binding := InputEventKey.new()
	binding.physical_keycode = KEY_SPACE
	InputMap.action_add_event("jump", binding)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10, 1, 10)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -.5
	root.add_child(floor_body)
	var player := Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_active(true)
	await ticks(5)
	check(player.is_on_floor(), "real capsule is grounded on the collision floor before tap")
	var before_y: float = player.position.y
	space(true)
	space(false)
	await physics_frame
	check(not Input.is_action_pressed("jump") and Input.is_action_just_pressed("jump"), "complete Space tap retains a fresh press despite released key")
	await physics_frame
	print("TAP velocity_y=", player.velocity.y, " rise=", player.position.y - before_y)
	check(player.velocity.y > 0.0, "complete Space tap produces upward jump velocity")
	check(player.position.y > before_y and not player.is_on_floor(), "complete Space tap lifts the physical capsule")
	await ticks(65)
	check(player.is_on_floor(), "player is grounded again before held-jump control")
	space(true)
	await physics_frame
	check(Input.is_action_pressed("jump") and Input.is_action_just_pressed("jump"), "held Space control starts with a fresh press")
	await ticks(2)
	check(player.velocity.y > 0.0 and not player.is_on_floor(), "held Space also jumps")
	space(false)
	await ticks(3)
	var ascent_velocity: float = player.velocity.y
	check(not player.is_on_floor() and ascent_velocity > 0.0, "double-jump check starts during ascent")
	space(true)
	space(false)
	await ticks(2)
	check(player.velocity.y < ascent_velocity, "a fresh airborne tap cannot reset jump velocity")
	await ticks(65)
	check(player.is_on_floor(), "gravity returns the player to the real floor")
	player.queue_free()
	floor_body.queue_free()
	await process_frame
	print("JUMP TAP FAILURES: ", failures)
	quit(1 if failures else 0)
