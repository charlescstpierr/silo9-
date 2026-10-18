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

func run() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = Vector3(100,1,100)
	shape.shape = geometry
	floor_body.position.y = -.5
	floor_body.add_child(shape)
	root.add_child(floor_body)
	await physics_frame
	for action in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "fire", "aim"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var player := Player.new()
	var state := State.new()
	player.setup(state)
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	player.set_active(true)
	state.ammo = 5
	state.reserve = 9
	check(player.reload_weapon(), "partial reload starts")
	check(not player.reload_weapon(), "repeated R does not restart")
	player._physics_process(.45)
	check(state.ammo == 5 and state.reserve == 9, "no transfer during manipulation")
	check(not player.fire(), "fire blocked during manipulation")
	player.equip(1)
	check(player.weapon_index == 0 and player.rig.weapon_index == 0, "cancel keeps visible D9 until lowered")
	check(not player.fire(), "cancel cannot fire while weapon is being lowered")
	player.equip(0)
	player.equip(1)
	player._physics_process(.17)
	check(player.weapon_index == 1 and player.rig.weapon_index == 1, "last destination equipped only after hidden")
	check(not player.fire(), "fire blocked during raise")
	player.equip(0)
	player._physics_process(.16)
	check(not player.fire(), "destination change during raise starts another safe lowering")
	player._physics_process(.5)
	player._physics_process(.2)
	check(player.weapon_index == 0 and player.rig.weapon_index == 0, "queued destination eventually equipped")
	check(state.ammo == 5 and state.reserve == 9, "cancel conserves both resources")
	check(player.reload_weapon(), "reload can restart after cancellation")
	player._physics_process(Player.D9.reload_duration + .01)
	check(state.ammo == 12 and state.reserve == 2, "large delta commits exactly one transfer")
	player._physics_process(2.0)
	check(state.ammo == 12 and state.reserve == 2, "later ticks do not repeat transfer")
	var gun: Node3D = player.rig._weapons[0]
	check(gun.get_node_or_null("Magazine") is Node3D, "D9 has an actual moving magazine")
	check(gun.get_node_or_null("Slide") is Node3D, "D9 has an actual moving slide")
	player.queue_free()
	await process_frame
	floor_body.queue_free()
	await create_timer(.4).timeout
	print("D9 RELOAD FAILURES: ", failures)
	quit(1 if failures else 0)
