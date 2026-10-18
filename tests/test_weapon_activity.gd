extends SceneTree

var failures := 0

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

func run() -> void:
	var app: Node = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	await process_frame
	for elapsed in [.07, .18]:
		for modal in ["pause", "inventory"]:
			app.new_game()
			await process_frame
			app.player.teleport(Vector3(0, 0, 7))
			app.player.set_physics_process(false)
			app.state.ammo = 4
			app.state.energy = 40
			app.player.equip(1)
			app.player._advance_reload(elapsed)
			app.player._update_view(elapsed)
			check(not app.player.reload_cycle.ready, modal + " fixture is inside normal selection")
			if modal == "pause": app._input(key(KEY_ESCAPE))
			else: app.open_inventory()
			app.player.set_physics_process(true)
			var poses: Array[Transform3D] = []
			for node: Node3D in app.player.rig.find_children("*", "Node3D", true, false): poses.append(node.transform)
			var right: Transform3D = app.player.rig.skeleton.get_bone_global_pose(3)
			var left: Transform3D = app.player.rig.skeleton.get_bone_global_pose(20)
			await create_timer(.12, true).timeout
			var unchanged := true
			var index := 0
			for node: Node3D in app.player.rig.find_children("*", "Node3D", true, false):
				unchanged = unchanged and node.transform.is_equal_approx(poses[index])
				index += 1
			unchanged = unchanged and app.player.rig.skeleton.get_bone_global_pose(3).is_equal_approx(right) and app.player.rig.skeleton.get_bone_global_pose(20).is_equal_approx(left)
			check(paused and not app.player.active and unchanged, modal + " freezes every rig transform and both wrists")
			app.player.set_physics_process(false)
			app.resume_game()
			for tick in 100:
				app.player._advance_reload(.01)
				app.player._update_view(.01)
			check(app.player.reload_cycle.ready and app.state.ammo == 4 and app.state.energy == 40, modal + " resumes a safe exit without resource change")
		app.new_game()
		await process_frame
		app.player.teleport(Vector3(0, 0, 7))
		app.player.set_physics_process(false)
		app.state.ammo = 4
		app.state.reserve = 17
		app.state.energy = 40
		app.state.cells = 2
		app.player.equip(1)
		app.player._advance_reload(elapsed)
		app.player._update_view(elapsed)
		app._input(key(KEY_F5))
		var old_id: int = app.player.get_instance_id()
		app.state.ammo = 1
		app.state.energy = 2
		app._input(key(KEY_F9))
		app.player.set_physics_process(false)
		await process_frame
		check(app.player.get_instance_id() != old_id and app.player.reload_cycle.ready and app.player.weapon_index == 0 and app.player.rig.weapon_index == 0, "load during selection recreates ready D9")
		for tick in 100:
			app.player._advance_reload(.01)
			app.player._update_view(.01)
		check(app.state.ammo == 4 and app.state.reserve == 17 and app.state.energy == 40 and app.state.cells == 2, "load preserves accounts and cannot resume an old selection or cell intention")
	app.queue_free()
	paused = false
	await create_timer(.3, true).timeout
	print("WEAPON ACTIVITY FAILURES: ", failures)
	quit(1 if failures else 0)
