extends "res://tests/ads_fixture.gd"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	await prepare_ads()
	for weapon in 2:
		reset(weapon)
		var rear := sight("SightRear")
		var front := sight("SightFront")
		check(rear != null and front != null, "weapon %d exposes front and rear references tied to visible sights" % weapon)
		if rear == null or front == null:
			print("GUARDED: weapon %d geometry/projection matrix awaits sight references" % weapon)
			continue
		if not configure_ads(): continue
		check(sights_have_geometry(rear, front), "weapon %d references meet front top and both rear-notch sides in actual triangles" % weapon)
		for fov in [60.0, 76.0, 100.0]:
			configure_ads(fov)
			player.rotation.y = .37
			player.camera.rotation.x = .11
			aim(false)
			advance(.4)
			aim(true)
			advance(.5)
			check(near_fov(zoom_fov(fov, 1.25)), "weapon %d FOV %.0f reaches optical magnification" % [weapon, fov])
			check(centered(rear.global_position) and centered(front.global_position), "both sights project within 1px at FOV %.0f weapon %d" % [fov, weapon])
			var axis := (front.global_position - rear.global_position).normalized()
			check(rad_to_deg(axis.angle_to(-player.camera.global_basis.z)) <= .05, "sight axis within .05 degrees of camera ray")
			check(-player.camera.to_local(rear.global_position).z >= player.camera.near + .02 and -player.camera.to_local(front.global_position).z >= player.camera.near + .02, "sights clear near plane by 2cm")
			check(contacts_valid(), "ADS preserves both hand contacts within 2mm and reachable IK")
			for distance in [3.0, 10.0, 20.0]:
				await shot_at(distance, weapon, fov)
			Input.action_press("forward")
			Input.action_press("crouch")
			advance(.4)
			check(centered(rear.global_position) and centered(front.global_position), "ADS sights remain centered during movement and crouch")
			release_inputs()
			advance(.4)
	await negative_rays()
	release_inputs()
	await create_timer(.25).timeout
	await finish("ADS GEOMETRY")

func shot_at(distance: float, weapon: int, fov: float) -> void:
	var camera_pose := player.camera.global_transform
	var direction := -camera_pose.basis.z
	var target := box(camera_pose.origin + direction * (distance + .02), Vector3(.04, .04, .04), true) as Target
	target.basis = camera_pose.basis
	await physics_frame
	player.state.ammo = 12
	player.state.energy = 100
	player._shot_time = 0
	check(player.fire(), "accepted ADS shot weapon %d FOV %.0f distance %.0fm" % [weapon, fov, distance])
	check(target.hits == 1 and is_equal_approx(target.damage, 28.0 if weapon == 0 else 39.0), "4cm real collider receives exactly one weapon damage event")
	check(player.state.ammo == (11 if weapon == 0 else 12) and player.state.energy == (100.0 if weapon == 0 else 88.0), "ADS preserves weapon-specific debit")
	check(player._impact.visible and centered(player._impact.global_position) and absf(player._impact.global_position.distance_to(camera_pose.origin) - distance) <= .002, "actual collision face and projected impact match center within 1px")
	check(player._shot_query.from.is_equal_approx(camera_pose.origin) and player._shot_query.to.is_equal_approx(camera_pose.origin + direction * player._weapon().reach), "actual physics query preserves camera origin, axis and weapon reach")
	check(player.camera.global_transform.is_equal_approx(camera_pose), "shot feedback leaves actual aiming transform unchanged")
	await submitted()
	present(.5)
	target.free()

func negative_rays() -> void:
	reset(1)
	player.rotation.y = -.24
	player.camera.rotation.x = .08
	var camera_pose := player.camera.global_transform
	var direction := -camera_pose.basis.z
	var distant := box(camera_pose.origin + direction * 23.02, Vector3(.04, .04, .04), true) as Target
	distant.basis = camera_pose.basis
	await physics_frame
	check(player.fire() and distant.hits == 0, "ARC cannot hit a target face beyond its 22m range")
	distant.free()
	var target := box(camera_pose.origin + direction * 3.02, Vector3(.04, .04, .04), true) as Target
	target.basis = camera_pose.basis
	var wall := box(camera_pose.origin + direction, Vector3(.2, .2, .1))
	wall.basis = camera_pose.basis
	await physics_frame
	player._shot_time = 0
	check(player.fire() and target.hits == 0 and player._impact.global_position.distance_to(camera_pose.origin) < 1.01, "near world obstacle blocks damage and owns the actual impact")

func sights_have_geometry(rear: Node3D, front: Node3D) -> bool:
	var front_distance := INF
	var rear_left := false
	var rear_right := false
	var gun: Node3D = player.rig._weapons[player.weapon_index]
	var axis := (front.global_position - rear.global_position).normalized()
	var right := axis.cross(gun.global_basis.y.normalized()).normalized()
	for mesh: MeshInstance3D in gun.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree(): continue
		var triangles := mesh.mesh.get_faces()
		for index in range(0, triangles.size(), 3):
			var a := mesh.global_transform * triangles[index]
			var b := mesh.global_transform * triangles[index + 1]
			var c := mesh.global_transform * triangles[index + 2]
			var up := gun.global_basis.y.normalized()
			var hit: Variant = Geometry3D.ray_intersects_triangle(front.global_position + up * .001, -up, a, b, c)
			if hit is Vector3: front_distance = minf(front_distance, hit.distance_to(front.global_position))
			for vertex in [a, b, c]:
				var offset: Vector3 = vertex - rear.global_position
				if absf(offset.dot(axis)) < .012 and absf(offset.dot(gun.global_basis.y.normalized())) < .006 and offset.length() < .035:
					rear_left = rear_left or offset.dot(right) < -.003
					rear_right = rear_right or offset.dot(right) > .003
	return front_distance <= .001 and rear_left and rear_right
