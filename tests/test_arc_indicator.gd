extends SceneTree
const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
func check(value: bool,label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var player := Player.new()
	var state := State.new()
	state.energy = 40
	player.setup(state)
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)
	player.equip(1)
	var arc := player.rig._weapons[1]
	var indicator := arc.get_node("EnergyIndicator") as Node3D
	var connection := arc.get_node_or_null("ConnectionIndicator") as Node3D
	player._update_view(0)
	check(is_equal_approx(indicator.scale.x,.4),"visible horizontal indicator reads actual battery")
	check(connection != null,"donor connection has a distinct lamp")
	check(player.reload_weapon(),"indicator fixture starts ARC service")
	player._advance_reload(1.1)
	player._update_view(0)
	check(is_equal_approx(indicator.scale.x,.4),"extracted donor cannot fake battery gain")
	if connection != null: check(not connection.visible,"disconnected donor lamp is dark")
	check(player.activate_scan(),"scanner spends from connected common battery")
	player._update_view(0)
	check(is_equal_approx(indicator.scale.x,.2),"indicator follows SCAN during extraction")
	player._advance_reload(1.6)
	player._update_view(0)
	check(is_equal_approx(indicator.scale.x,.8),"indicator follows actual latch transfer")
	if connection != null: check(connection.visible,"closed latch reconnects donor lamp")
	state.recharge()
	player._update_view(0)
	check(is_equal_approx(indicator.scale.x,1.0),"refuge fill is shown immediately on next view update")
	player._advance_reload(1)
	check(player.fire(),"ready ARC fires after transfer")
	check(is_equal_approx(indicator.scale.x,.88),"fire updates indicator with new balance")
	for stream in [player._audio,player._manipulation_audio,player._scan_audio]:
		stream.stop()
		stream.stream = null
	await create_timer(.2).timeout
	player.free()
	await process_frame
	await create_timer(.2).timeout
	print("ARC INDICATOR FAILURES: ",failures)
	quit(1 if failures else 0)
