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
	app.free()
	paused = false
	await create_timer(.2).timeout
	quit(0 if final_d9 and unchanged else 1)
