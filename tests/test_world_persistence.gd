extends "res://tests/persistence_fixture.gd"

func run() -> void:
	preserve_default_save()
	await crate_case()
	await robot_case("sentinel_1", Vector3(1.2, 0, -23.5), 0.73)
	await robot_case("crawler_1", Vector3(-2.2, 0, -29.5), -1.17)
	await arc_case()
	await gate_case()
	await invalid_load_case()
	await finish("WORLD PERSISTENCE")

func crate_panels() -> Array[MultiMeshInstance3D]:
	var result: Array[MultiMeshInstance3D] = []
	for mesh: MultiMeshInstance3D in app.world.find_children("*", "MultiMeshInstance3D", true, false):
		if mesh.is_visible_in_tree() and mesh.multimesh != null and mesh.multimesh.instance_count == 3 and mesh.global_position.distance_to(Vector3(4, 0, -12)) < 2:
			result.append(mesh)
	return result

func equip_ready(index: int) -> void:
	app.player.set_physics_process(true)
	app.player.equip(index)
	await create_timer(0.8).timeout
	app.player.set_physics_process(false)
	check(app.player.reload_cycle.ready and app.player.weapon_index == index, "fixture completes real weapon switch before firing")

func crate_case() -> void:
	print("CASE crate: actual hitscan, debris, collision, reconstruction")
	await start_app()
	var center := Vector3(4, 0.4, -12)
	var hit := ray(Vector3(4, 0.4, -10), Vector3(4, 0.4, -13))
	if check(not hit.is_empty() and hit.position.distance_to(center) < 1, "crate fixture ray hits the authored crate collider"):
		app.player.teleport(Vector3(4, 0, -10))
		app.player.camera.look_at(center)
		await equip_ready(1)
		app.player.camera.look_at(center)
		check(app.player.fire(), "real ARC shot is fired at crate")
		await create_timer(0.7).timeout
		check(not ray(Vector3(4, 0.4, -10), Vector3(4, 0.4, -13)).is_empty(), "ARC keeps crate intact and blocking")
		await equip_ready(0)
		app.player.camera.look_at(center)
		var camera_hit := ray(app.player.camera.global_position, center)
		check(not camera_hit.is_empty() and camera_hit.get("collider") == hit.get("collider"), "D9 camera ray targets the same authored crate collider")
		var before: int = app.state.ammo
		check(app.player.fire() and app.state.ammo == before - 1, "real D9 shot consumes a round against crate")
		if not camera_hit.is_empty():
			check(app.player._impact.global_position.distance_to(camera_hit.position) < 0.01, "D9 hitscan impact actually lands on targeted crate collider")
		await settle()
		check(ray(Vector3(4, 0.4, -10), Vector3(4, 0.4, -13)).is_empty(), "CRATE_RED ballistic hit removes blocking crate collider")
		check(crate_panels().size() == 1, "CRATE_RED ballistic hit leaves three visible static panels")
		check(app.state._snapshot().get("crate_broken", false), "CRATE_RED ballistic hit records broken crate in canonical snapshot")
		reload_app()
		await settle()
		check(ray(Vector3(4, 0.4, -10), Vector3(4, 0.4, -13)).is_empty() and crate_panels().size() == 1, "CRATE_RED restored crate has debris and no blocking collider")
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.32
		capsule.height = 1.8
		var sweep := PhysicsShapeQueryParameters3D.new()
		sweep.shape = capsule
		sweep.transform.origin = Vector3(4, 0.92, -10)
		sweep.motion = Vector3(0, 0, -3)
		sweep.collision_mask = 1
		check(app.world.get_world_3d().direct_space_state.cast_motion(sweep)[0] >= 0.999, "CRATE_RED player capsule traverses restored debris")
	await close_app()

func robot_case(id: String, death_position: Vector3, yaw: float) -> void:
	print("CASE robot: ", id, " moved pose and durable trace")
	await start_app()
	var victim: Node3D
	for enemy: Node3D in app.world.enemies:
		if enemy.enemy_id == id: victim = enemy
	if check(victim != null, "robot fixture finds authored " + id):
		victim.global_position = death_position
		victim.rotation.y = yaw
		await settle()
		var before := geometry_ids()
		var observations: Array[Dictionary] = []
		var capture := func() -> void: observations.append(app.state._snapshot().duplicate(true))
		app.state.changed.connect(capture)
		victim.receive_hit(1000.0, 0.0)
		app.state.changed.disconnect(capture)
		check(app.state.defeated.has(id), "robot damage records identified defeat")
		check(observations.size() == 1 and observations[0].get("death_poses", {}).has(id), "ROBOT_RED one changed notification exposes defeat and pose together")
		check(new_visible_geometry(before, death_position, 2).size() > 0, "ROBOT_RED death creates immediate static trace at moved position")
		await create_timer(2.6).timeout
		check(new_visible_geometry(before, death_position, 2).size() > 0, "ROBOT_RED trace survives old death animation lifetime")
		app.world.set_circuit(&"maintenance", false)
		check(app.world.set_circuit(&"maintenance", true) == app.world.PowerOutcome.CHANGED, "circuit commands remain usable after the defeated robot node is freed")
		var snapshot: Dictionary = app.state._snapshot()
		var pose: Dictionary = snapshot.get("death_poses", {}).get(id, {})
		check(pose.get("position", []) == [death_position.x, death_position.y, death_position.z] and is_equal_approx(float(pose.get("yaw", 99)), yaw), "ROBOT_RED snapshot records actual death position and yaw")
		reload_app()
		await settle()
		var revived := false
		for enemy: Node in app.world.find_children("*", "CharacterBody3D", true, false):
			if enemy is Enemy and enemy.enemy_id == id: revived = true
		check(not revived, "defeated robot is absent after reconstruction")
		var trace := trace_at(death_position, yaw)
		check(trace != null, "ROBOT_RED reconstruction restores visible trace at death pose")
		if trace != null:
			check(trace.find_children("*", "CollisionObject3D", true, false).is_empty() and trace.find_children("*", "Timer", true, false).is_empty() and trace.find_children("*", "Light3D", true, false).is_empty(), "trace has no collision, timers or lights")
			check(not trace.is_processing() and not trace.is_physics_processing(), "trace has no per-frame processing")
			var count: int = app.world.find_children("*", "GeometryInstance3D", true, false).size()
			for repeat in 20: app.world.refresh()
			check(app.world.find_children("*", "GeometryInstance3D", true, false).size() == count, "refresh does not duplicate trace geometry")
	await close_app()

func arc_case() -> void:
	print("CASE ARC: reconstructed device then second impact")
	await start_app()
	var first_events: Array[Dictionary] = []
	var capture := func() -> void: first_events.append(app.state._snapshot().duplicate(true))
	app.state.changed.connect(capture)
	app.world.objects["device"].receive_hit(10.0, 2.0)
	app.state.changed.disconnect(capture)
	check(app.state.facts.has("arc_lock_disabled"), "first ARC impact records canonical fact")
	check(first_events.size() == 1 and first_events[0].facts.has("arc_lock_disabled") and first_events[0].memory.has("Le verrou ARC a été désactivé."), "ARC_RED first disable notifies once with fact and memory committed")
	app.state.remember("A different event after disabling ARC.")
	reload_app()
	await settle()
	var device: Node = app.world.objects["device"]
	check(device.is_disabled, "ARC_RED reconstructed device is already disabled")
	check(device.get_meta("prompt", "") == "Verrou hors tension", "ARC_RED reconstructed device advertises inactive prompt")
	var emissive := false
	for mesh: MeshInstance3D in device.find_children("*", "MeshInstance3D", true, false):
		var material: Material = mesh.material_override
		if material is BaseMaterial3D and material.emission_enabled and material.emission_energy_multiplier > 0 and material.emission != Color.BLACK: emissive = true
	check(not emissive, "ARC_RED reconstructed lock is non-emissive")
	var events: Array[String] = []
	device.disabled.connect(func() -> void: events.append("disabled"))
	app.world.message.connect(func(_message: String) -> void: events.append("message"))
	app.state.changed.connect(func() -> void: events.append("changed"))
	var memory: Array = app.state.memory.duplicate()
	device.receive_hit(10.0, 2.0)
	check(events.is_empty(), "ARC_RED second impact emits no disabled, message or changed")
	check(app.state.memory == memory, "ARC_RED second impact does not append journal entry")
	check(not is_instance_valid(app.world.barrier), "restored disabled barrier has no remaining node")
	await close_app()

func gate_case() -> void:
	print("CASE gate: final pose synchronously after main.load_run")
	await start_app()
	check(app.state.discover_relay() and app.state.collect("gate-test-parts", "components", 3) and app.state.repair_relay(), "gate fixture reaches power through existing progression")
	check(app.world.reactor_gate.position.y < 4, "played gate opening remains animated")
	await create_timer(0.8).timeout
	check(is_equal_approx(app.world.reactor_gate.position.y, 4), "played gate reaches open pose")
	reload_app()
	check(is_equal_approx(app.world.reactor_gate.position.y, 4), "GATE_RED restored gate is open immediately before any frame or tween")
	for body: Node3D in app.world.reactor_gate.find_children("*", "StaticBody3D", true, false):
		check(body.global_position.y > 4, "GATE_RED restored gate collider is already above doorway")
	await settle()
	check(ray(Vector3(0, 1, -52), Vector3(0, 1, -56)).is_empty(), "GATE_RED restored doorway permits passage after physics synchronization")
	await close_app()

func invalid_load_case() -> void:
	print("CASE invalid load: active world retained")
	await start_app()
	var before: Dictionary = app.state._snapshot().duplicate(true)
	var old_player: int = app.player.get_instance_id()
	var old_world: int = app.world.get_instance_id()
	var invalid: Dictionary = before.duplicate(true)
	invalid["schema"] = 4
	invalid["crate_broken"] = false
	invalid["death_poses"] = {"sentinel_1": {"position": [0, 0, 0], "yaw": 0}}
	write_json("user://silo9-save.json", invalid)
	app.load_run()
	check(app.player.get_instance_id() == old_player and app.world.get_instance_id() == old_world and app.state._snapshot() == before, "invalid orphan pose leaves active state, Player and World unchanged")
	await close_app()
