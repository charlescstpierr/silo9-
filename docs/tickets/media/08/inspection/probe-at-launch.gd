extends SceneTree
## Evidence fixture: real production scene and rig; no material or geometry overrides.

var app: Node
var output := ""
var mode := "inspection"
var evidence_label := "source unchanged"
var label: Label
var environment: Environment
var saved_environment: Environment
var test_light: OmniLight3D
var stage := "warmup"
var location := "isolated bay x1000"
var lighting := "cold"
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var segments: Array[Dictionary] = []
var frames: Array[Dictionary] = []
var inventory_before: Dictionary
var last_drawn := 0
var last_progress_usec := 0
var finishing := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="): output = argument.trim_prefix("--proof-output=")
		elif argument.begins_with("--probe-mode="): mode = argument.trim_prefix("--probe-mode=")
		elif argument.begins_with("--evidence-label="): evidence_label = argument.trim_prefix("--evidence-label=")
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	check(not output.is_empty(), "output folder required")
	if output.is_empty():
		quit(1)
		return
	check(DirAccess.make_dir_recursive_absolute(output) == OK, "cannot create output folder")
	if FileAccess.file_exists(output.path_join("materials.json")):
		push_error("refusing to overwrite existing report")
		quit(1)
		return
	check(mode in ["inspection", "film"], "mode must be inspection or film")
	var version := Engine.get_version_info()
	check(version.major == 4 and version.minor == 7 and version.patch == 2, "requires Godot 4.7.2")
	check(DisplayServer.get_name().to_lower() == "x11", "requires X11")
	check(RenderingServer.get_current_rendering_method() == "gl_compatibility", "requires Compatibility")
	check(RenderingServer.get_current_rendering_driver_name() in ["opengl3", "opengl3_es", "opengl3_angle"], "requires OpenGL")
	check(not RenderingServer.get_video_adapter_name().strip_edges().is_empty(), "missing video adapter")
	check(RenderingServer.is_render_loop_enabled(), "disabled render loop")
	if mode == "film":
		var arguments := OS.get_cmdline_args()
		var fixed := arguments.find("--fixed-fps")
		check(fixed >= 0 and fixed + 1 < arguments.size() and arguments[fixed + 1] == "30", "film requires --fixed-fps 30")
		check(arguments.has("--write-movie"), "film requires actual engine movie output")
	if not failures.is_empty():
		finish()
		return
	root.size = Vector2i(1280, 720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_quality(false)
	app.player.configure_feedback(.5, 1.0, 2)
	app.player.configure_aim(76.0, 1.25, .65)
	for enemy in app.world.enemies:
		enemy.set_process(false)
		enemy.set_physics_process(false)
	saved_environment = app.world.ambience.environment
	environment = saved_environment.duplicate()
	app.world.ambience.environment = environment
	build_bay()
	label = Label.new()
	label.position = Vector2(24, 100)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.ui.add_child(label)
	last_drawn = Engine.get_frames_drawn()
	last_progress_usec = Time.get_ticks_usec()
	await setup(0, "cold")
	await capture("renderer-warmup")
	inventory_before = inventory()
	if mode == "inspection": await inspection()
	else: await film()
	check(app.state.health > 0.0 and app.player.active, "player no longer healthy/active")
	check(captures.size() == (17 if mode == "inspection" else 13), "incorrect capture quota")
	finish()

func _process(_delta: float) -> bool:
	if last_progress_usec > 0 and not finishing:
		if Engine.get_frames_drawn() != last_drawn:
			last_drawn = Engine.get_frames_drawn()
			last_progress_usec = Time.get_ticks_usec()
		elif Time.get_ticks_usec() - last_progress_usec > 10000000:
			check(false, "no rendered frame progress for 10 seconds")
			finish()
	return false

func finish() -> void:
	if finishing: return
	finishing = true
	var result := {"schema":1, "mode":mode, "evidence_label":evidence_label,
		"engine":Engine.get_version_info(), "display":DisplayServer.get_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"rendering_driver":RenderingServer.get_current_rendering_driver_name(),
		"adapter":RenderingServer.get_video_adapter_name(), "render_loop":RenderingServer.is_render_loop_enabled(),
		"captures":captures, "segments":segments, "film_frames":frames,
		"inventory_before":inventory_before, "inventory_after":inventory() if is_instance_valid(app) else {},
		"failures":failures, "performance_valid":false, "pixel_review":"pending independent human/agent inspection",
		"fixture_changes":"Isolated physical bay and one Omni; duplicate ambient/fog environment in bay; actual FPS light retained. Enemy callbacks frozen, collisions retained. Film rotations directly controlled; software right movement and RMB; R/B call production APIs with declared resource setup. No rig geometry/material changes.",
		"limits":"Film fixed 30fps is not performance. No physical input, Windows, gaming GPU, continuous viewing or aesthetic PASS established by fixture."}
	var file := FileAccess.open(output.path_join("materials.json"), FileAccess.WRITE)
	if file == null:
		push_error("cannot write materials.json")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	if InputMap.has_action("right"):
		Input.action_release("right")
	aim(false)
	print("MATERIALS_PROOF captures=", captures.size(), " segments=", segments.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)

func build_bay() -> void:
	var body := StaticBody3D.new()
	body.name = "MaterialProofFloor"
	root.add_child(body)
	body.position = Vector3(1000, -.1, 0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, .2, 40)
	collision.shape = shape
	body.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.13, .17, .23)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	test_light = OmniLight3D.new()
	test_light.name = "DeclaredMaterialProofLight"
	test_light.position = Vector3(1001.2, 2.5, 5.0)
	test_light.omni_range = 6.0
	test_light.light_cull_mask = 3
	test_light.shadow_enabled = false
	root.add_child(test_light)

func setup(weapon: int, condition: String) -> void:
	aim(false)
	app.set_quality(false)
	app.player.teleport(Vector3(1000, 0, 7))
	aim(false)
	location = "isolated bay x1000"
	lighting = condition
	app.world.ambience.environment = environment
	environment.ambient_light_color = Color("7c9eac")
	environment.ambient_light_energy = .18 if condition != "dim" else .025
	environment.fog_enabled = false
	test_light.visible = true
	test_light.light_color = Color("ff6439") if condition == "red" else Color("b0d6df")
	test_light.light_energy = .08 if condition == "dim" else 1.5
	await ready_weapon(weapon)
	await create_timer(.6).timeout

func ready_weapon(index: int) -> void:
	if app.player.weapon_index != index: app.player.equip(index)
	for tick in 600:
		if app.player.weapon_index == index and app.player.reload_cycle.ready and app.player._shot_time <= 0.0: return
		await physics_frame
	check(false, "weapon never ready")

func aim(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func refresh_label() -> void:
	label.text = "%s | %s\n%s; %s; quality=%s\n%s" % [evidence_label, stage, location, lighting, "Low" if app.low_quality else "Normal", "Film fixed 30fps; not performance" if mode == "film" else "Production materials; declared fixture lighting"]
func capture(name: String) -> void:
	stage = name
	refresh_label()
	var before := Engine.get_frames_drawn()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(Engine.get_frames_drawn() > before, "no frame progress: " + name)
	check(not image.is_empty() and image.get_size() == Vector2i(1280, 720), "invalid rendered image: " + name)
	if not image.is_empty(): check(image.save_png(output.path_join(name + ".png")) == OK, "cannot save " + name)
	var record := observation()
	record.merge({"file":name + ".png", "overlay":label.text, "lighting_state":light_state(), "frame_before":before,"rig_transforms":rig_transforms()})
	captures.append(record)

func inspection() -> void:
	for weapon in 2:
		for condition in ["cold", "red", "dim"]:
			await setup(weapon, condition)
			await capture("bay-w%d-%s-hip" % [weapon, condition])
			aim(true)
			await create_timer(.7).timeout
			check(app.player.aim_weight >= .99, "ADS failed to settle")
			await capture("bay-w%d-%s-ads" % [weapon, condition])
	aim(false)
	test_light.visible = false
	app.world.ambience.environment = saved_environment
	location = "real SILO refuge (0,0,7)"
	lighting = "actual world + actual FPS light"
	for low in [false, true]:
		app.set_quality(low)
		app.player.teleport(Vector3(0, 0, 7))
		aim(false)
		for weapon in 2:
			await ready_weapon(weapon)
			await create_timer(.6).timeout
			await capture("silo-w%d-%s-hip" % [weapon, "low" if low else "normal"])

func film() -> void:
	for weapon in 2:
		for condition in ["cold", "red", "dim"]:
			await setup(weapon, condition)
			app.state.ammo = 8
			app.state.reserve = 48
			app.state.energy = 40.0
			app.state.cells = 2
			var name := "film-w%d-%s" % [weapon, condition]
			await capture(name + "-start")
			var segment := {"name":name, "lighting_state":light_state(), "before":observation(), "fixture_resources":{"ammo":8,"reserve":48,"energy":40,"cells":2}, "first_sample":frames.size()}
			var origin: Vector3 = app.player.global_position
			var yaw_min := INF
			var yaw_max := -INF
			var pitch_min := INF
			var pitch_max := -INF
			var max_displacement := 0.0
			var accepted := false
			for tick in 180:
				var fraction := float(tick) / 179.0
				app.player.rotation.y = deg_to_rad(-15.0 + 30.0 * fraction)
				app.player.camera.rotation.x = deg_to_rad(5.0 * sin(TAU * fraction))
				if tick == 20:
					accepted = app.player.reload_weapon() if weapon == 0 else app.player.request_cell()
					check(accepted, "R/B refused: " + name)
				if tick == 85: Input.action_press("right")
				if tick == 95: Input.action_release("right")
				if tick == 125: aim(true)
				stage = name + "-frame-%03d" % tick
				refresh_label()
				var drawn_before := Engine.get_frames_drawn()
				await process_frame
				await RenderingServer.frame_post_draw
				check(Engine.get_frames_drawn() > drawn_before, "film frame did not draw")
				var record := observation()
				record["segment"] = name
				frames.append(record)
				var rotation: Vector3 = app.player.camera.global_rotation
				yaw_min = minf(yaw_min, rotation.y)
				yaw_max = maxf(yaw_max, rotation.y)
				pitch_min = minf(pitch_min, rotation.x)
				pitch_max = maxf(pitch_max, rotation.x)
				max_displacement = maxf(max_displacement, app.player.global_position.distance_to(origin))
			await ready_weapon(weapon)
			check(yaw_max - yaw_min > deg_to_rad(28.0) and pitch_max - pitch_min > deg_to_rad(9.0), "static or insufficient camera motion: " + name)
			check(max_displacement >= .1 and max_displacement <= 3.0, "missing or excessive movement: " + name)
			check(app.player.aim_weight >= .99, "film ADS not settled: " + name)
			if weapon == 0: check(app.state.ammo == 12 and app.state.reserve == 44, "R transfer failed: " + name)
			else: check(is_equal_approx(app.state.energy, 100.0) and app.state.cells == 1, "B transfer failed: " + name)
			await capture(name + "-end")
			segment.merge({"accepted":accepted, "after":observation(), "last_sample_exclusive":frames.size(), "yaw_range":yaw_max-yaw_min, "pitch_range":pitch_max-pitch_min, "max_displacement":max_displacement})
			segments.append(segment)
	check(segments.size() == 6 and frames.size() == 1080, "film segment/frame quota failed")

func observation() -> Dictionary:
	var camera: Camera3D = app.player.camera
	check(camera.global_position.is_finite() and camera.global_rotation.is_finite() and app.player.global_position.is_finite(), "nonfinite transform")
	return {"stage":stage,"frame":Engine.get_frames_drawn(),"process_frame":Engine.get_process_frames(),"camera_position":vector(camera.global_position),"camera_rotation":vector(camera.global_rotation),"player_position":vector(app.player.global_position),"fov":camera.fov,"near":camera.near,"aim_weight":app.player.aim_weight,"weapon":app.player.weapon_index,"ready":app.player.reload_cycle.ready,"motion":app.player.reload_cycle.view.motion,"gesture":app.player.reload_cycle.view.gesture,"gesture_fraction":app.player.reload_cycle.view.fraction,"ammo":app.state.ammo,"reserve":app.state.reserve,"energy":app.state.energy,"cells":app.state.cells,"health":app.state.health,"low_quality":app.low_quality,"scaling_3d_scale":root.scaling_3d_scale}

func rig_transforms() -> Array[Dictionary]:
	var transforms: Array[Dictionary] = []
	for node: Node3D in app.player.rig.find_children("*", "Node3D", true, false):
		transforms.append({"path":str(node.get_path()),"position":vector(node.position),"rotation":vector(node.rotation),"scale":vector(node.scale),"visible":node.is_visible_in_tree()})
	return transforms

func light_state() -> Dictionary:
	var lights: Array[Dictionary] = []
	for light: Light3D in root.find_children("*", "Light3D", true, false):
		lights.append({"path":str(light.get_path()),"type":light.get_class(),"visible":light.is_visible_in_tree(),"position":vector(light.global_position),"rotation":vector(light.global_rotation),"scale":vector(light.global_basis.get_scale()),"color":serial(light.light_color),"energy":light.light_energy,"specular":light.light_specular,"mask":light.light_cull_mask,"shadow":light.shadow_enabled,"range":light.omni_range if light is OmniLight3D else null})
	var env: Environment = app.world.ambience.environment
	return {"location":location,"condition":lighting,"lights":lights,"environment":properties(env),"environment_restored":env == saved_environment}

func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func serial(value: Variant) -> Variant:
	if value == null or value is bool or value is int or value is String or value is StringName: return value
	if value is float: return value if is_finite(value) else str(value)
	if value is Vector2: return [value.x, value.y]
	if value is Vector3: return vector(value)
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Resource: return {"class":value.get_class(),"path":value.resource_path,"instance_id":value.get_instance_id()}
	return str(value)

func properties(resource: Resource) -> Dictionary:
	var result := {}
	for property in resource.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE: result[property.name] = serial(resource.get(property.name))
	return result

func inventory() -> Dictionary:
	var surfaces: Array[Dictionary] = []
	var materials := {}
	var textures := {}
	var estimated_rgba8 := 0
	for mesh: MeshInstance3D in app.player.rig.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material == null: continue
			var id := str(material.get_instance_id())
			surfaces.append({"mesh":str(mesh.get_path()),"surface":surface,"material_id":id,"visible":mesh.is_visible_in_tree(),"layers":mesh.layers})
			if materials.has(id): continue
			materials[id] = {"path":material.resource_path,"class":material.get_class(),"parameters":properties(material)}
			for property in material.get_property_list():
				if not property.usage & PROPERTY_USAGE_STORAGE: continue
				var texture: Variant = material.get(property.name)
				if not texture is Texture2D: continue
				var texture_id := str(texture.get_instance_id())
				if textures.has(texture_id): continue
				var image: Image = texture.get_image()
				var bytes := 0
				var width: int = texture.get_width()
				var height: int = texture.get_height()
				var w := width
				var h := height
				while true:
					bytes += w * h * 4
					if w == 1 and h == 1: break
					w = maxi(1, w >> 1)
					h = maxi(1, h >> 1)
				estimated_rgba8 += bytes
				textures[texture_id] = {"path":texture.resource_path,"width":width,"height":height,"format":image.get_format() if image != null else null,"mipmaps":image.has_mipmaps() if image != null else null,"mipmap_count":image.get_mipmap_count() if image != null else null,"image_data_bytes":image.get_data_size() if image != null else null,"estimated_rgba8_full_mips_bytes":bytes}
	return {"surfaces":surfaces,"materials":materials,"textures":textures,"material_count":materials.size(),"texture_count":textures.size(),"estimated_rgba8_full_mips_bytes":estimated_rgba8,"estimate_scope":"Conservative RGBA8 full mip chain per unique Texture2D; not measured VRAM; no FPS textures on baseline is valid.","engine_bytes":{"texture":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"buffer":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"video":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)},"engine_metric_scope":"Whole viewport renderer-reported counters; zero may mean unsupported, not proof of zero memory."}
