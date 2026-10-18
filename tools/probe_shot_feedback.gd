extends SceneTree

class ShotTarget extends StaticBody3D:
	var hits := 0
	var damage := 0.0
	func receive_hit(amount: float, _stun: float) -> void:
		hits += 1
		damage += amount

var app: Node
var target: ShotTarget
var output := ""
var mode := "inspection"
var budget := 2
var require_feedback := false
var recording := false
var stage := "warmup"
var previous_usec := 0
var frame_ms: Array[float] = []
var frame_stage: Array[String] = []
var events: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var snapshots: Array[Dictionary] = []
var draw_max := 0
var node_max := 0
var resource_max := 0
var failures: Array[String] = []
var pre_draw_count := 0
var post_draw_count := 0

func on_pre_draw() -> void:
	pre_draw_count += 1

func on_post_draw() -> void:
	post_draw_count += 1

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="): output = argument.trim_prefix("--proof-output=")
		if argument.begins_with("--probe-mode="): mode = argument.trim_prefix("--probe-mode=")
		if argument.begins_with("--budget="): budget = int(argument.trim_prefix("--budget="))
		if argument == "--require-feedback": require_feedback = true
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	var engine_version := Engine.get_version_info()
	check(engine_version.major == 4 and engine_version.minor == 7 and engine_version.patch == 2, "requires Godot 4.7.2")
	check(DisplayServer.get_name().to_lower() == "x11", "requires X11 display driver")
	check(RenderingServer.get_current_rendering_method() == "gl_compatibility", "requires Compatibility rendering")
	check(RenderingServer.get_current_rendering_driver_name() in ["opengl3", "opengl3_es", "opengl3_angle"], "requires OpenGL rendering driver")
	check(not RenderingServer.get_video_adapter_name().strip_edges().is_empty(), "renderer adapter is empty")
	check(RenderingServer.is_render_loop_enabled(), "render loop is disabled")
	if not failures.is_empty():
		quit(1)
		return
	RenderingServer.frame_pre_draw.connect(on_pre_draw)
	RenderingServer.frame_post_draw.connect(on_post_draw)
	root.size = Vector2i(1280, 720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_quality(false)
	for enemy in app.world.enemies: enemy.set_physics_process(false)
	app.player.teleport(Vector3(0, 0, 7))
	target = ShotTarget.new()
	target.name = "ProofDamageFixture"
	target.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 2, .1)
	shape.shape = box
	target.add_child(shape)
	root.add_child(target)
	target.global_position = Vector3(0, 1.5, 4)
	var label := Label.new()
	label.position = Vector2(24, 100)
	label.text = "Retour de tir | cible de preuve invisible à 3 m\n" + ("Film déterministe 30 images/s, pas une mesure de fluidité" if mode == "film" else "Observation du vrai Player.fire()")
	app.ui.add_child(label)
	check(not require_feedback or app.player.has_method("configure_feedback"), "candidate lacks configure_feedback")
	configure(.5, 1.0, budget)
	await wait(1.0)
	await ready_weapon(0)
	await capture("renderer-warmup")
	await wait(.25)
	if not failures.is_empty():
		quit(1)
		return
	if mode == "inspection": await capture("rest-fps")
	snapshots.append(snapshot("warm"))
	var frames_drawn_start := Engine.get_frames_drawn()
	recording = true
	previous_usec = 0
	await journey()
	recording = false
	var frames_drawn_end := Engine.get_frames_drawn()
	check(frames_drawn_end > frames_drawn_start, "no rendered frames during journey")
	snapshots.append(snapshot("settled"))
	if mode == "inspection" and app.player.has_method("configure_feedback"):
		await inspect_profiles()
	check(events.size() == (12 if mode == "inspection" and app.player.has_method("configure_feedback") else (10 if mode == "film" else 9)), "unexpected accepted shot count")
	check(target.hits == events.size(), "damage fixture did not receive one hit per accepted shot")
	check(not frame_ms.is_empty(), "no full-frame samples")
	var raw_frames := frame_ms.duplicate()
	frame_ms.sort()
	var result := {"schema":1, "mode":mode, "budget":budget, "feedback_api":app.player.has_method("configure_feedback"), "resolution":"1280x720", "normal_quality":true, "renderer":RenderingServer.get_video_adapter_name(), "godot":Engine.get_version_info().string, "target":"invisible StaticBody3D fixture at (0,1.5,4), receive_hit records real hitscan", "scenario":"stationary, D9 x4, real R reload, ARC x4, switch D9 x1, settle", "accepted_shots":events.size(), "target_hits":target.hits, "target_damage":target.damage, "events":events, "captures":captures, "snapshots":snapshots, "frame_samples":frame_ms.size(), "frame_intervals_ms":raw_frames, "frame_stages":frame_stage, "frame_p50_ms":percentile(.5), "frame_p95_ms":percentile(.95), "draw_calls_max":draw_max, "nodes_max":node_max, "resources_max":resource_max, "failures":failures, "performance_valid":mode == "perf" and failures.is_empty(), "limits":"Renderer-local comparison only. No GPU target, Fortnite or Windows claim. UI input and pool collision/cycle assertions belong to dedicated tests."}
	result.merge({"engine_version":engine_version, "display_driver":DisplayServer.get_name(), "rendering_method":RenderingServer.get_current_rendering_method(), "rendering_driver":RenderingServer.get_current_rendering_driver_name(), "frames_drawn_start":frames_drawn_start, "frames_drawn_end":frames_drawn_end, "warmup_capture":"renderer-warmup.png", "pixel_review":"pending manual review of renderer warmup, per-weapon rest and first-draw PNGs; visibility and color counts do not establish flash readability", "film_supplement":"one additional D9 shot immediately followed by B and full cell return" if mode == "film" else "none"})
	var file := FileAccess.open(output + "/journey.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("SHOT_PROOF ", JSON.stringify(result))
	app.queue_free()
	target.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _process(_delta: float) -> bool:
	if recording:
		var now := Time.get_ticks_usec()
		if previous_usec != 0:
			frame_ms.append(float(now - previous_usec) / 1000.0)
			frame_stage.append(stage)
		previous_usec = now
		draw_max = maxi(draw_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		node_max = maxi(node_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		resource_max = maxi(resource_max, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
	return false

func percentile(fraction: float) -> float:
	return frame_ms[mini(int(frame_ms.size() * fraction), frame_ms.size() - 1)] if not frame_ms.is_empty() else 0.0

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func configure(camera_strength: float, light_strength: float, value: int) -> void:
	if app.player.has_method("configure_feedback"):
		app.player.call("configure_feedback", camera_strength, light_strength, value)

func ready_weapon(index: int) -> void:
	app.player.equip(index)
	for tick in 600:
		if app.player.weapon_index == index and app.player.reload_cycle.ready and app.player._shot_time <= 0.0: return
		await physics_frame
	check(false, "selection/reload never reached READY")

func shoot(label: String) -> void:
	stage = label
	var player: Node = app.player
	var ammo: int = app.state.ammo
	var energy: float = app.state.energy
	var hits := target.hits
	var damage := target.damage
	var spec: Resource = player._weapon()
	var origin: Vector3 = player.camera.global_position
	var endpoint: Vector3 = origin - player.camera.global_basis.z * spec.reach
	var accepted: bool = player.fire()
	check(accepted, "real fire refused: " + label)
	if not accepted: return
	check(target.hits == hits + 1, "real ray missed fixture: " + label)
	check(is_equal_approx(target.damage - damage, spec.damage), "wrong real damage: " + label)
	check(app.state.ammo == ammo - (1 if player.weapon_index == 0 else 0), "wrong ammo debit: " + label)
	check(is_equal_approx(energy - app.state.energy, spec.energy_cost), "wrong energy debit: " + label)
	check(player._shot_query.from.is_equal_approx(origin) and player._shot_query.to.is_equal_approx(endpoint), "shot altered aim ray: " + label)
	events.append({"label":label, "weapon":player.weapon_index, "frame":Engine.get_process_frames(), "physics_frame":Engine.get_physics_frames(), "ammo_before":ammo, "ammo_after":app.state.ammo, "energy_before":energy, "energy_after":app.state.energy, "damage":target.damage - damage, "ray_from":str(player._shot_query.from), "ray_to":str(player._shot_query.to), "fov":player.camera.fov})

func journey() -> void:
	for index in 4:
		shoot("d9-%d" % index)
		if index == 0 and mode == "inspection": await delayed_first_draw("d9-first-draw")
		if index < 3: await wait(app.player._weapon().cooldown + .08)
	stage = "d9-shot-then-R"
	check(app.player.reload_weapon(), "D9 reload refused")
	await ready_weapon(0)
	await ready_weapon(1)
	if mode == "inspection": await capture("rest-arc-fps")
	for index in 4:
		shoot("arc-%d" % index)
		if index == 0 and mode == "inspection": await delayed_first_draw("arc-first-draw")
		if index < 3: await wait(app.player._weapon().cooldown + .08)
	stage = "switch-d9"
	await ready_weapon(0)
	shoot("d9-final")
	if mode == "inspection":
		snapshots.append(snapshot("d9-final-live"))
		await wait(.6)
		var pool: Node = app.player.get("_casings")
		if pool != null:
			for mesh in pool.find_children("*", "MeshInstance3D", true, false):
				if not mesh.is_visible_in_tree(): continue
				var camera_pose: Transform3D = app.player.camera.global_transform
				var simulation: bool = pool.is_physics_processing()
				pool.set_physics_process(false)
				app.player.rig.visible = false
				app.player.camera.global_position = mesh.global_position + Vector3(.04, .04, .14)
				app.player.camera.look_at(mesh.global_position, Vector3.UP)
				await capture("casing-secondary-whole")
				app.player.camera.global_transform = camera_pose
				app.player.rig.visible = true
				pool.set_physics_process(simulation)
				break
	stage = "settle"
	await wait(3.0)
	if mode == "film":
		shoot("d9-shot-then-B")
		var cells: int = app.state.cells
		var energy: float = app.state.energy
		check(app.player.request_cell(), "B after D9 shot refused")
		stage = "B-cell-transfer-and-return"
		await wait(4.2)
		check(app.state.cells == cells - 1 and app.state.energy == minf(energy + 60.0, app.state.max_energy()), "B did not complete its real transfer")
		check(app.player.weapon_index == 0 and app.player.reload_cycle.ready, "B did not return to D9 READY")

func delayed_first_draw(label: String) -> void:
	var disabled_start := snapshot(label + "-disable-start")
	snapshots.append(disabled_start)
	RenderingServer.set_render_loop_enabled(false)
	var start := Time.get_ticks_usec()
	var tick := Engine.get_physics_frames()
	for index in 18: await physics_frame
	var before := snapshot(label + "-before-render")
	before["physics_ticks_without_render"] = Engine.get_physics_frames() - tick
	before["wall_delay_ms"] = float(Time.get_ticks_usec() - start) / 1000.0
	snapshots.append(before)
	check(before["pre_draw_count"] == disabled_start["pre_draw_count"] and before["post_draw_count"] == disabled_start["post_draw_count"], "draw callbacks advanced while rendering disabled: " + label)
	RenderingServer.set_render_loop_enabled(true)
	await capture(label)
	check(pre_draw_count == disabled_start["pre_draw_count"] + 1 and post_draw_count == disabled_start["post_draw_count"] + 1, "capture was not the first draw after reenabling rendering: " + label)
	if require_feedback:
		check(not departures().is_empty(), "departure absent on first draw after delayed ticks: " + label)

func departures() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for node: Node in app.player.rig.muzzle.find_children("*", "MeshInstance3D", true, false):
		if node.is_visible_in_tree():
			visible.append({"path":str(node.get_path()), "mesh_class":node.mesh.get_class() if node.mesh != null else "none", "mesh_id":node.mesh.get_instance_id() if node.mesh != null else 0})
	return visible

func snapshot(label: String) -> Dictionary:
	var meshes: Array[Dictionary] = []
	var pending: Array[Node] = [app]
	var pools: Array[Dictionary] = []
	var casing_nodes: Array[Node] = []
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		var script: Script = node.get_script()
		if script != null and script.resource_path.ends_with("/casing_pool.gd"):
			pools.append({"path":str(node.get_path()), "physics_processing":node.is_physics_processing(), "children":node.get_child_count()})
			casing_nodes.append_array(node.find_children("*", "MeshInstance3D", true, false))
		if node is MeshInstance3D and (node in casing_nodes or "casing" in str(node.get_path()).to_lower()):
			meshes.append({"path":str(node.get_path()), "visible":node.is_visible_in_tree(), "position":str(node.global_position), "mesh_id":node.mesh.get_instance_id() if node.mesh != null else 0})
	var lights: Array[Dictionary] = []
	for node: Node in app.player.rig.muzzle.find_children("*", "OmniLight3D", true, false):
		lights.append({"path":str(node.get_path()), "visible":node.is_visible_in_tree(), "energy":node.light_energy, "shadows":node.shadow_enabled, "range":node.omni_range})
	return {"label":label, "frame":Engine.get_process_frames(), "frames_drawn":Engine.get_frames_drawn(), "pre_draw_count":pre_draw_count, "post_draw_count":post_draw_count, "fov":app.player.camera.fov, "departures":departures(), "beam_visible":app.player._beam.is_visible_in_tree(), "lights":lights, "draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), "pools":pools, "casing_meshes":meshes}

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(not image.is_empty() and image.get_size() == Vector2i(1280, 720), "missing 1280x720 rendered image: " + label)
	if image.is_empty(): return
	var filename := label + ".png"
	check(image.save_png(output + "/" + filename) == OK, "cannot write " + filename)
	var pixel: Vector2 = app.player.camera.unproject_position(app.player.rig.muzzle.global_position)
	var orange := 0
	var cyan := 0
	for y in range(maxi(0, int(pixel.y) - 35), mini(image.get_height(), int(pixel.y) + 36)):
		for x in range(maxi(0, int(pixel.x) - 35), mini(image.get_width(), int(pixel.x) + 36)):
			var color := image.get_pixel(x, y)
			if color.r > .5 and color.r > color.g * 1.2 and color.g > color.b * 1.2: orange += 1
			if color.g > .45 and color.b > .45 and color.r < color.g * .7: cyan += 1
	var observed := snapshot(label)
	observed.merge({"file":filename, "view":"secondary close-up: camera at casing +(.04,.04,.14)m, rig hidden, casing simulation frozen for capture" if label == "casing-secondary-whole" else "unchanged FPS camera", "muzzle_pixel":str(pixel), "orange_pixels_71px_roi":orange, "cyan_pixels_71px_roi":cyan, "pixel_limit":"color counts include scenery and permanent weapon emitters; review the PNG and rest image"})
	captures.append(observed)

func inspect_profiles() -> void:
	await ready_weapon(0)
	for value in 3:
		configure(0.0 if value == 0 else 1.0, 0.0 if value == 0 else 1.0, value)
		shoot("profile-%d" % value)
		await capture("profile-%d-fps" % value)
		await wait(.4)
	configure(.5, 1.0, budget)
