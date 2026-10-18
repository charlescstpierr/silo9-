extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(value: bool,label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1
func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event
func run() -> void:
	var app: Node = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.player.teleport(Vector3(0,0,7))
	app.state.ammo = 4
	app.state.reserve = 17
	check(app.player.reload_weapon(),"real scene begins partial reload")
	await create_timer(.6).timeout
	var magazine: Node3D = app.player.rig._weapons[0].get_node("Magazine")
	var pose := magazine.transform
	app._input(key(KEY_ESCAPE))
	check(paused and not app.player.active,"Escape pauses actual player tree")
	check(not app.player._manipulation_audio.playing,"pause stops actual manipulation player")
	var clock: float = app.player.reload_cycle._time
	await create_timer(.3,true).timeout
	check(app.player.reload_cycle._time == clock and magazine.transform == pose,"paused tree keeps manipulation pose frozen")
	app._input(key(KEY_ESCAPE))
	await create_timer(.5).timeout
	check(app.player.reload_cycle.ready and app.state.ammo == 4 and app.state.reserve == 17,"resume safely lowers and raises without committing")
	app.player.reload_weapon()
	await create_timer(.7).timeout
	app._input(key(KEY_F5))
	var old_player_id: int = app.player.get_instance_id()
	app.state.ammo = 1
	app.state.reserve = 2
	app.load_run()
	app.resume_game()
	await process_frame
	check(app.player.get_instance_id() != old_player_id and app.state.ammo == 4 and app.state.reserve == 17 and app.player.reload_cycle.ready,"save/load before commit restores previous counts with ready D9")
	app.player.reload_weapon()
	await create_timer(app.player.D9.reload_duration+.15).timeout
	check(app.state.ammo == 12 and app.state.reserve == 9,"normal reload commits in live scene")
	app._input(key(KEY_F5))
	old_player_id = app.player.get_instance_id()
	app.state.ammo = 2
	app.state.reserve = 1
	app.load_run()
	app.resume_game()
	await process_frame
	check(app.player.get_instance_id() != old_player_id and app.state.ammo == 12 and app.state.reserve == 9 and app.player.reload_cycle.ready,"save/load after commit restores new counts with ready D9")
	app.player.set_physics_process(false)
	var node_count := get_node_count()
	var meshes: Array[Mesh] = []
	for node in app.player.rig.find_children("*","MeshInstance3D",true,false): meshes.append(node.mesh)
	for repetition in 100:
		app.state.ammo = 0 if repetition % 2 == 0 else 5
		app.state.reserve = 12
		app.player.reload_weapon()
		while not app.player.reload_cycle.ready:
			app.player._advance_reload(.025)
			app.player._update_view(.025)
	check(get_node_count() == node_count,"100 reloads do not add scene nodes")
	var index := 0
	for node in app.player.rig.find_children("*","MeshInstance3D",true,false):
		check(node.mesh == meshes[index],"reload reuses mesh resource %d"%index)
		index += 1
	app.queue_free()
	paused = false
	await create_timer(.4,true).timeout
	print("D9 MODAL/SAVE FAILURES: ",failures)
	quit(1 if failures else 0)
