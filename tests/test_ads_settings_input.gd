extends "res://tests/ads_fixture.gd"

const SETTINGS := "user://settings.cfg"
const SAVE := "user://silo9-save.json"
var app: Node
var saved_files := {}
var setting_locations: Array[Array] = []

func _initialize() -> void:
	run.call_deferred()

func open_app() -> void:
	if is_instance_valid(app): release_app()
	paused = false
	app = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)

func release_app() -> void:
	for audio in app.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	app.free()

func freeze_run() -> void:
	player = app.player
	player.set_physics_process(false)
	player.set_process(false)
	app.world.set_process(false)
	app.world.set_physics_process(false)
	for node in app.world.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)

func widgets() -> Array:
	return [app.content.find_child("FovSlider", true, false), app.content.find_child("AimZoomSlider", true, false), app.content.find_child("AimSensitivitySlider", true, false)]

func read_widgets() -> Vector3:
	var controls := widgets()
	return Vector3(controls[0].value, controls[1].value, controls[2].value)

func write_widgets(values: Vector3) -> void:
	var controls := widgets()
	for index in 3: controls[index].value = values[index]

func apply_options() -> void:
	for button in app.content.find_children("*", "Button", true, false):
		if button.text.begins_with("Appliquer"):
			button.pressed.emit()
			return
	check(false, "actual settings Apply button exists")

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func joy_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func joy_button(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func has_axis(action: String, axis: JoyAxis, direction: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and signf(event.axis_value) == direction: return true
	return false

func has_button(action: String, button: JoyButton) -> bool:
	if not InputMap.has_action(action): return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button: return true
	return false

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: real Main capture/input dispatch")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	for path in [SETTINGS, SAVE]:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	open_app()
	app.open_settings()
	var controls := widgets()
	check(controls.all(func(control: Variant) -> bool: return control is HSlider), "Main exposes named FOV, zoom and ADS sensitivity sliders")
	if controls.all(func(control: Variant) -> bool: return control is HSlider):
		settings_contract()
	else:
		print("GUARDED: Apply/config/invalid/new/load preference coverage awaits widgets")
	open_app()
	await process_frame
	var focus := root.gui_get_focus_owner()
	check(focus is Button and focus.is_visible_in_tree(), "main menu grants an initial usable GUI focus")
	await menu_accept_contract()
	joypad_contract()
	modal_contract()
	joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
	joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	joy_axis(JOY_AXIS_RIGHT_X, 0)
	joy_axis(JOY_AXIS_LEFT_Y, 0)
	release_inputs()
	await create_timer(.25).timeout
	release_app()
	paused = false
	await create_timer(.3).timeout
	for path in saved_files:
		if saved_files[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved_files[path])
	print("ADS SETTINGS INPUT FAILURES: ", failures)
	quit(1 if failures else 0)

func settings_contract() -> void:
	check(read_widgets().is_equal_approx(Vector3(76, 1.25, .65)), "absent ADS config loads documented defaults")
	var controls := widgets()
	check(controls[0].min_value == 60 and controls[0].max_value == 100 and controls[1].min_value == 1 and controls[1].max_value == 1.6 and controls[2].min_value == .2 and controls[2].max_value == 1, "real widgets expose accepted physical option ranges")
	write_widgets(Vector3(91, 1.4, .4))
	apply_options()
	var config := ConfigFile.new()
	check(config.load(SETTINGS) == OK, "Apply actually writes local settings.cfg")
	for value in [91.0, 1.4, .4]:
		var location: Array = []
		for section in config.get_sections():
			for setting in config.get_section_keys(section):
				var stored: Variant = config.get_value(section, setting)
				if (stored is float or stored is int) and is_equal_approx(float(stored), value): location = [section, setting]
		check(not location.is_empty(), "Apply persists ADS preference %.2f" % value)
		setting_locations.append(location)
	if setting_locations.any(func(location: Array) -> bool: return location.is_empty()):
		print("GUARDED: malformed-config injection requires actual persisted option keys")
		return
	app.new_game()
	freeze_run()
	observe_options(Vector3(91, 1.4, .4), "new game")
	app.open_settings()
	write_widgets(Vector3(60, 1, 1))
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	app.open_settings()
	check(read_widgets().is_equal_approx(Vector3(91, 1.4, .4)), "Escape discards unapplied ADS controls")
	app.resume_game()
	observe_options(Vector3(91, 1.4, .4), "cancelled options")
	app.open_settings()
	write_widgets(Vector3(60, 1.6, .2))
	app.endpoint_input.text = "http://example.com"
	apply_options()
	check(app.mode == "settings", "invalid endpoint refuses entire Apply")
	config.load(SETTINGS)
	check(is_equal_approx(float(config.get_value(setting_locations[0][0], setting_locations[0][1])), 91), "refused Apply leaves persisted FOV unchanged")
	app.endpoint_input.text = ""
	apply_options()
	app.resume_game()
	observe_options(Vector3(60, 1.6, .2), "Apply to current Player")
	app.save_run()
	var save: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(save is Dictionary and save.get("schema") == 3, "ADS preferences keep the sector-power save schema")
	if save is Dictionary:
		for location in setting_locations: check(not save.has(location[1]), "ADS preference stays outside gameplay save: " + location[1])
	var previous: int = player.get_instance_id()
	app.load_run()
	freeze_run()
	check(player.get_instance_id() != previous, "load constructs a replacement Player")
	observe_options(Vector3(60, 1.6, .2), "load")
	open_app()
	app.open_settings()
	check(read_widgets().is_equal_approx(Vector3(60, 1.6, .2)), "fresh Main reads actual persisted preferences")
	for invalid in [[true, false, true], ["91", {}, []], [NAN, INF, -INF], [-5.0, 8.0, -.5]]:
		config = ConfigFile.new()
		for index in 3: config.set_value(setting_locations[index][0], setting_locations[index][1], invalid[index])
		check(config.save(SETTINGS) == OK, "boundary fixture writes actual config")
		open_app()
		app.open_settings()
		var expected := Vector3(60, 1.6, .2) if invalid[0] is float and invalid[0] == -5.0 else Vector3(76, 1.25, .65)
		check(read_widgets().is_equal_approx(expected), "numeric finite values clamp; bool/type/nonfinite values default")
		app.new_game()
		freeze_run()
		observe_options(expected, "loaded boundary config")
	if FileAccess.file_exists(SETTINGS): DirAccess.remove_absolute(SETTINGS)

func observe_options(options: Vector3, context: String) -> void:
	app.resume_game()
	freeze_run()
	aim(false)
	advance(.4)
	check(near_fov(options.x), context + " applies hip FOV to actual camera")
	aim(true)
	advance(.4)
	check(near_fov(zoom_fov(options.x, options.y)), context + " applies optical magnification")
	var yaw := player.rotation.y
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(20, 0)
	player._unhandled_input(event)
	check(absf(player.rotation.y - yaw + 20 * player.sensitivity * options.z) < .00001, context + " applies ADS sensitivity to actual rotation")
	aim(false)
	advance(.3)

func menu_accept_contract() -> void:
	var button := app.content.find_child("NewGame", true, false) as Button
	check(button != null, "real New Game button is available for joypad activation")
	if button == null: return
	button.grab_focus()
	joy_button(JOY_BUTTON_A, true)
	await process_frame
	joy_button(JOY_BUTTON_A, false)
	await process_frame
	check(app.mode == "playing", "software GUI A activates focused New Game")
	if app.mode == "playing":
		freeze_run()
		tick(.01)
		check(player.velocity.y <= 0, "GUI A used to enter game does not also jump")

func joypad_contract() -> void:
	for binding in [["aim", JOY_AXIS_TRIGGER_LEFT], ["fire", JOY_AXIS_TRIGGER_RIGHT]]:
		check(has_axis(binding[0], binding[1], 1), "actual InputMap binds trigger to " + binding[0])
	for binding in [["jump", JOY_BUTTON_A], ["reload", JOY_BUTTON_X], ["interact", JOY_BUTTON_Y], ["scan", JOY_BUTTON_RIGHT_SHOULDER], ["weapon1", JOY_BUTTON_LEFT_SHOULDER], ["weapon2", JOY_BUTTON_DPAD_RIGHT], ["sprint", JOY_BUTTON_LEFT_STICK], ["pause", JOY_BUTTON_START]]:
		check(has_button(binding[0], binding[1]), "actual InputMap binds joypad button to " + binding[0])
	for azerty in [true, false]:
		app.set_layout(azerty)
		check(has_axis("forward", JOY_AXIS_LEFT_Y, -1) and has_axis("back", JOY_AXIS_LEFT_Y, 1) and has_axis("left", JOY_AXIS_LEFT_X, -1) and has_axis("right", JOY_AXIS_LEFT_X, 1) and has_button("scan", JOY_BUTTON_RIGHT_SHOULDER), "layout switch preserves joypad movement and scan bindings")
	app.new_game()
	freeze_run()
	player.teleport(Vector3(0, 0, 7))
	joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
	tick(.01)
	joy_axis(JOY_AXIS_TRIGGER_LEFT, 1)
	advance(.4)
	check(near_fov(zoom_fov(76, 1.25)), "software LT event enters ADS through actual mapping")
	var yaw := player.rotation.y
	joy_axis(JOY_AXIS_RIGHT_X, .19)
	tick(.1)
	check(is_equal_approx(player.rotation.y, yaw), "right-stick motion inside radial deadzone does not rotate")
	joy_axis(JOY_AXIS_RIGHT_X, .15)
	joy_axis(JOY_AXIS_RIGHT_Y, .15)
	var pitch := player.camera.rotation.x
	tick(.1)
	check(player.rotation.y < yaw and player.camera.rotation.x < pitch, "diagonal stick magnitude above .2 escapes the radial deadzone")
	joy_axis(JOY_AXIS_RIGHT_Y, 0)
	yaw = player.rotation.y
	joy_axis(JOY_AXIS_RIGHT_X, 1)
	tick(.1)
	joy_axis(JOY_AXIS_RIGHT_X, 0)
	check(absf(player.rotation.y - yaw + 2 * .1 * .65) < .001, "full software right stick rotates 2rad/s with ADS sensitivity")
	joy_axis(JOY_AXIS_LEFT_Y, -1)
	advance(.3)
	check(Vector2(player.velocity.x, player.velocity.z).length() > 3.9, "software left stick drives actual movement")
	joy_axis(JOY_AXIS_LEFT_Y, 0)
	advance(.3)
	var ammo := player.state.ammo
	joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	tick(.01)
	joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	check(player.state.ammo == ammo - 1, "software RT accepts exactly one D9 shot")
	joy_button(JOY_BUTTON_X, true)
	joy_button(JOY_BUTTON_X, false)
	check(not player.reload_cycle.ready, "software X requests real reload")
	advance(4)
	check(player.state.ammo == 12 and player.reload_cycle.ready, "software reload completes round transfer")
	joy_button(JOY_BUTTON_DPAD_RIGHT, true)
	joy_button(JOY_BUTTON_DPAD_RIGHT, false)
	advance(1)
	check(player.weapon_index == 1, "software weapon2 command selects ARC")
	joy_button(JOY_BUTTON_LEFT_SHOULDER, true)
	joy_button(JOY_BUTTON_LEFT_SHOULDER, false)
	advance(1)
	check(player.weapon_index == 0, "distinct software weapon1 command selects D9")
	var energy := player.state.energy
	joy_button(JOY_BUTTON_RIGHT_SHOULDER, true)
	joy_button(JOY_BUTTON_RIGHT_SHOULDER, false)
	check(player.state.energy == energy - 20, "software RB invokes scanner with actual energy debit")
	joy_button(JOY_BUTTON_START, true)
	joy_button(JOY_BUTTON_START, false)
	check(app.mode == "pause" and paused, "software Start opens actual pause menu")
	joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	var paused_ammo := player.state.ammo
	joy_button(JOY_BUTTON_START, true)
	joy_button(JOY_BUTTON_START, false)
	check(app.mode == "playing" and not paused, "software Start resumes without a gameplay command")
	advance(.4)
	check(player.state.ammo == paused_ammo and near_fov(76), "Start resume suppresses held fire and aim triggers")
	joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
	aim(false)
	advance(.4)

func modal_contract() -> void:
	app.resume_game()
	freeze_run()
	for first in ["mouse", "trigger"]:
		aim(false)
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
		advance(.3)
		aim(true)
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 1)
		advance(.4)
		if first == "mouse": aim(false)
		else: joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
		advance(.4)
		check(near_fov(zoom_fov(76, 1.25)), "releasing " + first + " retains ADS from the other held source")
		aim(false)
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
		advance(.3)
	for operation in ["pause", "settings", "inventory", "new", "load"]:
		app.save_run()
		aim(true)
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 1)
		advance(.4)
		match operation:
			"pause": app.open_pause()
			"settings": app.open_settings()
			"inventory": app.open_inventory()
			"new": app.new_game()
			"load": app.load_run()
		freeze_run()
		app.resume_game()
		advance(.4)
		check(near_fov(76), operation + " suppresses held aim after resume/replacement")
		aim(false)
		advance(.3)
		check(near_fov(76), operation + " remains disarmed while LT is still held")
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
		tick(.01)
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 1)
		advance(.4)
		check(near_fov(zoom_fov(76, 1.25)), operation + " rearms only after every source released and a fresh LT press")
		joy_axis(JOY_AXIS_TRIGGER_LEFT, 0)
		advance(.3)
