extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func key(code: Key, down: bool, repeated: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.echo = repeated
	Input.parse_input_event(event)

func run() -> void:
	var app: Node = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	await process_frame
	app.new_game()
	app.player.teleport(Vector3(0,0,7))
	key(KEY_2,true)
	key(KEY_2,false)
	await create_timer(.4).timeout
	assert(app.player.weapon_index == 1 and app.player.reload_cycle.ready)
	key(KEY_1,true)
	key(KEY_1,false)
	key(KEY_2,true)
	key(KEY_2,false)
	key(KEY_1,true,true)
	key(KEY_1,false)
	await create_timer(.4).timeout
	var final_d9: bool = app.player.reload_cycle.ready and app.player.weapon_index == 0 and app.player.reload_cycle._destination == 0
	var unchanged: bool = app.state.ammo == 12 and app.state.energy == 100
	print("PASS: coalesced release and echoed selection keeps final D9 intent" if final_d9 else "FAIL: coalesced release and echoed selection loses final D9 intent")
	print("PASS: repeated selection spends no resources" if unchanged else "FAIL: repeated selection spent resources")
	var shot: bool = app.player.fire()
	var d9_debit: bool = shot and app.state.ammo == 11 and app.state.energy == 100
	print("PASS: final selection fires D9 ammo only" if d9_debit else "FAIL: final selection fires wrong weapon resources")
	key(KEY_1,true)
	key(KEY_1,false)
	await create_timer(.4).timeout
	app.player.set_physics_process(false)
	key(KEY_2,true)
	await process_frame
	app.player._advance_reload(.08)
	app.player._update_view(.08)
	key(KEY_2,true,true)
	await process_frame
	app.player._advance_reload(.081)
	app.player._update_view(.081)
	var clock_preserved: bool = app.player.weapon_index == 1 and not app.player.reload_cycle.ready
	print("PASS: repeated same destination preserves lower clock" if clock_preserved else "FAIL: repeated same destination restarts lower clock")
	key(KEY_2,false)
	for stream in [app.player._audio,app.player._manipulation_audio,app.player._scan_audio]:
		stream.stop()
		stream.stream = null
	await create_timer(.2).timeout
	app.free()
	paused = false
	await create_timer(.2).timeout
	quit(0 if final_d9 and unchanged and d9_debit and clock_preserved else 1)
