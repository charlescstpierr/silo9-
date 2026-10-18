extends SceneTree

class ShotTarget extends StaticBody3D:
	var hits := 0
	var damage := 0.0
	func receive_hit(amount: float, _stun: float) -> void:
		hits += 1
		damage += amount

var app: Node
var target: ShotTarget
var label: Label
var output := ""
var mode := "inspection"
var require_ads := false
var recording := false
var stage := "warmup"
var capture_label := ""
var overlay_location := "SILO réel"
var previous_usec := 0
var frame_ms: Array[float] = []
var frame_stages: Array[String] = []
var events: Array[Dictionary] = []
var lifecycle: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var transitions: Array[Dictionary] = []
var failures: Array[String] = []
var draw_max := 0
var node_max := 0
var resource_max := 0
var base_fov := 76.0
var target_distance := 3.0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="): output = argument.trim_prefix("--proof-output=")
		if argument.begins_with("--probe-mode="): mode = argument.trim_prefix("--probe-mode=")
		if argument == "--require-ads": require_ads = true
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var version := Engine.get_version_info()
	check(version.major == 4 and version.minor == 7 and version.patch == 2, "requires Godot4.7.2")
	check(DisplayServer.get_name().to_lower() == "x11", "requires X11")
	check(RenderingServer.get_current_rendering_method() == "gl_compatibility", "requires Compatibility")
	check(RenderingServer.get_current_rendering_driver_name() in ["opengl3", "opengl3_es", "opengl3_angle"], "requires OpenGL")
	check(not RenderingServer.get_video_adapter_name().strip_edges().is_empty(), "missing renderer")
	check(RenderingServer.is_render_loop_enabled(), "disabled render loop")
	if not failures.is_empty():
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_quality(false)
	for enemy in app.world.enemies:
		enemy.set_process(false)
		enemy.set_physics_process(false)
	check(not require_ads or app.player.has_method("configure_aim"), "candidate lacks configure_aim")
	if not failures.is_empty():
		quit(1)
		return
	app.player.configure_feedback(.5, 1.0, 2)
	configure(76.0)
	if mode == "inspection":
		var floor_body := StaticBody3D.new()
		root.add_child(floor_body)
		box(floor_body, Vector3(32, .2, 32), Color(.13, .17, .23))
		floor_body.position = Vector3(1000, -.1, -8)
		app.player.teleport(Vector3(1000, 0, 7))
		overlay_location = "Arène isolée"
	else:
		app.player.teleport(Vector3(0, 0, 7))
	target = ShotTarget.new()
	target.name = "Visible4cmDamageFixture"
	root.add_child(target)
	box(target, Vector3(.04, .04, .04), Color(1, .25, .05), true)
	label = Label.new()
	label.position = Vector2(24, 100)
	app.ui.add_child(label)
	await wait(1.0)
	await ready_weapon(0)
	await place_target(target_distance)
	await capture("renderer-warmup")
	await wait(.25)
	var start := Engine.get_frames_drawn()
	recording = true
	if mode == "inspection": await inspection()
	else: await journey()
	recording = false
	var end := Engine.get_frames_drawn()
	check(end > start, "no drawn frames")
	var quota := 18 if mode == "inspection" else 8
	var damage_quota := 603.0 if mode == "inspection" else 246.0
	check(events.size() == quota and target.hits == quota, "incorrect accepted-shot/hit quota")
	check(is_equal_approx(target.damage, damage_quota), "incorrect total damage")
	check(not frame_ms.is_empty(), "missing frame intervals")
	var result := {"schema":1, "mode":mode, "scenario":"SILO elevator: movement, 6D9+2ARC, R, B, switches, settle" if mode != "inspection" else "18 ADS shots: 2weapons x3FOV x3distance; hip and ADS renders", "engine_version":version, "godot":version.string, "display_driver":DisplayServer.get_name(), "rendering_method":RenderingServer.get_current_rendering_method(), "rendering_driver":RenderingServer.get_current_rendering_driver_name(), "renderer":RenderingServer.get_video_adapter_name(), "render_loop_enabled":RenderingServer.is_render_loop_enabled(), "resolution":"1280x720", "normal_quality":true, "base_fov":76 if mode != "inspection" else "60/76/100", "aim_api":app.player.has_method("configure_aim"), "frames_drawn_start":start, "frames_drawn_end":end, "warmup_capture":"renderer-warmup.png", "accepted_shots":events.size(), "target_hits":target.hits, "target_damage":target.damage, "events":events, "lifecycle":lifecycle, "captures":captures, "transitions":transitions, "frame_samples":frame_ms.size(), "frame_intervals_ms":frame_ms, "frame_stages":frame_stages, "frame_p50_ms":percentile(.5), "frame_p95_ms":percentile(.95), "draw_calls_max":draw_max, "nodes_max":node_max, "resources_max":resource_max, "failures":failures, "performance_valid":mode == "perf" and failures.is_empty(), "pixel_review":"pending manual review; projections/depth bounds are not a visual PASS", "limits":"Inspection matrix uses temporary proof bay at x1000; perf/film use actual SILO at(0,0,7), visible3m collider; software action inputs, not XTest/controller hardware. Film fixed30fps is not performance. Candidate zoom changes viewing volume versus baseline; no target GPU or Windows claim."}
	var file := FileAccess.open(output + "/journey.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("ADS_PROOF shots=", events.size(), " damage=", target.damage, " failures=", failures)
	for action in ["aim", "left", "right", "crouch"]: Input.action_release(action)
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func box(body: StaticBody3D, size: Vector3, color: Color, unshaded := false) -> void:
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = size
	shape.shape = cube
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if unshaded: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	body.add_child(mesh)

func refresh_label() -> void:
	if is_instance_valid(label):
		label.text = "ADS | " + (capture_label if not capture_label.is_empty() else stage) + "\n" + overlay_location + "; cible de preuve 4 cm; commandes logicielles"
		if mode == "film": label.text += "\nFilm moteur fixe 30 fps; pas une mesure de fluidité"

func _process(_delta: float) -> bool:
	refresh_label()
	if recording:
		var now := Time.get_ticks_usec()
		if previous_usec != 0:
			frame_ms.append(float(now - previous_usec) / 1000.0)
			frame_stages.append(stage)
		previous_usec = now
		draw_max = maxi(draw_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		node_max = maxi(node_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		resource_max = maxi(resource_max, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
		if mode == "film": transitions.append(observation(stage))
	return false

func percentile(fraction: float) -> float:
	var values := frame_ms.duplicate()
	values.sort()
	return values[mini(int(values.size() * fraction), values.size() - 1)] if not values.is_empty() else 0.0

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func aim(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func configure(fov: float) -> void:
	base_fov = fov
	if app.player.has_method("configure_aim"): app.player.call("configure_aim", fov, 1.25, .65)
	else: app.player.camera.fov = fov

func ready_weapon(index: int) -> void:
	if app.player.weapon_index != index: app.player.equip(index)
	for tick in 600:
		if app.player.weapon_index == index and app.player.reload_cycle.ready and app.player._shot_time <= 0.0: return
		await physics_frame
	check(false, "weapon never READY")

func place_target(distance: float) -> void:
	target.global_position = app.player.camera.global_position - app.player.camera.global_basis.z * distance
	await physics_frame
	await physics_frame

func observation(name: String) -> Dictionary:
	var player: Node = app.player
	var camera: Camera3D = player.camera
	var markers: Dictionary = {}
	var weapon: Node3D = player.rig._weapons[player.weapon_index]
	for key in ["SightRear", "SightFront"]:
		var marker := weapon.find_child(key, true, false) as Node3D
		if marker != null:
			var pixel := camera.unproject_position(marker.global_position)
			markers[key] = {"path":str(marker.get_path()), "world":vec3(marker.global_position), "pixel":[pixel.x, pixel.y], "depth":-camera.to_local(marker.global_position).z, "center_error_px":pixel.distance_to(Vector2(640, 360))}
	var pixel := camera.unproject_position(target.global_position)
	return {"label":name, "frame":Engine.get_process_frames(), "weapon":player.weapon_index, "fov":camera.fov, "near":camera.near, "markers":markers, "target_world":vec3(target.global_position), "target_pixel":[pixel.x, pixel.y], "camera_world":vec3(camera.global_position), "camera_rotation":vec3(camera.global_rotation)}

func vec3(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func shoot(name: String) -> void:
	stage = name
	var player: Node = app.player
	var ammo: int = app.state.ammo
	var energy: float = app.state.energy
	var hits := target.hits
	var damage := target.damage
	var spec: Resource = player._weapon()
	var origin: Vector3 = player.camera.global_position
	var endpoint: Vector3 = origin - player.camera.global_basis.z * spec.reach
	var accepted: bool = player.fire()
	check(accepted, "fire refused: " + name)
	if not accepted: return
	check(target.hits == hits + 1, "real ray missed visible fixture: " + name)
	check(is_equal_approx(target.damage - damage, spec.damage), "incorrect damage: " + name)
	check(app.state.ammo == ammo - (1 if player.weapon_index == 0 else 0), "incorrect ammo: " + name)
	check(is_equal_approx(energy - app.state.energy, spec.energy_cost), "incorrect energy: " + name)
	check(player._shot_query.from.is_equal_approx(origin) and player._shot_query.to.is_equal_approx(endpoint), "ray changed: " + name)
	var observed := observation(name)
	observed.merge({"ammo_before":ammo, "ammo_after":app.state.ammo, "energy_before":energy, "energy_after":app.state.energy, "damage":target.damage - damage, "ray_from":vec3(player._shot_query.from), "ray_to":vec3(player._shot_query.to), "impact":vec3(player._impact.global_position)})
	events.append(observed)

func capture(name: String) -> void:
	capture_label = name
	refresh_label()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	capture_label = ""
	check(not image.is_empty() and image.get_size() == Vector2i(1280, 720), "missing render: " + name)
	if image.is_empty(): return
	check(image.save_png(output + "/" + name + ".png") == OK, "cannot save render")
	var observed := observation(name)
	observed["file"] = name + ".png"
	var bounds: Array[Dictionary] = []
	for mesh: MeshInstance3D in app.player.rig.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree() or mesh.mesh == null: continue
		var minimum := INF
		var maximum := -INF
		var aabb := mesh.get_aabb()
		for i in 8:
			var depth: float = -app.player.camera.to_local(mesh.to_global(aabb.get_endpoint(i))).z
			minimum = minf(minimum, depth)
			maximum = maxf(maximum, depth)
		bounds.append({"path":str(mesh.get_path()), "bounds_depth_min":minimum, "bounds_depth_max":maximum})
	observed["mesh_bounds"] = bounds
	observed["depth_limit"] = "AABB bounds include invisible arm extensions; review actual pixels, no general anti-clipping guarantee"
	captures.append(observed)

func inspection() -> void:
	for weapon in 2:
		for fov in [60.0, 76.0, 100.0]:
			for distance in [3.0, 10.0, 20.0]:
				aim(false)
				await ready_weapon(weapon)
				app.state.ammo = 12
				app.state.energy = 100.0
				configure(fov)
				await wait(.5)
				await place_target(distance)
				var name := "w%d-fov%d-%dm" % [weapon, int(fov), int(distance)]
				stage = name + "-hip"
				await capture(stage)
				aim(true)
				await wait(.7)
				stage = name + "-ads"
				var aligned := observation(stage)
				if require_ads:
					check(aligned.markers.size() == 2, "candidate missing sight geometry references")
					for marker: Dictionary in aligned.markers.values():
						check(marker.center_error_px <= 1.0 and marker.depth >= app.player.camera.near + .02, "sight outside center/near margin: " + stage)
					var expected := rad_to_deg(2.0 * atan(tan(deg_to_rad(fov) * .5) / 1.25))
					check(absf(app.player.camera.fov - expected) <= .01, "wrong settled ADS FOV")
				await capture(stage)
				shoot(name)
				await wait(.6)
	configure(76.0)
	Input.action_press("crouch")
	await wait(.6)
	await place_target(3.0)
	await capture("ads-crouch")
	Input.action_release("crouch")
	Input.action_press("right")
	await wait(.25)
	await capture("ads-walking")
	Input.action_release("right")
	await wait(.5)
	var wall := StaticBody3D.new()
	root.add_child(wall)
	box(wall, Vector3(2, 2, .1), Color(.32, .23, .19), true)
	wall.global_position = app.player.camera.global_position - app.player.camera.global_basis.z * .3
	await capture("wall-frontal-30cm-intersection-observation")
	wall.rotation.y = .6
	await capture("wall-oblique-30cm-intersection-observation")
	wall.queue_free()
	aim(false)
	app.player.teleport(Vector3(0, 0, 7))
	overlay_location = "SILO réel"
	await wait(.6)
	for weapon in 2:
		await ready_weapon(weapon)
		await place_target(3.0)
		await capture("silo-w%d-hip" % weapon)
		aim(true)
		await wait(.6)
		await capture("silo-w%d-ads" % weapon)
		aim(false)
		await wait(.3)

func journey() -> void:
	stage = "hip-still"
	await wait(.4)
	shoot("d9-hip")
	await wait(.45)
	stage = "walk-right-hip"
	var walk_start: Vector3 = app.player.global_position
	var walk_direction: Vector3 = app.player.global_basis.x
	walk_direction.y = 0.0
	walk_direction = walk_direction.normalized()
	Input.action_press("right")
	await wait(.25)
	Input.action_release("right")
	await wait(.3)
	var walk_end: Vector3 = app.player.global_position
	var horizontal := Vector3(walk_end.x - walk_start.x, 0.0, walk_end.z - walk_start.z)
	var distance := horizontal.length()
	var forward := horizontal.dot(walk_direction)
	lifecycle.append({"kind":"walk-right", "start":vec3(walk_start), "end":vec3(walk_end), "direction":vec3(walk_direction), "horizontal_distance":distance, "forward_distance":forward})
	check(walk_start.is_finite() and walk_end.is_finite() and walk_direction.is_finite(), "nonfinite movement observation")
	check(walk_direction.is_equal_approx(Vector3.RIGHT), "unexpected right heading")
	check(distance >= .1 and distance <= 3.0 and forward >= .1 and forward >= distance * .9, "right movement absent or incorrect")
	await place_target(target_distance)
	stage = "enter-ADS"
	aim(true)
	await wait(.08)
	shoot("d9-during-entry")
	aim(false)
	stage = "release-during-recoil"
	await wait(.45)
	aim(true)
	stage = "enter-before-inversion"
	await wait(.08)
	aim(false)
	stage = "inversion"
	await wait(.04)
	aim(true)
	await wait(.08)
	shoot("d9-during-inversion")
	await wait(.65)
	shoot("d9-full-ADS")
	stage = "R-while-aim-held"
	var ammo_before: int = app.state.ammo
	var reserve_before: int = app.state.reserve
	check(app.player.reload_weapon(), "R refused")
	await ready_weapon(0)
	lifecycle.append({"kind":"reload", "ammo_before":ammo_before, "ammo_after":app.state.ammo, "reserve_before":reserve_before, "reserve_after":app.state.reserve})
	check(ammo_before == 8 and app.state.ammo == 12 and reserve_before == 48 and app.state.reserve == 44, "R transfer incomplete")
	await wait(.6)
	shoot("d9-after-R")
	await wait(.4)
	stage = "switch-ARC-held-ADS"
	await ready_weapon(1)
	await wait(.6)
	shoot("arc-ADS-1")
	await wait(.5)
	shoot("arc-ADS-2")
	await wait(.5)
	stage = "B-while-aim-held"
	var cells: int = app.state.cells
	var energy: float = app.state.energy
	check(app.player.request_cell(), "B refused")
	await ready_weapon(1)
	check(app.state.cells == cells - 1 and is_equal_approx(app.state.energy, minf(energy + 60.0, app.state.max_energy())), "B transfer incomplete")
	stage = "return-D9-held-ADS"
	await ready_weapon(0)
	await wait(.6)
	shoot("d9-final")
	aim(false)
	stage = "settled-hip"
	await wait(2.0)
	check(absf(app.player.camera.fov - 76.0) <= .01, "camera failed to return to base FOV")
