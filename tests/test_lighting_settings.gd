extends SceneTree

const SETTINGS := "user://settings.cfg"
const SAVE := "user://silo9-save.json"
var app: Node
var failures: int = 0
var saved_files: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func close_app() -> void:
	if not is_instance_valid(app): return
	for audio: AudioStreamPlayer in app.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	app.free()
	paused = false

func open_app() -> void:
	close_app()
	app = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	app.open_settings()

func option() -> BaseButton:
	for button: BaseButton in app.content.find_children("*", "BaseButton", true, false):
		if button.text == "Réduire les variations lumineuses": return button
	return null

func apply_options() -> void:
	for button: Button in app.content.find_children("*", "Button", true, false):
		if button.text.begins_with("Appliquer"):
			button.pressed.emit()
			return
	check(false, "Settings provides actual Apply button")

func run() -> void:
	for path: String in [SETTINGS, SAVE]:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	open_app()
	check(option() != null, "Settings exposes explicit reduced-light-variations boolean")
	if option() != null: contract()
	close_app()
	await create_timer(.3).timeout
	for path: String in saved_files:
		if saved_files[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved_files[path])
	print("LIGHTING SETTINGS FAILURES: ", failures)
	quit(1 if failures else 0)

func contract() -> void:
	check(not option().button_pressed, "Absent config defaults to animated light effects")
	option().button_pressed = true
	apply_options()
	var config := ConfigFile.new()
	check(config.load(SETTINGS) == OK, "Apply persists real local settings")
	var location: Array[String] = []
	for section: String in config.get_sections():
		for key: String in config.get_section_keys(section):
			if config.get_value(section, key) is bool and config.get_value(section, key) == true: location = [section, key]
	check(location.size() == 2, "Enabled option is persisted as boolean")
	if location.size() != 2: return
	check(config.get_value("graphics", "effects_budget") == 2 and is_equal_approx(config.get_value("graphics", "shot_light"), 1.0), "Accessibility option leaves effects budget and shot strength unchanged")
	app.new_game()
	check(app.world.has_method("set_reduced_light_effects"), "Main constructs world with reduced-light API")
	observe_reduced("new game")
	app.save_run()
	var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(save.schema == 3 and not save.has(location[1]), "Accessibility preference stays outside gameplay save")
	app.load_run()
	observe_reduced("load")
	open_app()
	check(option().button_pressed, "Fresh Main reads enabled option")
	option().button_pressed = false
	app.endpoint_input.text = "http://example.com"
	apply_options()
	config.load(SETTINGS)
	check(app.mode == "settings" and config.get_value(location[0], location[1]) == true, "Refused Apply cannot change accessibility preference")
	for invalid: Variant in ["true", 1, 0, {}, []]:
		config.set_value(location[0], location[1], invalid)
		config.save(SETTINGS)
		open_app()
		check(not option().button_pressed, "Malformed nonboolean reduced option defaults to false")

func observe_reduced(context: String) -> void:
	if not app.world.has_method("set_reduced_light_effects"): return
	var ceiling := app.world.find_child("ceiling_maintenance", true, false) as OmniLight3D
	check(ceiling != null, "Constructed world exposes actual maintenance source")
	if ceiling == null: return
	app.world.set_process(false)
	var energy: float = ceiling.light_energy
	for step: int in 80:
		app.world.call("_process", .1)
		check(is_equal_approx(energy, ceiling.light_energy), context + " applies saved reduced option across full neon cycle")
	app.world.call("_set_colossus_gain", .05)
	check(is_equal_approx(energy, ceiling.light_energy), context + " applies saved reduced option to colossus")
	app.world.call("_set_colossus_gain", 1.0)
