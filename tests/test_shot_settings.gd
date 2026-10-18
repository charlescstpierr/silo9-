extends SceneTree

var failures := 0
var app: Node
var saved_files: Dictionary = {}
const SETTINGS := "user://settings.cfg"
const SAVE := "user://silo9-save.json"

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func release_app() -> void:
	for audio in app.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	app.free()

func open_app() -> void:
	if is_instance_valid(app): release_app()
	paused = false
	app = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	app.open_settings()

func control_after(label_text: String, type: String) -> Node:
	for label in app.content.find_children("*", "Label", true, false):
		if not label.text.contains(label_text): continue
		var siblings: Node = label.get_parent()
		for index in range(label.get_index() + 1, siblings.get_child_count()):
			var node := siblings.get_child(index)
			if node.is_class(type): return node
	return null

func controls() -> Array:
	return [control_after("Impulsion caméra", "HSlider"), control_after("Lumière des départs", "HSlider"), control_after("Budget des effets", "OptionButton")]

func values(widgets: Array) -> Vector3:
	return Vector3(widgets[0].value, widgets[1].value, widgets[2].selected)

func set_values(widgets: Array, camera_strength: float, light_strength: float, budget: int) -> void:
	widgets[0].value = camera_strength
	widgets[1].value = light_strength
	widgets[2].select(budget)

func apply_button() -> void:
	for node in app.content.find_children("*", "Button", true, false):
		if node.text.begins_with("Appliquer"):
			node.pressed.emit()
			return
	check(false, "settings provide real Apply button")

func fire_from_app(camera_enabled: bool, light_enabled: bool, expected_cases: int) -> void:
	app.resume_game()
	app.player.set_physics_process(false)
	app.player.set_process(false)
	app.player.teleport(Vector3(0, 0, 7))
	app.state.ammo = 12
	app.player._shot_time = 0
	var base: float = app.player.camera.fov
	check(app.player.fire() and app.state.ammo == 11, "configured current player accepts and debits actual shot")
	check((app.player.camera.fov > base) == camera_enabled, "Main camera preference changes actual shot FOV")
	var visible_departure := false
	for mesh in app.player.rig.muzzle.find_children("*", "MeshInstance3D", true, false):
		visible_departure = visible_departure or mesh.is_visible_in_tree()
	check(visible_departure == light_enabled, "Main light preference changes actual departure visibility")
	var pool: Node
	for node in app.player.find_children("*", "", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path == "res://scripts/casing_pool.gd": pool = node
	check(pool != null, "Main player owns casing pool")
	if pool != null:
		var count := 0
		for mesh in pool.find_children("*", "MeshInstance3D", true, false):
			if mesh.is_visible_in_tree(): count += 1
		check(count == expected_cases, "Main budget preference changes actual casing output")

func write_config(camera_value: Variant, light_value: Variant, budget_value: Variant) -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "camera_impulse", camera_value)
	config.set_value("graphics", "shot_light", light_value)
	config.set_value("graphics", "effects_budget", budget_value)
	check(config.save(SETTINGS) == OK, "fixture settings written")

func run() -> void:
	for path in [SETTINGS, SAVE]:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	open_app()
	var widgets := controls()
	check(not widgets.has(null), "real Main settings expose camera, shot light and budget widgets")
	if not widgets.has(null):
		for label in app.content.find_children("*", "Label", true, false):
			if label.text.contains("IA conversationnelle"):
				check(widgets[2].get_index() < label.get_index(), "feedback options precede optional AI settings")
		check(values(widgets).is_equal_approx(Vector3(50, 100, 2)), "absent config defaults to 50 percent camera, full light, normal budget")
		check(widgets[0].min_value == 0 and widgets[0].max_value == 100 and widgets[0].step == 10 and widgets[1].step == 10, "attenuation sliders expose 0..100 percent in ten-percent steps")
		check(widgets[2].item_count == 3 and widgets[2].get_item_text(0) == "Minimal" and widgets[2].get_item_text(1) == "Réduit" and widgets[2].get_item_text(2) == "Normal", "budget has three player-facing levels")
		var old := ConfigFile.new()
		old.set_value("controls", "sensitivity", .003)
		old.set_value("graphics", "low_quality", true)
		old.save(SETTINGS)
		open_app()
		check(values(controls()).is_equal_approx(Vector3(50, 100, 2)) and app.low_quality, "old config preserves existing preferences and defaults only new fields")
		for invalid in [["bad", {}, 1.5], [NAN, INF, -1], [-2.0, 4.0, 8]]:
			write_config(invalid[0], invalid[1], invalid[2])
			open_app()
			var expected := Vector3(0, 100, 2) if invalid[0] is float and invalid[0] == -2.0 else Vector3(50, 100, 2)
			check(values(controls()).is_equal_approx(expected), "invalid types/nonfinite values default; finite numbers clamp; enum rejects invalid values")
		write_config(.5, 1.0, 2)
		open_app()
		app.new_game()
		app.player.set_physics_process(false)
		app.open_settings()
		set_values(controls(), 0, 0, 0)
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		app._input(escape)
		app.open_settings()
		check(values(controls()).is_equal_approx(Vector3(50, 100, 2)), "Escape discards uncommitted controls")
		fire_from_app(true, true, 1)
		app.open_settings()
		set_values(controls(), 0, 0, 0)
		app.endpoint_input.text = "http://example.com"
		apply_button()
		check(app.mode == "settings", "existing endpoint validation refuses Apply")
		var persisted := ConfigFile.new()
		persisted.load(SETTINGS)
		check(persisted.get_value("graphics", "camera_impulse") == .5 and persisted.get_value("graphics", "effects_budget") == 2, "refused Apply leaves saved options unchanged")
		fire_from_app(true, true, 1)
		app.open_settings()
		set_values(controls(), 0, 0, 0)
		app.endpoint_input.text = ""
		apply_button()
		persisted.load(SETTINGS)
		check(persisted.get_value("graphics", "camera_impulse", -1) == 0 and persisted.get_value("graphics", "shot_light", -1) == 0 and persisted.get_value("graphics", "effects_budget", -1) == 0, "Apply persists all three graphics keys")
		fire_from_app(false, false, 0)
		var old_player: int = app.player.get_instance_id()
		app.new_game()
		check(app.player.get_instance_id() != old_player, "new game replaces Player")
		fire_from_app(false, false, 0)
		app.save_run()
		var save: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		check(save is Dictionary and save.get("schema") == 3 and not save.has("camera_impulse") and not save.has("shot_light") and not save.has("effects_budget"), "graphics preferences stay outside gameplay save")
		old_player = app.player.get_instance_id()
		app.load_run()
		check(app.player.get_instance_id() != old_player, "load replaces Player")
		fire_from_app(false, false, 0)
		open_app()
		check(values(controls()).is_equal_approx(Vector3.ZERO), "fresh Main reads persisted disabled effects")
		app.new_game()
		fire_from_app(false, false, 0)
		app.open_settings()
		set_values(controls(), 100, 100, 1)
		app.quality_check.button_pressed = not app.quality_check.button_pressed
		apply_button()
		fire_from_app(true, true, 1)
		check(not app.player._flash_light.visible, "reduced effects budget suppresses dynamic light independently of quality")
	release_app()
	paused = false
	await create_timer(.3).timeout
	for path in saved_files:
		if saved_files[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved_files[path])
	print("SHOT SETTINGS FAILURES: ", failures)
	quit(1 if failures else 0)
