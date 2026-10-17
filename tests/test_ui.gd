extends SceneTree
var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main: Node = load("res://scripts/main.gd").new()
	main.boot_world = false
	root.add_child(main)
	await process_frame
	check(main.find_child("NewGame", true, false) is Button, "Main menu exposes a new mission button")
	check(main.find_child("Continue", true, false) is Button, "Main menu exposes continue")
	main.open_settings()
	check(main.mode == "settings", "Settings releases gameplay into a modal state")
	main.set_layout(true)
	check(InputMap.has_action("forward"), "FPS movement actions configured")
	check(InputMap.event_is_action(key_event(KEY_Z, KEY_W), "forward"), "AZERTY logical Z moves forward")
	check(InputMap.event_is_action(key_event(KEY_Q, KEY_A), "left"), "AZERTY logical Q moves left")
	check(not InputMap.event_is_action(key_event(KEY_Q, KEY_A), "scan"), "AZERTY Q does not trigger scanner")
	check(InputMap.event_is_action(key_event(KEY_A, KEY_Q), "scan"), "AZERTY logical A triggers scanner")
	main.set_layout(false)
	check(InputMap.event_is_action(key_event(KEY_W, KEY_W), "forward"), "WASD W moves forward")
	check(InputMap.event_is_action(key_event(KEY_A, KEY_A), "left"), "WASD A moves left")
	check(InputMap.event_is_action(key_event(KEY_Q, KEY_Q), "scan"), "WASD Q triggers scanner")
	main.state = load("res://scripts/run_state.gd").new()
	main.resume_game()
	check(main.mode == "playing" and not paused, "Resume restores live simulation")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	main._input(escape)
	check(main.mode == "pause" and paused, "Escape freezes simulation")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Pause releases mouse")
	main._input(escape)
	check(main.mode == "playing" and not paused, "Escape resumes simulation")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	main._input(tab)
	check(main.mode == "inventory" and paused, "Inventory is modal")
	main.state.health = 50.0
	main.state.medkits = 1
	main.state.energy = 20.0
	main.state.cells = 1
	main.open_inventory()
	main._input(key_event(KEY_H, KEY_H))
	check(main.state.health == 95.0 and main.state.medkits == 0, "Inventory H consumes a medkit and heals")
	check(main.content.get_child(2).text.contains("0 trousses"), "Inventory refreshes medkit count after H")
	main._input(key_event(KEY_B, KEY_B))
	check(main.state.energy == 80.0 and main.state.cells == 0, "Inventory B consumes a cell and recharges")
	check(main.content.get_child(2).text.contains("0 cellules"), "Inventory refreshes cell count after B")
	check(main.mode == "inventory" and paused, "Consumable shortcuts keep inventory modal")
	main._input(tab)
	check(main.mode == "playing" and not paused, "Tab closes inventory")
	main.open_ending()
	check(main.mode == "playing", "Final choice cannot open before the core")
	main.state.health = 0.0
	main._process(0.2)
	check(main.mode == "death" and paused, "Death freezes gameplay and offers restart")
	main.queue_free()
	print("UI TESTS: %d failures" % failures)
	quit(1 if failures else 0)

func key_event(logical: Key, physical: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = logical
	event.physical_keycode = physical
	return event
