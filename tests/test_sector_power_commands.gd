extends "res://tests/power_fixture.gd"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not await prepare():
		await finish()
		return
	var before: int = revision()
	var first_enemy: CharacterBody3D = world.enemies[0]
	first_enemy.position = Vector3(0, 0, -20)
	first_enemy.mode = "patrol"
	first_enemy.stunned = 0
	var publications: Array[Dictionary] = []
	var observe := func() -> void:
		publications.append({"save": saved(), "nested": world.call("set_circuit", &"archives", false)})
		for light: OmniLight3D in world.lights:
			if light.global_position.z <= -14 and light.global_position.z > -34:
				check(not light.visible and is_zero_approx(light.light_energy), "Observer sees committed lighting before publication")
	state.changed.connect(observe)
	command(&"maintenance", false)
	state.changed.disconnect(observe)
	check(first_enemy.mode == "investigate", "First admissible cut alerts a nearby living enemy")
	var alarm_sounds: Array[AudioStreamPlayer3D] = []
	for sound: AudioStreamPlayer3D in world.find_children("*", "AudioStreamPlayer3D", true, false):
		if sound.playing and absf(sound.global_position.z + 18) < 2 and absf(sound.global_position.x - 2) < 2:
			alarm_sounds.append(sound)
	check(not alarm_sounds.is_empty(), "First cut starts an actual local alarm sound")
	check(publications.size() == 1, "One transition publishes once")
	if not publications.is_empty():
		check(publications[0].nested == outcomes.BUSY and on(&"archives"), "Observer cannot reenter a command")
		check(publications[0].save.circuits == {"maintenance": false, "archives": true}, "Observer saves committed circuit state")
	check(revision() == before + 1, "A transition increments revision once")
	var quiet: Array[int] = []
	state.changed.connect(func() -> void: quiet.append(1))
	command(&"maintenance", false, "UNCHANGED")
	command(&"unknown", false, "UNKNOWN_CIRCUIT")
	player.active = false
	command(&"archives", false, "INACTIVE")
	player.active = true
	state.health = 0
	command(&"archives", false, "INACTIVE")
	state.health = 100
	check(quiet.is_empty() and revision() == before + 1 and on(&"archives"), "Retries and refusals have no publication or mutation")
	var fake := StaticBody3D.new()
	fake.set_meta("id", "breaker_archives")
	root.add_child(fake)
	world.interact(fake)
	check(on(&"archives") and quiet.is_empty(), "Forged breaker identity cannot operate circuit")
	fake.queue_free()
	if check(world.objects.has_all(["breaker_maintenance", "breaker_archives"]), "Both physical breaker objects exist"):
		for id: String in ["maintenance", "archives"]:
			var breaker: StaticBody3D = world.objects["breaker_" + id]
			var was_on: bool = on(id)
			world.interact(breaker)
			check(on(id) != was_on, "Registered physical breaker toggles " + id)
			check(breaker.visible and breaker.collision_layer != 0 and not str(breaker.get_meta("prompt", "")).is_empty(), "Breaker stays visible, collisionnable and labelled off power")
	for sound: AudioStreamPlayer3D in alarm_sounds:
		check(not sound.playing, "Restoration stops the active alarm")
	command(&"maintenance", true, "UNCHANGED")
	command(&"archives", true)
	var enemy: CharacterBody3D = world.enemies[0]
	enemy.position = Vector3(0, 0, -20)
	enemy.mode = "patrol"
	enemy.stunned = 0
	command(&"maintenance", false)
	check(enemy.mode == "patrol", "Cut inside cooldown does not alert again")
	command(&"archives", false)
	world.refresh()
	check(enemy.mode == "patrol", "Refresh does not replay electrical noise")
	for cycle: int in 4:
		command(&"maintenance", true)
		command(&"maintenance", false)
		check(not on(&"maintenance") and not on(&"archives"), "Repeated transitions preserve independent circuit states")
	for id: String in ["maintenance", "archives"]:
		command(id, true)
	for enemy_node: CharacterBody3D in world.enemies:
		enemy_node.position = Vector3(0, 0, 7)
	await settle()
	for z: float in [-14.0, -34.0]:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.35
		capsule.height = 1.8
		var crossing := PhysicsShapeQueryParameters3D.new()
		crossing.shape = capsule
		crossing.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0.95, z + 1.0))
		crossing.motion = Vector3(0, 0, -2)
		crossing.collision_mask = 1
		var motion: PackedFloat32Array = world.get_world_3d().direct_space_state.cast_motion(crossing)
		check(motion[0] >= 0.999, "Player capsule crosses central passage under power")
		check(blocked(-2.1, z), "Powered left leaf blocks its lane")
		check(blocked(2.1, z), "Powered lateral leaf blocks its lane")
	command(&"maintenance", false)
	await settle()
	check(not blocked(2.1, -14), "Power cut removes lateral collision")
	player.position = Vector3(1.2, 0, -14)
	await settle()
	command(&"maintenance", true)
	await settle()
	check(not blocked(2.1, -14, [player.get_rid()]) and player.position.is_equal_approx(Vector3(1.2, 0, -14)), "Occupied leaf stays open without moving player")
	player.position = Vector3(0, 0, 7)
	await settle()
	check(blocked(2.1, -14), "Pending leaf closes after player leaves")
	for robot: CharacterBody3D in world.enemies:
		command(&"maintenance", false)
		robot.position = Vector3(-2.1, 0, -14)
		await settle()
		command(&"maintenance", true)
		await settle()
		check(not blocked(-2.1, -14, [robot.get_rid()]), "Full robot body prevents unsafe leaf closure")
		command(&"maintenance", false)
		robot.position = Vector3(0, 0, 7)
		await settle()
		check(not blocked(-2.1, -14), "Power cut cancels pending closure after actor leaves")
		command(&"maintenance", true)
	await finish()
