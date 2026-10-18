extends SceneTree

var app: Node
var failures: int = 0
var travelled: float = 0.0
var start_simulation: float = 0.0
var shots: int = 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_layout(false)
	start_simulation = app.state.elapsed
	await walk_to(Vector3(0, 0, -2))
	await use_object("component_0", Vector3(-2.5, 0, -3))
	await walk_to(Vector3(0, 0, -7))
	await use_object("component_1", Vector3(3.3, 0, -9))
	await walk_to(Vector3(0, 0, -11))
	await use_object("component_2", Vector3(-5.3, 0, -11))
	check(app.state.components == 3, "Three physical loot interactions collect repair resources")
	await walk_to(Vector3(0, 0, -18))
	check(app.state.phase == 0, "Walking into maintenance alone does not discover relay")
	app.player.activate_scan()
	check(app.state.phase == 1, "Real player scanner reaches world and advances discovery")
	await use_object("relay", Vector3(5.2, 0, -25))
	check(app.state.phase == 2 and app.state.components == 0, "Raycast interaction repairs relay")
	await walk_to(Vector3(0, 0, -32))
	await walk_to(Vector3(0, 0, -42))
	await use_object("n7", Vector3(-5.2, 0, -42))
	check(app.mode == "dialogue", "N7 world interaction opens real dialogue UI")
	app.resume_game()
	await walk_to(Vector3(0, 0, -45))
	await use_object("evidence", Vector3(4.2, 0, -46))
	check(app.state.facts.has("surface_signal"), "Physical archive adds canonical evidence")
	await walk_to(Vector3(0, 0, -56))
	await walk_to(Vector3(3.6, 0, -56))
	await walk_to(Vector3(3.6, 0, -61))
	await walk_to(Vector3(0, 0, -65))
	await use_object("core", Vector3(0, 0, -69.5))
	check(app.state.phase == 3, "Physical bypass and core extraction succeed")
	await walk_to(Vector3(3.6, 0, -61))
	await walk_to(Vector3(3.6, 0, -56))
	await walk_to(Vector3(0, 0, -53))
	await walk_to(Vector3(0, 0, 6))
	app.state.player_position = app.player.global_position
	app.state.player_yaw = app.player.rotation.y
	check(app.state.save_game("user://journey-test.json") == OK, "Save real travelled mission before choice")
	await use_object("ending", Vector3(0, 0, 6.7))
	check(app.mode == "ending", "Returning to lift opens final choice")
	app._choose_ending("mother")
	check(app.state.ending == "mother" and app.mode == "conclusion", "Mother ending reaches conclusion UI")
	var mother_color: Color = app.world.lights[0].light_color
	var restored: RefCounted = load("res://scripts/run_state.gd").new()
	check(restored.load_game("user://journey-test.json") == OK, "Restore pre-choice gameplay state")
	app._start_run(restored)
	app.resume_game()
	await process_frame
	app.open_ending()
	app._choose_ending("n7")
	check(app.state.ending == "n7" and app.world.lights[0].light_color != mother_color, "N7 ending is visibly distinct")
	check(app.world.enemies.filter(func(e): return is_instance_valid(e) and e.health > 0).size() == 0, "Defeated enemies remain absent after load")
	print("JOURNEY: failures=%d travelled=%.1fm simulation=%.1fs shots=%d health=%.0f" % [failures, travelled, app.state.elapsed - start_simulation, shots, app.state.health])
	app.queue_free()
	paused = false
	await process_frame
	DirAccess.remove_absolute("user://journey-test.json")
	quit(1 if failures else 0)

func walk_to(destination: Vector3) -> void:
	app.resume_game()
	var limit: int = 5400
	while limit > 0:
		limit -= 1
		var offset: Vector3 = destination - app.player.global_position
		offset.y = 0
		if offset.length() < 0.3:
			break
		if app.state.health <= 0:
			check(false, "Journey player survives combat")
			return
		if app.state.health < 55:
			app.state.heal()
		var enemy: Node3D = visible_enemy()
		if enemy != null:
			Input.action_release("forward")
			Input.action_release("sprint")
			aim(enemy.global_position + Vector3(0, 0.35 if enemy.crawler else 1.0, 0))
			if app.state.ammo == 0:
				app.player.reload_weapon()
			elif app.player.fire():
				shots += 1
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
	check(limit > 0, "Physical path reaches " + str(destination))
	for i in 8:
		await physics_frame

func visible_enemy() -> Node3D:
	for enemy in app.world.enemies:
		if not is_instance_valid(enemy) or enemy.health <= 0 or enemy.global_position.distance_to(app.player.global_position) > 14:
			continue
		var target: Vector3 = enemy.global_position + Vector3(0, 0.35 if enemy.crawler else 1, 0)
		var ray := PhysicsRayQueryParameters3D.create(app.player.camera.global_position, target, 1)
		var hit: Dictionary = app.player.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.get("collider") == enemy:
			return enemy
	return null

func aim(point: Vector3) -> void:
	var offset: Vector3 = point - app.player.camera.global_position
	app.player.rotation.y = atan2(-offset.x, -offset.z)
	app.player.camera.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())

func use_object(id: String, approach: Vector3) -> void:
	await walk_to(approach)
	var object: Node3D = app.world.objects[id]
	aim(object.global_position + Vector3(0, 0.25 if id.begins_with("component") else 0.7, 0))
	for i in 15:
		await physics_frame
	check(app.player.aim_target() == object, "Aim ray reaches " + id)
	if app.player.aim_target() == object:
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		app.player._unhandled_input(event)
	await process_frame
