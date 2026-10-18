extends "res://tests/ads_fixture.gd"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: ADS captured mouse and draw acknowledgements")
		quit(2)
		return
	await prepare_ads()
	reset()
	configure_ads()
	aim(false)
	advance(.3)
	aim(true)
	tick(.05)
	var partial := player.camera.fov
	check(partial < 76 and partial > zoom_fov(76, 1.25), "ADS enters gradually on physical time")
	var pose := player.rig._weapons[0].global_transform
	for repeat in 20:
		tick(0)
		player._update_view(0)
		present(0)
	check(is_equal_approx(player.camera.fov, partial) and player.rig._weapons[0].global_transform.is_equal_approx(pose), "zero-delta physics/render/recompose do not advance ADS")
	aim(false)
	tick(.02)
	check(player.camera.fov > partial and player.camera.fov < 76, "mid-entry release reverses continuously")
	advance(.4)
	check(near_fov(76), "release returns exactly to current hip FOV")
	var nodes := get_node_count()
	var resources := mesh_resources()
	var settles := true
	for cycle in 50:
		aim(true)
		for delta in [.013, .047, .021, .109, .08, .04]: tick(delta)
		settles = settles and near_fov(zoom_fov(76, 1.25))
		aim(false)
		for delta in [.03, .007, .09, .06]: tick(delta)
		settles = settles and near_fov(76)
	check(settles, "50 irregular ADS cycles settle both endpoints without cumulative zoom")
	check(get_node_count() == nodes and mesh_resources() == resources, "50 cycles retain nodes, mesh resources and material resources")
	configurable_timing()
	await recoil_composition()
	motion_and_sensitivity()
	manipulations()
	lifecycle()
	release_inputs()
	await create_timer(.25).timeout
	await finish("ADS TRANSITIONS")

func mesh_resources() -> Dictionary:
	var result := {}
	for mesh: MeshInstance3D in player.find_children("*", "MeshInstance3D", true, false):
		result[mesh.get_instance_id()] = [mesh.mesh, mesh.get_active_material(0)]
	return result

func configurable_timing() -> void:
	reset()
	var spec := player._weapon()
	var duration: Variant = spec.get("aim_enter_seconds")
	check(duration is float and duration > 0, "weapon resource exposes a positive configurable ADS entry duration")
	if not duration is float:
		print("GUARDED: alternate timing behavior awaits weapon ADS duration")
		return
	if not configure_ads(): return
	aim(false)
	advance(.3)
	spec.set("aim_enter_seconds", .4)
	aim(true)
	advance(.2)
	check(near_fov((76 + zoom_fov(76, 1.25)) * .5), "changing resource entry duration changes actual half-time zoom")
	advance(.2)
	check(near_fov(zoom_fov(76, 1.25)), "changed entry duration reaches ADS at configured time")
	spec.set("aim_enter_seconds", duration)
	release_inputs()

func recoil_composition() -> void:
	reset()
	if not configure_ads():
		print("GUARDED: changing options during recoil awaits configure_aim")
		return
	aim(false)
	advance(.3)
	aim(true)
	tick(.08)
	var orientation := player.camera.global_basis
	check(player.fire(), "entry shot accepted")
	await submitted()
	aim(false)
	advance(.2)
	present(.5)
	check(near_fov(76) and player.camera.global_basis.is_equal_approx(orientation), "release during recoil restores current hip FOV without aim-axis drift")
	aim(true)
	advance(.4)
	player._shot_time = 0
	check(player.fire(), "fully aimed shot accepted")
	configure_ads(100, 1.6, .2)
	await submitted()
	present(.5)
	check(near_fov(zoom_fov(100, 1.6)), "recoil return uses newly applied base and zoom instead of captured old FOV")
	aim(false)
	advance(.4)
	check(near_fov(100), "release after option change restores new base")

func motion_and_sensitivity() -> void:
	reset()
	if not configure_ads():
		print("GUARDED: configurable ADS mouse factors await configure_aim")
		return
	for scale in [.2, 1.0]:
		configure_ads(76, 1.25, scale)
		aim(false)
		advance(.3)
		aim(true)
		advance(.4)
		var yaw := player.rotation.y
		var pitch := player.camera.rotation.x
		var event := InputEventMouseMotion.new()
		event.screen_relative = Vector2(20, -10)
		player._unhandled_input(event)
		check(absf(player.rotation.y - yaw + 20 * player.sensitivity * scale) < .00001 and absf(player.camera.rotation.x - pitch - 10 * player.sensitivity * scale) < .00001, "actual yaw/pitch obey configured ADS mouse factor %.1f" % scale)
		advance(.4)
		var rear := sight("SightRear")
		var front := sight("SightFront")
		check(rear != null and front != null, "sensitivity proof has physical sights")
		if rear != null and front != null: check(centered(rear.global_position) and centered(front.global_position), "sensitivity change and mouse look preserve stable sight alignment")
		aim(false)
		advance(.4)
		yaw = player.rotation.y
		player._unhandled_input(event)
		check(absf(player.rotation.y - yaw + 20 * player.sensitivity) < .00001, "release restores hip sensitivity")
	player.camera.rotation.x = 1.45
	var clamp_event := InputEventMouseMotion.new()
	clamp_event.screen_relative = Vector2(0, -100)
	player._unhandled_input(clamp_event)
	check(is_equal_approx(player.camera.rotation.x, 1.45), "ADS-aware mouse retains pitch clamp")
	aim(true)
	Input.action_press("forward")
	Input.action_press("sprint")
	advance(.5)
	check(absf(Vector2(player.velocity.x, player.velocity.z).length() - 4.0) < .02, "ready ADS overrides sprint with 4m/s walking")
	Input.action_press("crouch")
	advance(.4)
	check(absf(Vector2(player.velocity.x, player.velocity.z).length() - 2.2) < .02, "crouched ADS retains 2.2m/s speed")
	release_inputs()

func manipulations() -> void:
	for operation in ["d9_reload", "arc_reload", "cell", "switch"]:
		reset(1 if operation == "arc_reload" else 0)
		configure_ads()
		aim(false)
		advance(.3)
		aim(true)
		advance(.4)
		player.state.ammo = 3
		player.state.energy = 30
		var ammo := player.state.ammo
		var energy := player.state.energy
		var reserve := player.state.reserve
		var cells: int = player.state.cells
		var fov := player.camera.fov
		var accepted := true
		match operation:
			"d9_reload", "arc_reload": accepted = player.reload_weapon()
			"cell": accepted = player.request_cell()
			"switch": player.equip(1)
		check(accepted and not player.fire(), operation + " accepts manipulation and blocks firing")
		check(player.state.ammo == ammo and player.state.energy == energy, "blocked fire during " + operation + " has no debit")
		check(absf(player.camera.fov - fov) <= .01, operation + " starts without an instantaneous FOV jump")
		var max_step := 0.0
		var reached_hip := false
		var rebinds := 0
		var weapon := player.weapon_index
		for step in 480:
			var previous := player.camera.fov
			tick(.01)
			max_step = maxf(max_step, absf(player.camera.fov - previous))
			reached_hip = reached_hip or near_fov(76)
			if player.weapon_index != weapon:
				rebinds += 1
				weapon = player.weapon_index
		check(reached_hip and max_step < 1.6, operation + " exits smoothly through HIDDEN/handling without a camera reset jump")
		check(player.reload_cycle.ready and near_fov(zoom_fov(76, 1.25)), operation + " returns to ADS at READY when aim remains held")
		check(contacts_valid(), operation + " restores reachable hand contacts")
		if operation == "d9_reload":
			check(player.state.ammo + player.state.reserve == ammo + reserve and player.state.ammo == 12, "ADS reload conserves D9 rounds")
		elif operation in ["arc_reload", "cell"]:
			check(player.state.energy == 90 and player.state.cells == cells - 1, "ADS cell manipulation transfers exactly one cell")
		else:
			check(rebinds == 1 and player.weapon_index == 1 and player.state.ammo == ammo and player.state.energy == energy, "ADS switch binds once and preserves resources")
		release_inputs()
	reset()
	configure_ads()
	aim(false)
	advance(.3)
	aim(true)
	advance(.4)
	check(not player.reload_weapon(), "full D9 magazine refuses reload")
	advance(.4)
	check(near_fov(zoom_fov(76, 1.25)), "refused reload retains ADS target")
	for weapon in [1, 0, 1]:
		player.equip(weapon)
		tick(.03)
	advance(1.2)
	check(player.weapon_index == 1 and player.reload_cycle.ready and near_fov(zoom_fov(76, 1.25)), "rapid ADS switches converge to final requested READY weapon")
	release_inputs()

func lifecycle() -> void:
	for operation in ["inactive", "teleport", "capture", "death"]:
		reset()
		configure_ads()
		aim(false)
		advance(.3)
		aim(true)
		advance(.4)
		match operation:
			"inactive": player.set_active(false)
			"teleport": player.teleport(Vector3(2, 0, 0))
			"capture": Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			"death": player.apply_damage(100)
		tick(.01)
		check(near_fov(76), operation + " purges ADS camera channel")
		if operation == "death":
			release_inputs()
			continue
		player.set_active(true)
		advance(.5)
		check(near_fov(76), operation + " held RMB cannot reactivate ADS after interruption")
		aim(false)
		tick(.01)
		aim(true)
		advance(.4)
		check(near_fov(zoom_fov(76, 1.25)), operation + " fresh RMB after release rearms ADS")
		release_inputs()
