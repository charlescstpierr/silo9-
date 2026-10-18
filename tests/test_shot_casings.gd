extends "res://tests/shot_feedback_fixture.gd"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	await prepare()
	reset()
	var pool := casings()
	check(pool != null, "accepted design provides a world casing pool owned by Player")
	if pool != null:
		pool.set_physics_process(false)
		var ejection := player.rig.get("ejection") as Node3D
		check(ejection != null, "D9 has composed ejection marker")
		var nodes := get_node_count()
		var resources: Array[Resource] = []
		for mesh in pool.find_children("*", "MeshInstance3D", true, false):
			resources.append(mesh.mesh)
			resources.append(mesh.get_active_material(0))
		check(pool.find_children("*", "CollisionObject3D", true, false).is_empty(), "decorative pool cannot intercept hitscan or player motion")
		configure(1, 1, 2)
		var all_accepted := true
		for shot in 12:
			player._shot_time = 0
			all_accepted = player.fire() and all_accepted
			check(visible_cases(pool).size() == mini(shot + 1, 8), "one D9 case per accepted shot with eight-slot cap")
		check(all_accepted and player.state.ammo == 0, "coalesced shots spend twelve real rounds")
		check(not player.fire() and visible_cases(pool).size() == 8, "empty refusal cannot emit ninth case")
		var before: Array[Transform3D] = []
		for casing in visible_cases(pool): before.append(casing.global_transform)
		pool.call("_physics_process", .5)
		var held := true
		var index := 0
		for casing in visible_cases(pool):
			held = held and casing.global_transform.is_equal_approx(before[index])
			index += 1
		check(held and index == 8, "new casings do not simulate before first submitted frame")
		await submitted()
		player.position.x += 3
		var world_fixed := true
		index = 0
		for casing in visible_cases(pool):
			world_fixed = world_fixed and casing.global_transform.is_equal_approx(before[index])
			index += 1
		check(world_fixed, "ejected cases stay in world space when player moves")
		configure(1, 1, 1)
		check(visible_cases(pool).size() == 2, "reducing normal to reduced immediately removes excess cases")
		pool.call("_physics_process", .81)
		check(visible_cases(pool).is_empty() and not pool.is_physics_processing(), "reduced TTL consumes full elapsed delta and stops empty simulation")
		configure(1, 1, 2)
		check(visible_cases(pool).is_empty(), "raising budget never resurrects expired cases")
		player.state.ammo = 12
		player._shot_time = 0
		check(player.fire(), "post-expiry shot accepted")
		check(visible_cases(pool).size() == 1, "expired slot is reused")
		configure(1, 1, 0)
		check(visible_cases(pool).is_empty() and not pool.is_physics_processing() and not player._flash_light.visible, "minimal budget removes casings, idle simulation and light immediately")
		player._shot_time = 0
		check(player.fire() and visible_cases(pool).is_empty() and departure_visible(), "minimal budget keeps departure but emits no cases")
		configure(1, 1, 2)
		player.equip(1)
		check(Ready.wait_for(player, 1), "ARC ready after D9 effects")
		player._shot_time = 0
		check(player.fire() and visible_cases(pool).is_empty(), "accepted ARC shot emits zero cases")
		player.equip(0)
		check(Ready.wait_for(player, 0), "D9 ready for recycle cycles")
		for cycle in 24:
			player.state.ammo = 12
			player._shot_time = 0
			all_accepted = player.fire() and all_accepted
			await submitted()
			pool.call("_physics_process", 2.1)
		check(all_accepted and visible_cases(pool).is_empty() and get_node_count() == nodes, "repeated real fire/expiry cycles preserve node count")
		var reused := true
		index = 0
		for mesh in pool.find_children("*", "MeshInstance3D", true, false):
			reused = reused and mesh.mesh == resources[index] and mesh.get_active_material(0) == resources[index + 1]
			index += 2
		check(reused and index == resources.size(), "recycled slots reuse their original meshes and materials")
		await marker_and_budget_cases(pool)
		await collision_cases(pool)
		for operation in ["inactive", "teleport", "death"]:
			player.state.health = 100
			player.state.ammo = 12
			player.set_active(true)
			player._shot_time = 0
			check(player.fire() and visible_cases(pool).size() == 1, operation + " casing fixture emits")
			match operation:
				"inactive": player.set_active(false)
				"teleport": player.teleport(Vector3.ZERO)
				"death": player.apply_damage(100)
			check(visible_cases(pool).is_empty(), operation + " clears world casings")
	await finish("SHOT CASINGS")

func collision_cases(pool: Node) -> void:
	var target := box(Vector3(0, 1.58, -4), Vector3(2, 2, .2), true) as Target
	var ceiling := box(Vector3(0, 2.5, 0), Vector3(10, .2, 10))
	var wall := box(Vector3(1, 1.2, 0), Vector3(.2, 2.4, 10))
	await physics_frame
	pool.call("clear")
	player.teleport(Vector3.ZERO)
	pool.call("emit", Transform3D(Basis.IDENTITY, Vector3(0, 1.58, -1)), Vector3.ZERO)
	player.state.ammo = 12
	player._shot_time = 0
	check(player.fire() and target.hits == 1 and target.damage == 28, "live casing between camera and target cannot block real hitscan")
	pool.call("clear")
	for origin in [Vector3(0, .1, 0), Vector3(.8, 1, 0), Vector3(0, 2.3, 0)]:
		pool.call("emit", Transform3D(Basis.IDENTITY, origin), Vector3(0, 3, 0))
	await submitted()
	var confined := true
	for tick in 35:
		pool.call("_physics_process", .02)
		for casing in visible_cases(pool):
			var p := casing.global_position
			confined = confined and p.y >= -.01 and p.y <= 2.41 and p.x <= .91
	check(confined, "point sweeps keep cases above floor and outside wall/ceiling")
	pool.call("clear")
	pool.call("emit", Transform3D(Basis.IDENTITY, wall.position), Vector3.ZERO)
	await submitted()
	pool.call("_physics_process", .016)
	check(visible_cases(pool).is_empty(), "case spawned inside solid is retired rather than frozen inside geometry")
	pool.call("emit", Transform3D(Basis.IDENTITY, Vector3(0, .05, 0)), Vector3.ZERO)
	await submitted()
	for tick in 80: pool.call("_physics_process", .02)
	var resting := visible_cases(pool)
	check(not resting.is_empty(), "floor contact can settle a case before normal TTL")
	if not resting.is_empty():
		var pose := resting[0].global_transform
		pool.call("_physics_process", .1)
		check(resting[0].global_transform.is_equal_approx(pose), "settled case has no continuing movement")
	pool.call("clear")
	ceiling.free()
	wall.free()

func marker_and_budget_cases(pool: Node) -> void:
	var ejection := player.rig.get("ejection") as Node3D
	if ejection != null:
		pool.call("clear")
		player.state.ammo = 12
		player._shot_time = 0
		check(player.fire(), "ejection fixture accepts real D9 shot")
		var cases := visible_cases(pool)
		check(cases.size() == 1 and cases[0].global_position.distance_to(ejection.global_position) < .001, "case starts at same-tick composed ejection port")
		player.reload_weapon()
		player._advance_reload(.4)
		player._update_view(0)
		player.equip(1)
		var relative := ejection.global_position - player.rig.muzzle.global_position
		for tick in 4:
			player._advance_reload(.01)
			player._update_view(0)
		check((ejection.global_position - player.rig.muzzle.global_position).is_equal_approx(relative), "LOWER_ABORT lowers ejection with frozen muzzle pose")
		check(visible_cases(pool).size() == 1, "reload and lowering preserve world casing")
		check(Ready.wait_for(player, 1), "HIDDEN completes after aborted reload")
		check(visible_cases(pool).size() == 1, "weapon identity change preserves world casing")
		player.equip(0)
		check(Ready.wait_for(player, 0), "D9 restores after port fixture")
	pool.call("clear")
	configure(1, 1, 2)
	for index in 3:
		pool.call("emit", Transform3D(Basis.IDENTITY, Vector3(index * 2, 1, 0)), Vector3.ZERO)
	configure(1, 1, 1)
	var survivors := visible_cases(pool)
	check(survivors.size() == 2 and survivors.all(func(mesh: MeshInstance3D) -> bool: return mesh.global_position.x > 1), "budget reduction removes oldest case rather than newest")
	pool.call("clear")
	configure(1, 1, 2)
	pool.call("emit", Transform3D(Basis.IDENTITY, Vector3(0, 3, 0)), Vector3(6, 0, 0))
	await submitted()
	pool.call("_physics_process", .02)
	var inherited := visible_cases(pool)
	check(inherited.size() == 1 and inherited[0].global_position.x > .05, "world casing inherits player motion")
	pool.call("clear")
