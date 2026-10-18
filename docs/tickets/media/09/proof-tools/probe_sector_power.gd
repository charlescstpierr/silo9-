extends SceneTree

var app: Node
var output := ""
var mode := "perf"
var ending := "mother"
var display := ":100"
var require_lighting := false
var lighting_available := false
var lighting_samples: Array[Dictionary] = []
var cost_windows: Array[Dictionary] = []
var circuits_requested: Dictionary = {"maintenance": true, "archives": true}
var waypoint_positions: Array[Array] = []
const LIGHT_IDS := ["ceiling_refuge", "ceiling_decontamination", "ceiling_maintenance", "ceiling_archives", "ceiling_core_entry", "ceiling_core_end", "reactor", "alarm_maintenance", "alarm_archives"]
var require_circuits := false
var circuits := false
var low := false
var stage := "warmup"
var measuring := false
var previous_usec := 0
var intervals: Array[float] = []
var stages: Array[String] = []
var failures: Array[String] = []
var commands: Array[Dictionary] = []
var events: Array[Dictionary] = []
var travelled := 0.0
var waypoints := 0
var shots := 0
var draw_max := 0
var node_max := 0
var resource_max := 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="): output = argument.trim_prefix("--proof-output=")
		if argument.begins_with("--probe-mode="): mode = argument.trim_prefix("--probe-mode=")
		if argument.begins_with("--ending="): ending = argument.trim_prefix("--ending=")
		if argument.begins_with("--display="): display = argument.trim_prefix("--display=")
		if argument == "--require-lighting": require_lighting = true
		if argument == "--require-circuits": require_circuits = true
		if argument == "--low": low = true
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	if not ok:
		failures.append(message)
		printerr("PROOF FAILURE: " + message)
	return ok

func run() -> void:
	check(DisplayServer.get_name().to_lower() == "x11", "X11 required")
	check(RenderingServer.get_current_rendering_method() == "gl_compatibility", "Compatibility required")
	check(RenderingServer.is_render_loop_enabled(), "render loop required")
	if not failures.is_empty():
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.endpoint = ""
	app.new_game()
	app.set_layout(false)
	app.set_quality(low)
	DisplayServer.window_move_to_foreground()
	circuits = app.state.has_method("circuit_on") and app.world.has_method("set_circuit")
	check(not require_circuits or circuits, "required circuit API absent")
	lighting_available = app.player.has_method("toggle_flashlight") and app.world.has_method("set_reduced_light_effects") and app.player.find_child("Flashlight", true, false) is SpotLight3D
	for id in LIGHT_IDS:
		lighting_available = lighting_available and app.world.find_child(id, true, false) is OmniLight3D
	check(not require_lighting or lighting_available, "required lighting API/nodes absent")
	if mode in ["lighting", "lighting-perf"]:
		# Inspected fixture, explicitly not a mission or native movement proof.
		app.player.set_process(false)
		app.player.set_physics_process(false)
		app.world.set_process(false)
		app.world.colossus_triggered = true
		for enemy in app.world.enemies: enemy.process_mode = Node.PROCESS_MODE_DISABLED
		for consumer in app.world.power_consumers.values(): consumer.set_process(false)
		app.state.phase = 1
		app.state.energy = 0
		app.state.changed.emit()
	if mode == "perf":
		for enemy in app.world.enemies:
			enemy.queue_free()
		app.world.enemies.clear()
		await process_frame
	await wait(2.0)
	if require_lighting and mode in ["mission", "capture"] and failures.is_empty(): await native_flashlight_on()
	var drawn_start := Engine.get_frames_drawn()
	measuring = true
	if failures.is_empty():
		if mode == "perf": await performance_route()
		elif mode in ["lighting", "lighting-perf"]: await lighting_route()
		else: await mission_route()
	measuring = false
	for action in ["forward", "sprint"]: Input.action_release(action)
	var drawn := Engine.get_frames_drawn() - drawn_start
	check(drawn > 0, "no frames drawn")
	if mode in ["perf", "mission", "capture"]: check(travelled >= 90.0 and waypoints >= 8, "route incomplete")
	var report := {
		"schema": 2, "waypoint_positions": waypoint_positions,
		"require_lighting": require_lighting, "lighting_available": lighting_available,
		"scene_inspection": mode in ["lighting", "lighting-perf"], "lighting_samples": lighting_samples, "cost_windows": cost_windows,
		"final_observation": observation("final"), "mode": mode, "low_quality": low, "expected_ending": ending, "ending": app.state.ending,
		"phase": app.state.phase, "health": app.state.health, "ammo": app.state.ammo, "reserve": app.state.reserve,
		"medkits": app.state.medkits, "shots": shots, "defeated": app.state.defeated,
		"circuits_available": circuits, "travelled_m": travelled, "waypoints_completed": waypoints,
		"frames_drawn": drawn, "frame_intervals_ms": intervals, "frame_stages": stages,
		"frame_p50_ms": percentile(.5), "frame_p95_ms": percentile(.95), "frame_p99_ms": percentile(.99),
		"draw_calls_max": draw_max, "nodes_max": node_max, "resources_max": resource_max,
		"commands": commands, "events": events, "failures": failures,
		"engine": Engine.get_version_info(), "display_driver": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(), "renderer": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y], "performance_valid": mode == "perf" and failures.is_empty(),
		"scenario": "controlled poses; actors frozen alive; phase1 fixture; zero energy; colossus suppressed; no native journey" if mode in ["lighting", "lighting-perf"] else "refuge -> maintenance -> archives -> refuge; enemies removed; no circuit switching" if mode == "perf" else "fresh mission with live combat and native E interactions",
		"limits": "Linux X11 only; no Windows or target GPU claim. Walking uses Input actions, yaw/camera scripted; E is native OS press/release. Perf is an isolated no-enemy bench, not full mission. Mission/capture timings include interactions and are not a comparative benchmark. Screenshots need visual review; they are not video. Dummy audio does not prove audible output. Mission/perf: no teleports after normal new_game spawn. Lighting modes: explicitly teleported scene inspection, frozen living actors, deterministic process advances, not a native journey. Lighting-perf measures only named isolated windows; global timing includes setup and is not comparative."
	}
	var file := FileAccess.open(output + "/journey.json", FileAccess.WRITE)
	if file == null:
		printerr("cannot write journey.json")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("SECTOR_PROOF mode=%s travelled=%.1f failures=%d" % [mode, travelled, failures.size()])
	app.queue_free()
	paused = false
	await process_frame
	quit(0 if failures.is_empty() else 1)

func performance_route() -> void:
	for point in [Vector3(0,0,-10), Vector3(0,0,-16), Vector3(0,0,-22), Vector3(0,0,-32), Vector3(0,0,-36), Vector3(0,0,-42), Vector3(0,0,-32), Vector3(0,0,-12), Vector3(0,0,7)]:
		stage = "walk_" + str(point.z)
		await walk_to(point)
		if not failures.is_empty(): return
		stage = "settle_" + str(point.z)
		await wait(.5)

func mission_route() -> void:
	await walk_to(Vector3(0,0,-2))
	await use_object("component_0", Vector3(-2.5,0,-3))
	await walk_to(Vector3(0,0,-7))
	await use_object("component_1", Vector3(3.3,0,-9))
	await walk_to(Vector3(0,0,-11))
	await use_object("component_2", Vector3(-5.3,0,-11))
	if not check(app.state.components == 3, "three gathered repair components"): return
	await walk_to(Vector3(0,0,-18))
	if circuits: await breaker_cycle("maintenance", Vector3(2,0,-16))
	await walk_to(Vector3(0,0,-18))
	if not check(app.state.phase == 0, "scan remains mandatory"): return
	app.player.activate_scan()
	await process_frame
	if not check(app.state.phase == 1, "scanner discovers relay"): return
	await use_object("relay", Vector3(5.2,0,-25))
	if not check(app.state.phase == 2 and app.state.components == 0, "relay repaired from collected resources"): return
	await walk_to(Vector3(0,0,-32))
	await walk_to(Vector3(0,0,-36))
	if circuits: await breaker_cycle("archives", Vector3(2,0,-36))
	await walk_to(Vector3(0,0,-42))
	await use_object("n7", Vector3(-5.2,0,-42))
	if not check(app.mode == "dialogue", "physical N7 dialogue opens"): return
	app.resume_game()
	await walk_to(Vector3(0,0,-45))
	await use_object("evidence", Vector3(4.2,0,-46))
	if not check(app.state.facts.has("surface_signal"), "physical archive read"): return
	await walk_to(Vector3(0,0,-56))
	if ending == "n7":
		await use_arc_lock()
		await walk_to(Vector3(0,0,-61))
	else:
		await walk_to(Vector3(3.6,0,-56))
		await walk_to(Vector3(3.6,0,-61))
	await walk_to(Vector3(0,0,-65))
	await use_object("core", Vector3(0,0,-69.5))
	if not check(app.state.phase == 3, "physical core extracted"): return
	await walk_to(Vector3(3.6,0,-61))
	await walk_to(Vector3(3.6,0,-56))
	await walk_to(Vector3(0,0,-53))
	await walk_to(Vector3(0,0,6))
	await use_object("ending", Vector3(0,0,6.7))
	if not check(app.mode == "ending", "physical lift return opens final choice"): return
	app._choose_ending(ending)
	await wait(.4)
	check(app.state.ending == ending and app.mode == "conclusion", "fresh mission reaches requested ending")
	await capture("conclusion_" + ending)

func use_arc_lock() -> void:
	var object: Node3D = app.world.objects["device"]
	app.player.equip(1)
	for tick in 600:
		if app.player.weapon_index == 1 and app.player.reload_cycle.ready: break
		await physics_frame
	aim(object.global_position + Vector3(0,.7,0))
	await wait(.1)
	check(app.player.fire(), "ARC fires from earned starting energy")
	await wait(.2)
	check(app.state.facts.has("arc_lock_disabled"), "ARC destroys mission lock")
	app.player.equip(0)

func breaker_cycle(circuit: String, approach: Vector3) -> void:
	for cycle in 3:
		await use_object("breaker_" + circuit, approach)
		if not failures.is_empty(): return
		await wait(.35)

func use_object(id: String, approach: Vector3) -> void:
	if not failures.is_empty(): return
	await walk_to(approach)
	if not failures.is_empty(): return
	if not check(app.world.objects.has(id), "object exists: " + id): return
	var object: Node3D = app.world.objects[id]
	aim(object.global_position + Vector3(0,.25 if id.begins_with("component") else .7,0))
	await wait(.3)
	var aimed: bool = app.player.aim_target() == object
	if not check(aimed, "aim ray reaches " + id): return
	var prompt_before: String = str(object.get_meta("prompt", ""))
	check(not app.prompt_label.text.is_empty(), "HUD prompt visible before " + id)
	var circuit := id.trim_prefix("breaker_")
	var breaker := id.begins_with("breaker_")
	var bit_before := false
	var revision_before := -1
	if breaker:
		bit_before = app.state.call("circuit_on", StringName(circuit))
		revision_before = int(app.state.get("power_revision"))
	stage = "interact_" + id
	await capture("before_%02d_%s" % [commands.size(), id])
	if breaker: await capture_consumers(circuit, "before_%02d" % commands.size())
	aim(object.global_position + Vector3(0,.25 if id.begins_with("component") else .7,0))
	await wait(.15)
	if not check(app.player.aim_target() == object, "aim immediately before native E: " + id): return
	var before := observation("before_" + id)
	var native_output: Array = []
	var native_code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/x11_input.py"), "key", "e", "--display", display, "--duration", "0.1"], native_output, true)
	await wait(.3)
	var changed := true
	var prompt_changed := true
	if breaker:
		changed = app.state.call("circuit_on", StringName(circuit)) != bit_before and int(app.state.get("power_revision")) == revision_before + 1
		prompt_changed = str(object.get_meta("prompt", "")) != prompt_before
		check(changed, "native E changes circuit and revision: " + circuit)
		check(prompt_changed, "breaker prompt changes: " + circuit)
	check(native_code == 0, "native E helper exit")
	commands.append({"id": id, "native": native_code == 0, "aim_valid": aimed, "changed": changed, "prompt_changed": prompt_changed, "prompt_before": prompt_before, "prompt_after": str(object.get_meta("prompt", "")), "bit_before": bit_before if breaker else null, "bit_after": app.state.call("circuit_on", StringName(circuit)) if breaker else null, "before": before, "after": observation("after_" + id), "native_output": native_output})
	await capture("after_%02d_%s" % [commands.size(), id])
	if breaker: await capture_consumers(circuit, "after_%02d" % commands.size())
	aim(object.global_position + Vector3(0,.25 if id.begins_with("component") else .7,0))

func capture_consumers(circuit: String, label: String) -> void:
	if mode != "capture": return
	for tick in 1800:
		var enemy := visible_enemy()
		if enemy == null: break
		if not check(app.state.health > 0, "survives consumer capture combat"): return
		if app.state.health < 55 and app.state.medkits > 0: app.state.heal()
		aim(enemy.global_position + Vector3(0,.35 if enemy.crawler else 1,0))
		if app.state.ammo == 0: app.player.reload_weapon()
		elif app.player.fire(): shots += 1
		await physics_frame
	if not check(visible_enemy() == null, "capture threat cleared with real combat"): return
	var maintenance := circuit == "maintenance"
	aim(Vector3(0,1.7,-14 if maintenance else -34))
	await wait(.15)
	await capture(label + "_" + circuit + "_sas")
	aim(Vector3(6.6,1.15,-17.7) if maintenance else Vector3(-6.6,1.15,-38.7))
	for frame in 3:
		await wait(.2)
		await capture(label + "_" + circuit + "_fan_" + str(frame))

func walk_to(destination: Vector3) -> void:
	if not failures.is_empty(): return
	app.resume_game()
	stage = "walk_" + str(destination)
	var reached := false
	for tick in 5400:
		var offset: Vector3 = destination - app.player.global_position
		offset.y = 0
		if offset.length() < .3:
			reached = true
			break
		if not check(app.state.health > 0, "player survives real combat"): break
		if mode != "perf" and app.state.health < 55 and app.state.medkits > 0:
			app.state.heal()
		var enemy: Node3D = visible_enemy() if mode != "perf" else null
		if enemy != null:
			Input.action_release("forward")
			Input.action_release("sprint")
			aim(enemy.global_position + Vector3(0,.35 if enemy.crawler else 1,0))
			if app.state.ammo == 0: app.player.reload_weapon()
			elif app.player.fire(): shots += 1
		else:
			app.player.rotation.y = atan2(-offset.x, -offset.z)
			app.player.camera.rotation.x = 0
			Input.action_press("forward")
			Input.action_press("sprint")
		var before: Vector3 = app.player.global_position
		await physics_frame
		travelled += app.player.global_position.distance_to(before)
	Input.action_release("forward")
	Input.action_release("sprint")
	if check(reached, "physical waypoint reached: " + str(destination)):
		waypoints += 1
		waypoint_positions.append([destination.x, destination.y, destination.z])
	for tick in 8: await physics_frame

func visible_enemy() -> Node3D:
	for enemy in app.world.enemies:
		if not is_instance_valid(enemy) or enemy.health <= 0 or enemy.global_position.distance_to(app.player.global_position) > 14: continue
		var point: Vector3 = enemy.global_position + Vector3(0,.35 if enemy.crawler else 1,0)
		var ray := PhysicsRayQueryParameters3D.create(app.player.camera.global_position, point, 1)
		if app.player.get_world_3d().direct_space_state.intersect_ray(ray).get("collider") == enemy: return enemy
	return null

func aim(point: Vector3) -> void:
	var offset: Vector3 = point - app.player.camera.global_position
	app.player.rotation.y = atan2(-offset.x, -offset.z)
	app.player.camera.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())

func observation(label: String) -> Dictionary:
	var consumers: Array[Dictionary] = []
	var materials: Dictionary = {}
	for node in app.world.find_children("*", "Node3D", true, false):
		if node is MeshInstance3D and node.mesh != null:
			for surface in node.mesh.get_surface_count():
				record_material(materials, node.get_active_material(surface))
		if node is MultiMeshInstance3D and node.multimesh != null and node.multimesh.mesh != null:
			for surface in node.multimesh.mesh.get_surface_count():
				record_material(materials, node.material_override if node.material_override != null else node.multimesh.mesh.surface_get_material(surface))
		var path := str(app.world.get_path_to(node))
		var lower := path.to_lower()
		if "fan" not in lower and "sas" not in lower and "alarm" not in lower and "breaker" not in lower: continue
		var row := {"path": path, "position": str(node.position), "rotation": str(node.rotation), "visible": node.is_visible_in_tree()}
		if node is CollisionShape3D: row["disabled"] = node.disabled
		if node is AudioStreamPlayer3D: row["playing"] = node.playing
		consumers.append(row)
	var lights: Array[Dictionary] = []
	for light in app.world.lights:
		lights.append({"id": str(light.name), "position": vec(light.global_position), "visible": light.is_visible_in_tree(), "energy": light.light_energy, "color": str(light.light_color), "shadow": light.shadow_enabled, "mask": light.light_cull_mask, "range": light.omni_range})
	var flashlight: Node = app.player.find_child("Flashlight", true, false)
	var flashlight_actual: Variant = null
	if flashlight is SpotLight3D:
		flashlight_actual = {"visible": flashlight.is_visible_in_tree(), "energy": flashlight.light_energy, "shadow": flashlight.shadow_enabled, "position": vec(flashlight.global_position), "mask": flashlight.light_cull_mask, "range": flashlight.spot_range}
	var living: Array[Dictionary] = []
	for enemy in app.world.enemies:
		if is_instance_valid(enemy) and enemy.health > 0: living.append({"name": str(enemy.name), "position": vec(enemy.global_position), "health": enemy.health, "visible": enemy.is_visible_in_tree()})
	var meshes: Array[Dictionary] = []
	for node in app.world.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null: continue
		var material_ids: Array[int] = []
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(surface)
			if material != null: material_ids.append(material.get_instance_id())
		meshes.append({"path": str(app.world.get_path_to(node)), "position": vec(node.global_position), "visible": node.is_visible_in_tree(), "material_ids": material_ids})
	var power: Dictionary = {}
	var alarms: Dictionary = {}
	for circuit in ["maintenance", "archives"]:
		alarms[circuit] = app.world.power_consumers[StringName(circuit)].alarm_remaining if circuits else null
		power[circuit] = app.state.call("circuit_on", StringName(circuit)) if circuits else null
	return {"energy": app.state.energy, "scale_3d": root.scaling_3d_scale, "camera_position": vec(app.player.camera.global_position), "camera_rotation": vec(app.player.camera.global_rotation), "fov": app.player.camera.fov, "flashlight": flashlight_actual, "live_enemies": living, "circuits": power, "alarms": alarms, "mesh_materials": meshes, "label": label, "usec": Time.get_ticks_usec(), "player": str(app.player.global_position), "phase": app.state.phase, "health": app.state.health, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "objects": Performance.get_monitor(Performance.OBJECT_COUNT), "resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "consumers": consumers, "lights": lights, "materials": materials}

func record_material(materials: Dictionary, material: Material) -> void:
	if material is BaseMaterial3D:
		materials[str(material.get_instance_id())] = {"emission_enabled": material.emission_enabled, "emission": str(material.emission), "emission_energy": material.emission_energy_multiplier, "albedo": str(material.albedo_color)}

func capture(label: String) -> void:
	if mode not in ["capture", "lighting"]: return
	await RenderingServer.frame_post_draw
	var code := root.get_texture().get_image().save_png(output + "/" + label + ".png")
	check(code == OK, "capture writes " + label)

func _process(_delta: float) -> bool:
	if measuring:
		var now := Time.get_ticks_usec()
		if previous_usec > 0:
			intervals.append(float(now - previous_usec) / 1000.0)
			stages.append(stage)
		previous_usec = now
		draw_max = maxi(draw_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		node_max = maxi(node_max, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		resource_max = maxi(resource_max, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
	return false

func percentile(fraction: float) -> float:
	var sorted := intervals.duplicate()
	sorted.sort()
	return sorted[mini(int(sorted.size() * fraction), sorted.size() - 1)] if not sorted.is_empty() else 0.0

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func vec(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func lighting_pose(zone: String) -> void:
	var poses := {
		"refuge": [Vector3(0,0,8), Vector3(0,2,-2)],
		"decontamination": [Vector3(0,0,0), Vector3(0,2,-11)],
		"maintenance": [Vector3(0,0,-16), Vector3(3,2,-26)],
		"archives": [Vector3(0,0,-36), Vector3(1,2,-46)],
		"core": [Vector3(0,0,-61), Vector3(0,2,-72)]
	}
	app.player.teleport(poses[zone][0])
	aim(poses[zone][1])

func inspect_lighting(zone: String, label: String, flashlight_requested: bool) -> void:
	var row := {"zone": zone, "label": label, "flashlight_requested": flashlight_requested, "circuits_requested": circuits_requested.duplicate(), "observation": observation(label), "png": label + ".png" if mode == "lighting" else ""}
	lighting_samples.append(row)
	await capture(label)

func fixture_flashlight(enabled: bool) -> void:
	if not lighting_available: return
	if bool(app.player.get("flashlight_on")) != enabled:
		check(bool(app.player.call("toggle_flashlight")), "fixture flashlight toggle accepted")

func advance_lighting(delta: float) -> void:
	for consumer in app.world.power_consumers.values(): consumer.call("_process", delta)
	app.world.call("_process", delta)

func fixture_circuit(circuit: StringName, enabled: bool) -> void:
	circuits_requested[str(circuit)] = enabled
	var outcome: int = app.world.call("set_circuit", circuit, enabled)
	var outcomes: Dictionary = app.world.get_script().get_script_constant_map()["PowerOutcome"]
	check(outcome in [outcomes["CHANGED"], outcomes["UNCHANGED"]], "fixture circuit command accepted: " + str(circuit))
	check(bool(app.state.call("circuit_on", circuit)) == enabled, "fixture circuit state matches: " + str(circuit))

func fixture_power(enabled: bool) -> void:
	for circuit in ["maintenance", "archives"]:
		fixture_circuit(StringName(circuit), enabled)
	advance_lighting(0.0)

func lighting_route() -> void:
	if mode == "lighting-perf":
		# Separate stationary cost experiment. No PNG, no mission timing mixed in.
		measuring = false
		for zone in ["core", "maintenance"]:
			lighting_pose(zone)
			fixture_power(true)
			if zone == "maintenance":
				advance_lighting(9.0)
				fixture_circuit(&"maintenance", false)
				advance_lighting(.2)
			for enabled in [false, true]:
				fixture_flashlight(enabled)
				var label: String = zone + ("_alarm" if zone == "maintenance" else "") + ("_on" if enabled else "_off")
				await wait(1.0)
				await inspect_lighting(zone, label, enabled)
				var first := intervals.size()
				var drawn := Engine.get_frames_drawn()
				previous_usec = 0
				draw_max = 0
				node_max = 0
				resource_max = 0
				stage = label
				measuring = true
				await wait(6.0)
				measuring = false
				cost_windows.append({"label": label, "frames_drawn": Engine.get_frames_drawn() - drawn, "intervals_ms": intervals.slice(first), "draw_calls_max": draw_max, "nodes_max": node_max, "resources_max": resource_max, "observation_after": observation(label + "_after"), "clock": "alarm/neon deliberately held; stationary isolated cost"})
		return
	for zone in ["refuge", "decontamination", "maintenance", "archives", "core"]:
		lighting_pose(zone)
		for powered in [true, false]:
			fixture_power(powered)
			advance_lighting(2.0) # Expire alarms for steady OFF comparison.
			for enabled in [false, true]:
				fixture_flashlight(enabled)
				await wait(.2)
				await inspect_lighting(zone, zone + ("_power_on" if powered else "_power_off") + ("_flash_on" if enabled else "_flash_off"), enabled)
	for entry in [["maintenance", "relay", Vector3(3.8,0,-23)], ["maintenance", "breaker_maintenance", Vector3(2,0,-16)], ["archives", "evidence", Vector3(3.2,0,-44)]]:
		fixture_power(false)
		advance_lighting(2.0)
		app.player.teleport(entry[2])
		var target: Node3D = app.world.objects[entry[1]]
		aim(target.global_position + Vector3(0,.7,0))
		for enabled in [false, true]:
			fixture_flashlight(enabled)
			await wait(.2)
			await inspect_lighting(entry[0], "critical_" + str(entry[1]) + ("_flash_on" if enabled else "_flash_off"), enabled)
	lighting_pose("maintenance")
	fixture_flashlight(false)
	fixture_power(true)
	# Six-second sequence through real World._process, no duplicate animation model.
	for step in 13:
		advance_lighting(.5)
		await inspect_lighting("maintenance", "neon_%02d" % step, false)
	if lighting_available: app.world.call("set_reduced_light_effects", true)
	for step in 3:
		advance_lighting(2.0)
		await inspect_lighting("maintenance", "reduced_%02d" % step, false)
	if lighting_available: app.world.call("set_reduced_light_effects", false)
	advance_lighting(9.0)
	fixture_circuit(&"maintenance", false)
	advance_lighting(.2)
	await inspect_lighting("maintenance", "alarm_active", false)
	advance_lighting(1.4)
	await inspect_lighting("maintenance", "alarm_expired", false)


func native_flashlight_on() -> void:
	var flashlight: SpotLight3D = app.player.find_child("Flashlight", true, false)
	var intent_before: bool = app.player.get("flashlight_on")
	var visible_before := flashlight.is_visible_in_tree()
	var native_output: Array = []
	var native_code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/x11_input.py"), "key", "f", "--display", display, "--duration", "0.1"], native_output, true)
	await wait(.3)
	var intent_after: bool = app.player.get("flashlight_on")
	var visible_after := flashlight.is_visible_in_tree()
	events.append({"id": "flashlight_native_f", "native_exit": native_code, "intent_before": intent_before, "intent_after": intent_after, "visible_before": visible_before, "visible_after": visible_after, "native_output": native_output, "observation": observation("native_f_after")})
	check(native_code == 0 and not intent_before and intent_after and not visible_before and visible_after, "native F enables real flashlight before mission")
