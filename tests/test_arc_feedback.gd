extends SceneTree
const Ready = preload("res://tests/weapon_ready.gd")
const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
var notices: Array[String] = []
func check(value: bool,label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var player := Player.new()
	var state := State.new()
	state.energy = 10
	player.setup(state)
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)
	player.feedback.connect(func(message: String) -> void: notices.append(message))
	check(player.request_cell(),"late refusal request accepted before stock changes")
	state.cells = 0
	for tick in 100: player._advance_reload(.01)
	check(notices.back().contains("réserve"),"late stock refusal announces reason")
	check(player.weapon_index == 0 and state.energy == 10,"late refusal returns to D9 without success")
	player.equip(1)
	check(Ready.wait_for(player, 1), "ARC fixture reaches final READY")
	state.energy = 100
	notices.clear()
	check(not player.reload_weapon(),"R refuses full battery")
	check(notices.size() == 1 and notices[0].contains("pleine"),"R full refusal is visible to player")
	player.free()
	await process_frame
	await create_timer(.2).timeout
	print("ARC FEEDBACK FAILURES: ",failures)
	quit(1 if failures else 0)
