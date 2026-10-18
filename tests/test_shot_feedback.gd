extends "res://tests/shot_feedback_fixture.gd"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: X11 dummy supplies real frame_pre_draw/frame_post_draw callbacks")
		quit(2)
		return
	await prepare()
	var target := box(Vector3(0, 1.58, -5), Vector3(2, 2, .2), true) as Target
	await physics_frame
	var profiles: Array[Array] = []
	for weapon in [0, 1]:
		reset(weapon)
		player.configure_aim(60.0 if weapon == 0 else 90.0, 1.25, .65)
		var base_fov := player.camera.fov
		var ray := player.camera.global_transform
		var hits := target.hits
		check(player.fire(), "real shot accepted weapon=%d" % weapon)
		check(target.hits == hits + 1 and target.stun == (0.0 if weapon == 0 else 2.3), "hitscan reaches real target once with correct stun")
		check(player.state.ammo == (11 if weapon == 0 else 12) and player.state.energy == (100.0 if weapon == 0 else 88.0), "accepted shot debits only its weapon resource")
		check(player.camera.global_transform.is_equal_approx(ray), "shot preserves actual camera ray transform")
		check(player._shot_query.from.is_equal_approx(ray.origin) and player._shot_query.to.is_equal_approx(ray.origin - ray.basis.z * player._weapon().reach), "actual physics query retains original origin and direction")
		check(player.camera.fov > base_fov and player.camera.fov <= base_fov + 1.0, "accepted shot gives bounded FOV impulse from current rest FOV")
		var geometry: Array = []
		var colors: Array[Color] = []
		var opaque_unshaded := not departure_meshes().is_empty()
		for mesh in departure_meshes():
			var material := mesh.get_active_material(0) as StandardMaterial3D
			geometry.append([mesh.mesh.get_faces(), mesh.transform])
			colors.append(material.albedo_color)
			opaque_unshaded = opaque_unshaded and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
		profiles.append([geometry, colors])
		check(opaque_unshaded, "departure is opaque unshaded geometry")
		if weapon == 0:
			check(player.rig._slide.position.z > 0 and player.rig._slide.position.z <= .0181, "accepted D9 shot retracts real slide within 18 mm")
		var recoil := player._recoil
		player._event_shot = true
		player._physics_process(.25)
		player._physics_process(.05)
		present(.3)
		check(departure_visible() and is_equal_approx(player._recoil, recoil), "physics and process before first draw cannot consume flash or recoil")
		check(player._shot_time > 0 and not player.fire(), "event-shot first tick preserves cooldown; refused follow-up does not debit")
		check(target.hits == hits + 1, "refused follow-up causes no repeated hit")
		var first_draw := [false]
		var observe := func() -> void: first_draw[0] = departure_visible() and player._recoil > 0
		RenderingServer.frame_pre_draw.connect(observe, CONNECT_ONE_SHOT)
		await submitted()
		check(first_draw[0], "first submitted frame contains accepted departure and recoil")
		var previous := player._recoil
		var monotone := true
		for step in 40:
			present(.01)
			monotone = monotone and player._recoil <= previous + .000001 and player._recoil >= 0.0
			previous = player._recoil
		check(monotone and is_zero_approx(player._recoil) and is_equal_approx(player.camera.fov, base_fov), "presentation returns monotonically to exact recoil/FOV rest")
		check(not departure_visible() and not player._beam.visible and not player._flash_light.visible, "submitted departure expires on presentation clock")
		check(target.hits == hits + 1, "presentation never traces or damages again")
	check(profiles[0][0] != profiles[1][0] and profiles[0][1] != profiles[1][1], "D9 flash and ARC pulse have distinct geometry and color")
	check(is_equal_approx(target.damage, 67.0), "one D9 plus one ARC inflict exactly 28 + 39 damage")
	reset()
	if configure(1.0, 1.0, 2):
		player.configure_aim(90, 1.25, .65)
		check(player.fire(), "camera options fixture fires")
		var first_peak := player.camera.fov
		player._shot_time = 0
		check(player.fire() and is_equal_approx(player.camera.fov, first_peak), "coalesced shot resets impulse without accumulating modified FOV")
		await submitted()
		var motion := InputEventMouseMotion.new()
		motion.screen_relative = Vector2(15, -10)
		player._unhandled_input(motion)
		var looked := player.camera.global_basis
		present(.1)
		check(player.rotation.y != 0 and player.camera.rotation.x != 0 and player.camera.global_basis.is_equal_approx(looked), "mouse input during return survives presentation")
		configure(0, 1, 2)
		check(is_equal_approx(player.camera.fov, 90), "camera zero immediately restores current base")
		player._shot_time = 0
		check(player.fire() and is_equal_approx(player.camera.fov, 90), "camera zero suppresses subsequent impulse without suppressing shot")
		await submitted()
		present(1)
		configure(1, 1, 2)
		check(is_equal_approx(player.camera.fov, 90) and not departure_visible(), "raising options does not replay expired shot")
	await light_options()
	await resource_cycles()
	await refusals()
	await transitions()
	await finish("SHOT FEEDBACK")

func refusals() -> void:
	for reason in ["inactive", "dead", "empty", "energy", "busy", "cooldown"]:
		reset(1 if reason == "energy" else 0)
		match reason:
			"inactive": player.set_active(false)
			"dead": player.state.health = 0
			"empty": player.state.ammo = 0
			"energy": player.state.energy = 0
			"busy":
				player.state.ammo = 4
				player.reload_weapon()
			"cooldown": player._shot_time = 1
		var resources := Vector2(player.state.ammo, player.state.energy)
		check(not player.fire() and Vector2(player.state.ammo, player.state.energy) == resources, reason + " refusal preserves resources")
		check(not departure_visible() and not player._beam.visible and not player._flash_light.visible and is_zero_approx(player._recoil), reason + " refusal creates no departure")
		var pool := casings()
		if pool != null: check(visible_cases(pool).is_empty(), reason + " refusal creates no casing")

func transitions() -> void:
	for operation in ["reload", "cell", "switch", "inactive", "death", "teleport"]:
		reset()
		player.state.energy = 30
		check(player.fire(), operation + " starts with accepted shot")
		match operation:
			"reload": check(player.reload_weapon(), "R accepted during shot")
			"cell": check(player.request_cell(), "B accepted during shot")
			"switch": player.equip(1)
			"inactive": player.set_active(false)
			"death": player.apply_damage(100)
			"teleport": player.teleport(Vector3(2, 0, 0))
		if operation in ["reload", "cell"]:
			check(is_zero_approx(player._recoil) and player.rig._slide.position.is_zero_approx() and departure_visible(), operation + " clears recoil and slide immediately but preserves accepted departure")
		elif operation == "switch":
			check(player._recoil > 0, "LOWER preserves outgoing recoil")
			for tick in 100:
				player._advance_reload(.01)
				player._update_view(0)
				if player.weapon_index == 1: break
			check(player.weapon_index == 1 and is_zero_approx(player._recoil) and not departure_visible(), "HIDDEN clears outgoing shot before new weapon appears")
		else:
			check(not departure_visible() and not player._beam.visible and not player._impact.visible and not player._flash_light.visible, operation + " purges every shot effect immediately")
			check(is_zero_approx(player._recoil) and is_equal_approx(player.camera.fov, 76), operation + " restores recoil and FOV")
	reset()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	check(player.fire(), "raw pause fixture fires")
	await submitted()
	player.set_process(true)
	player.set_physics_process(true)
	paused = true
	var paused_recoil := player._recoil
	await create_timer(.15, true).timeout
	check(departure_visible() and is_equal_approx(player._recoil, paused_recoil), "raw SceneTree pause freezes active presentation")
	paused = false
	player.set_process(false)
	player.set_physics_process(false)
	reset(1)
	check(player.fire(), "ARC interruption fixture fires")
	check(player.reload_weapon() and player._beam.visible and is_zero_approx(player._recoil), "ARC R preserves beam while cancelling recoil")
	await submitted()
	present(.5)
	check(not player._beam.visible, "preserved ARC beam still expires")

func light_options() -> void:
	reset(1)
	if not configure(1, 1, 2): return
	check(player.fire(), "full light ARC shot accepted")
	var impact_material := player._impact.get_active_material(0) as StandardMaterial3D
	var impact_color := impact_material.albedo_color
	var flash := departure_meshes()[0]
	var flash_material := flash.get_active_material(0) as StandardMaterial3D
	var full_color := flash_material.albedo_color
	var full_energy := player._flash_light.light_energy
	check(player._flash_light.visible and not player._flash_light.shadow_enabled and is_equal_approx(player._flash_light.omni_range, 2) and player._flash_light.light_cull_mask == 3, "normal light has bounded range, layer mask and no shadows")
	check(player._beam.get_active_material(0) != impact_material and flash_material != impact_material, "target impact material is independent from shot attenuation")
	configure(1, .5, 2)
	var half_color := (flash.get_active_material(0) as StandardMaterial3D).albedo_color
	check(player._flash_light.light_energy < full_energy and half_color != full_color, "intermediate light strength attenuates both source light and departure material")
	configure(1, 0, 2)
	check(not departure_visible() and not player._beam.visible and not player._flash_light.visible, "zero light hides departure, pulse, beam and dynamic light immediately")
	check(player._impact.visible and impact_material.albedo_color == impact_color, "light attenuation preserves actual target impact")
	check(player.state.energy == 88, "changing light options never repeats shot debit")
	await submitted()
	present(1)
	configure(1, 1, 2)
	check(not departure_visible() and not player._beam.visible, "light increase after expiry does not resurrect departure")

func resource_cycles() -> void:
	reset()
	var nodes := get_node_count()
	var resources: Dictionary = {}
	for mesh in player.find_children("*", "MeshInstance3D", true, false):
		resources[mesh.get_instance_id()] = [mesh.mesh, mesh.get_active_material(0)]
	var accepted := true
	for shot in 24:
		player.state.ammo = 12
		player._shot_time = 0
		accepted = player.fire() and accepted
		await submitted()
		present(.3)
	var stable := get_node_count() == nodes
	for mesh in player.find_children("*", "MeshInstance3D", true, false):
		stable = stable and resources.has(mesh.get_instance_id())
		if resources.has(mesh.get_instance_id()):
			stable = stable and resources[mesh.get_instance_id()][0] == mesh.mesh and resources[mesh.get_instance_id()][1] == mesh.get_active_material(0)
	check(accepted and stable, "24 accepted shots reuse initialized nodes, meshes and materials")
	check(is_zero_approx(player._recoil) and is_equal_approx(player.camera.fov, 76), "repeated shots fully return without accumulated recoil or FOV drift")
