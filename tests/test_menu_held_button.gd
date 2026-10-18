extends SceneTree

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)

func mouse_button(position: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.position = position
	event.global_position = position
	event.pressed = down
	Input.parse_input_event(event)

func settings_button(app: Node) -> Button:
	for child in app.content.get_children():
		if child is Button and child.text == "Réglages":
			return child
	return null

func hover(button: Button) -> Vector2:
	var position := button.get_global_rect().get_center()
	Input.warp_mouse(position)
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	Input.parse_input_event(event)
	await process_frame
	return position

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: held menu button needs X11 GUI dispatch")
		quit(2)
		return
	var app: Node = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	await process_frame
	app.new_game()
	app.player.teleport(Vector3(0, 0, 7))
	await create_timer(.1).timeout
	key(KEY_ESCAPE)
	await process_frame
	await process_frame
	var settings := settings_button(app)
	check(app.mode == "pause" and settings != null and settings.is_visible_in_tree(), "pause shows a real settings button")
	if settings == null:
		quit(1)
		return
	var position := await hover(settings)
	mouse_button(position, true)
	await process_frame
	check(app.mode == "pause" and settings.button_pressed, "mouse down arms settings without opening it")
	mouse_button(position, false)
	await process_frame
	check(app.mode == "settings" and app.sensitivity_slider.is_visible_in_tree(), "normal GUI click opens usable settings")
	key(KEY_ESCAPE)
	await process_frame
	await process_frame
	settings = settings_button(app)
	check(app.mode == "pause" and settings != null, "Escape returns settings to pause")
	if settings == null:
		quit(1)
		return
	position = await hover(settings)
	mouse_button(position, true)
	await process_frame
	check(settings.button_pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "real pause button is held before Escape")
	var ammo_before: int = app.state.ammo
	key(KEY_ESCAPE)
	await create_timer(.2, true).timeout
	check(app.mode == "playing" and not paused and app.player.active, "Escape resumes gameplay while settings button is held")
	check(not app.panel.visible and not app.overlay.visible and app.hud.visible, "resume hides the modal and restores the HUD")
	check(app.state.ammo == ammo_before, "held menu click does not fire on resume")
	mouse_button(position, false)
	await create_timer(.2, true).timeout
	check(app.mode == "playing" and not paused, "releasing the cancelled click does not reopen settings")
	app.notice_label.text = ""
	key(KEY_F5)
	await process_frame
	check(app.notice_label.text == "Progression sauvegardée.", "F5 remains available after held-button resume")
	app.free()
	paused = false
	await create_timer(.1, true).timeout
	print("MENU HELD BUTTON FAILURES: ", failures)
	quit(1 if failures else 0)
