extends "res://tests/ads_fixture.gd"

const SETTINGS := "user://settings.cfg"
const SAVE := "user://silo9-save.json"
var app: Node
var saved_files: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func key(down: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F
	event.keycode = KEY_F
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func stick(down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_RIGHT_STICK
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func freeze() -> void:
	player = app.player
	player.set_physics_process(false)
	player.set_process(false)
	app.world.set_process(false)
	for node: Node in app.world.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)

func lamp() -> SpotLight3D:
	return player.find_child("Flashlight", true, false) as SpotLight3D

func is_on() -> bool:
	return bool(player.get("flashlight_on"))

func observe(expected: bool, label: String) -> void:
	check(is_on() == expected and lamp().visible == expected, label)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: real Main flashlight capture/input dispatch")
		quit(2)
		return
	for path: String in [SETTINGS, SAVE]:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	app = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	app.new_game()
	freeze()
	var available: bool = player.has_method("toggle_flashlight") and player.has_method("set_flashlight_quality") and lamp() != null
	check(available, "Player exposes real camera-mounted Flashlight and guarded toggle/quality APIs")
	if available:
		await contract()
	key(false)
	stick(false)
	paused = false
	for audio: AudioStreamPlayer in app.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	app.free()
	await create_timer(0.3).timeout
	for path: String in saved_files:
		if saved_files[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved_files[path])
	print("FLASHLIGHT INPUT FAILURES: ", failures)
	quit(1 if failures else 0)

func contract() -> void:
	observe(false, "New session starts with flashlight OFF")
	check(player.camera.is_ancestor_of(lamp()) and lamp().light_cull_mask == 1, "Flashlight follows actual camera and lights world layer only")
	check(InputMap.has_action("flashlight"), "Real InputMap exposes flashlight action")
	if not InputMap.has_action("flashlight"): return
	for azerty: bool in [false, true]:
		app.set_layout(azerty)
		var physical_f := false
		var right_stick := false
		for event: InputEvent in InputMap.action_get_events("flashlight"):
			if event is InputEventKey and event.physical_keycode == KEY_F: physical_f = true
			if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_STICK: right_stick = true
		check(physical_f and right_stick, "WASD/ZQSD keep physical F and right-stick bindings")
		key(true)
		observe(true, "Physical F dispatch toggles ON")
		key(true, true)
		observe(true, "Key repeat cannot toggle again")
		key(false)
		stick(true)
		observe(false, "Right-stick dispatch toggles OFF")
		stick(false)
	app.state.energy = 0
	var noises: Array[Vector3] = []
	player.noise_emitted.connect(func(origin: Vector3, _radius: float) -> void: noises.append(origin))
	var phase: int = app.state.phase
	var relay_visible: bool = app.world.objects.relay.visible
	check(bool(player.call("toggle_flashlight")), "Guarded toggle accepts live captured player with zero energy")
	observe(true, "Zero battery still permits exploration lamp")
	app.call("_process", .2)
	var status_visible := false
	for label: Label in app.hud.find_children("*", "Label", true, false):
		if label.is_visible_in_tree() and label.text.contains("LAMPE") and label.text.contains("ON"): status_visible = true
	check(status_visible, "Visible HUD reports flashlight ON")
	check(app.state.energy == 0 and app.state.phase == phase and app.world.objects.relay.visible == relay_visible and noises.is_empty(), "Flashlight consumes no battery, emits no noise, never discovers mandatory relay")
	var local_pose: Transform3D = lamp().transform
	player.camera.rotation.y += .4
	check(lamp().transform == local_pose and lamp().global_basis != lamp().basis, "Real lamp transforms with camera orientation")
	for low: bool in [true, false, true, false]:
		app.set_quality(low)
		observe(true, "Quality retains flashlight intent")
		check(lamp().shadow_enabled == not low, "Exploration shadow follows Main quality")
		var shadows := 0
		for light: Light3D in app.find_children("*", "Light3D", true, false):
			if light.visible and light.shadow_enabled and light.light_energy > 0: shadows += 1
		check(shadows == (0 if low else 1), "Active scene stays within exploration shadow budget")
	for mode: String in ["pause", "settings", "inventory"]:
		match mode:
			"pause": app.open_pause()
			"settings": app.open_settings()
			"inventory": app.open_inventory()
		check(not bool(player.call("toggle_flashlight")), "Toggle refuses inactive player in " + mode)
		key(true)
		observe(true, "Modal F press retains previous light state")
		app.resume_game()
		freeze()
		tick(.02)
		key(true, true)
		observe(true, "Held F cannot activate after modal resume")
		key(false)
		tick(.02)
		key(true)
		key(false)
		observe(false, "Fresh press after release rearms flashlight")
		key(true)
		key(false)
		observe(true, "Flashlight can be switched back on after modal")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	check(not bool(player.call("toggle_flashlight")), "Toggle refuses freely released cursor even if player remains active")
	key(true)
	key(false)
	observe(true, "Free-cursor key does not toggle")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	app.save_run()
	var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(save.schema == 3 and not save.has("flashlight_on"), "Flashlight stays transient outside save schema3")
	app.load_run()
	freeze()
	observe(false, "Loading creates a new player with lamp OFF")
	check(bool(player.call("toggle_flashlight")), "Replacement player can activate lamp")
	app.new_game()
	freeze()
	observe(false, "New game resets previously enabled lamp")
	player.call("toggle_flashlight")
	player.apply_damage(1000)
	observe(false, "Death extinguishes flashlight")
	check(not bool(player.call("toggle_flashlight")), "Dead player cannot activate flashlight")
