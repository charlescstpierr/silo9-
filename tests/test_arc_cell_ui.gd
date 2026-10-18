extends SceneTree

var failures := 0
var app: Node
var saw_arc := false

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func reset(weapon: int = 0, energy: float = 10.0, cells: int = 3) -> void:
	app.new_game()
	app.player.set_physics_process(false)
	await process_frame
	app.player.teleport(Vector3(0, 0, 7))
	app.state.energy = energy
	app.state.cells = cells
	app.player.equip(weapon)
	saw_arc = weapon == 1
	step(.016)

func step(delta: float) -> void:
	app.player.position = Vector3(0, 0, 7)
	app.player.velocity = Vector3.ZERO
	var health: float = app.state.health
	app.player._physics_process(delta)
	if app.state.health != health: check(false, "real world floor preserves health during manual ticks")
	saw_arc = saw_arc or app.player.weapon_index == 1

func finish() -> void:
	for tick in 160: step(.05)

func transfer() -> bool:
	var cells: int = app.state.cells
	for tick in 800:
		step(.01)
		if app.state.cells < cells: return true
	return false

func cell_button() -> Button:
	for child in app.content.get_children():
		if child is Button and child.text.contains("cellule"): return child
	return null

func request(route: String) -> void:
	if route != "field": app.open_inventory()
	if route == "button":
		var button := cell_button()
		check(button != null, "inventory exposes its real cell button")
		if button != null: button.pressed.emit()
	else: app._input(key(KEY_B))

func run() -> void:
	app = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	await process_frame
	for route in ["field", "inventory", "button"]:
		for weapon in [0, 1]:
			await reset(weapon)
			request(route)
			check(app.state.energy == 10.0 and app.state.cells == 3, route + " B never consumes on request")
			check(app.mode == "playing" and not paused and app.player.active, route + " accepted cell resumes live play synchronously")
			check(not app.notice_label.text.contains("Batterie rechargée"), route + " cannot announce success before transfer")
			app.player._shot_time = 0.0
			check(not app.player.fire() and app.state.ammo == 12 and app.state.energy == 10.0, route + " blocks firing through approach and manipulation")
			for repeat in 5: app._input(key(KEY_B))
			check(not app.player.reload_weapon(), route + " refuses R while cell service is active")
			finish()
			check(app.state.energy == 70.0 and app.state.cells == 2, route + " repeated B has no queue or instant bypass")
			check(saw_arc, route + " from D9 visibly passes through ARC")
			check(app.player.weapon_index == weapon and app.player.rig.weapon_index == weapon, route + " returns to original weapon after transfer")
	for route in ["inventory", "button"]:
		for reason in ["full", "empty", "dead"]:
			await reset()
			match reason:
				"full": app.state.energy = 100.0
				"empty": app.state.cells = 0
				"dead": app.state.health = 0.0
			var before := Vector2(app.state.energy, app.state.cells)
			request(route)
			check(app.mode == "inventory" and paused and not app.player.active, route + " " + reason + " refusal keeps inventory open in same turn")
			check(Vector2(app.state.energy, app.state.cells) == before, route + " " + reason + " refusal preserves resources")
	await reset()
	app.open_inventory()
	var button := cell_button()
	check(button != null and button.text.contains("reprend le jeu"), "inventory button announces resumption")
	var panel_text := ""
	for child in app.content.get_children():
		if child is Label or child is Button or child is RichTextLabel: panel_text += child.text
	check(panel_text.contains("ARC"), "inventory explains ARC passage when holding D9")
	for reason in ["inactive", "dead"]:
		await reset()
		if reason == "inactive": app.player.active = false
		else: app.state.health = 0.0
		app._input(key(KEY_B))
		check(app.state.energy == 10.0 and app.state.cells == 3, "field B validates current " + reason + " without an intervening tick")
		app.state.health = 100.0
		app.player.set_active(true)
		finish()
		check(app.state.energy == 10.0 and app.state.cells == 3, "refused " + reason + " cannot leave a ghost intention")
	await reset()
	app.state.ammo = 4
	app.state.reserve = 17
	check(app.player.reload_weapon(), "active D9 service starts")
	step(.5)
	app._input(key(KEY_B))
	finish()
	check(app.state.ammo == 12 and app.state.reserve == 9, "B during active D9 service cannot interrupt its reload")
	check(app.state.energy == 10.0 and app.state.cells == 3, "B during active D9 service is refused without queuing")
	await reset()
	request("field")
	app.player.equip(1)
	finish()
	check(app.player.weapon_index == 1 and app.player.rig.weapon_index == 1, "manual ARC choice defeats automatic D9 return")
	await reset()
	request("field")
	app.state.cells = 0
	finish()
	check(saw_arc and app.player.weapon_index == 0 and app.state.energy == 10.0, "late stock refusal safely returns from ARC to D9")
	for cancel in ["none", "modal", "manual", "manual_same", "teleport", "death"]:
		await reset()
		app.state.ammo = 4
		app.state.reserve = 17
		check(app.player.reload_weapon(), "D9 reload starts before inventory cancellation")
		step(.5)
		request("inventory")
		for repeat in 4: app._input(key(KEY_B))
		check(app.mode == "playing" and app.state.energy == 10.0 and app.state.cells == 3, "one B intention may wait for cancelled D9 exit without reserving")
		match cancel:
			"modal":
				app.open_inventory()
				app.resume_game()
			"manual": app.player.equip(1)
			"manual_same": app.player.equip(0)
			"teleport": app.player.teleport(Vector3(0, 0, 7))
			"death": app.player.apply_damage(100.0)
		finish()
		check(app.state.ammo == 4 and app.state.reserve == 17, "cancelled D9 never transfers rounds")
		check(app.state.energy == (70.0 if cancel == "none" else 10.0) and app.state.cells == (2 if cancel == "none" else 3), cancel + " bounds or clears deferred cell intention")
		if cancel == "none": check(saw_arc and app.player.weapon_index == 0, "deferred cell returns to original D9")
	await reset(1, 0.0, 0)
	app.world.interact(app.world.objects["recharge"])
	check(app.state.energy == 100.0 and app.state.cells == 0, "real refuge remains immediate and free without cells")
	check(app.player.activate_scan() and app.state.energy == 80.0, "free refuge restores scanner access")
	await reset(1, 40.0, 1)
	check(app.player.reload_weapon(), "refuge revalidation starts ARC service")
	step(.01)
	app.world.interact(app.world.objects["recharge"])
	finish()
	check(app.state.energy == 100.0 and app.state.cells == 1, "real refuge before latch prevents waste of a cell")
	for after_transfer in [false, true]:
		await reset(1, 10.0, 2)
		check(app.player.reload_weapon(), "pause/save scenario begins ARC service")
		if after_transfer: check(transfer(), "save after transfer reaches economic milestone")
		else: step(.01)
		var expected_energy := 70.0 if after_transfer else 10.0
		var expected_cells := 1 if after_transfer else 2
		app._input(key(KEY_F5))
		var previous_player: int = app.player.get_instance_id()
		app.state.energy = 2.0
		app.state.cells = 9
		app._input(key(KEY_F9))
		app.player.set_physics_process(false)
		await process_frame
		check(app.player.get_instance_id() != previous_player, "F9 replaces actual player")
		check(app.state.energy == expected_energy and app.state.cells == expected_cells, "F5/F9 restores counts on correct side of transfer")
		finish()
		check(app.state.energy == expected_energy and app.state.cells == expected_cells, "loaded player has no ghost operation")
		app.player.equip(1)
		app.player._shot_time = 0.0
		check(app.player.fire() == after_transfer, "loaded weapon readiness uses restored energy")
		await reset(1, 10.0, 2)
		check(app.player.reload_weapon(), "pause scenario begins ARC service")
		if after_transfer: check(transfer(), "pause after transfer reaches economic milestone")
		else: step(.01)
		app.player.set_physics_process(true)
		app._input(key(KEY_ESCAPE))
		var poses: Array[Transform3D] = []
		for node in app.player.rig.find_children("*", "Node3D", true, false): poses.append(node.transform)
		await create_timer(.15, true).timeout
		var index := 0
		var unchanged := true
		for node in app.player.rig.find_children("*", "Node3D", true, false):
			unchanged = unchanged and node.transform.is_equal_approx(poses[index])
			index += 1
		check(paused and unchanged, "pause freezes all actual rig transforms")
		check(app.state.energy == expected_energy and app.state.cells == expected_cells, "pause cannot transfer resources")
		app.player.set_physics_process(false)
		app._input(key(KEY_ESCAPE))
		finish()
		check(app.state.energy == expected_energy and app.state.cells == expected_cells, "resumed cancelled exit preserves only acquired transfer")
	await reset(1, 10.0, 1)
	var nodes := get_node_count()
	var meshes: Array[Mesh] = []
	for node in app.player.rig.find_children("*", "MeshInstance3D", true, false): meshes.append(node.mesh)
	var all_completed := true
	for cycle in 100:
		app.state.energy = 10.0
		app.state.cells = 1
		var accepted: bool = app.player.reload_weapon()
		finish()
		all_completed = all_completed and accepted and app.state.energy == 70.0 and app.state.cells == 0
	check(all_completed, "100 full ARC cycles each consume exactly one cell")
	check(get_node_count() == nodes, "100 ARC cycles do not add nodes")
	var resources_reused := true
	var mesh_index := 0
	for node in app.player.rig.find_children("*", "MeshInstance3D", true, false):
		resources_reused = resources_reused and mesh_index < meshes.size() and node.mesh == meshes[mesh_index]
		mesh_index += 1
	check(resources_reused and mesh_index == meshes.size(), "100 ARC cycles reuse mesh resources")
	app.queue_free()
	paused = false
	await create_timer(.4, true).timeout
	print("ARC CELL UI FAILURES: ", failures)
	quit(1 if failures else 0)
