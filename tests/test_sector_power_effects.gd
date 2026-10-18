extends "res://tests/power_fixture.gd"

var light_reference: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func poses(node: Node) -> Dictionary:
	var result: Dictionary = {}
	for child: Node in node.find_children("*", "Node3D", true, false):
		result[child.get_instance_id()] = child.transform
	return result

func assert_lights(low: bool) -> void:
	check(world.lights.size() == 9, "Composition preserves nine real Omni lights")
	for light: OmniLight3D in world.lights:
		if str(light.name).begins_with("alarm_"): continue
		var id: String = str(light.name).trim_prefix("ceiling_")
		var powered: bool = on(StringName(id)) if id in ["maintenance", "archives"] else true
		var expected: bool = powered and (not low or light.name != &"reactor")
		check(light.visible == expected, "Circuit and quality compose visibility: " + str(light.name))
		check(is_equal_approx(light.light_energy, light_reference[low][light.get_instance_id()] if expected else 0.0), "Composition restores measured source amplitude without drift: " + str(light.name))

func run() -> void:
	if not await prepare():
		await finish()
		return
	world.set_quality(false)
	if world.has_method("set_reduced_light_effects"): world.call("set_reduced_light_effects", true)
	for low: bool in [true, false]:
		world.set_quality(low)
		var levels: Dictionary = {}
		for light: OmniLight3D in world.lights: levels[light.get_instance_id()] = light.light_energy
		light_reference[low] = levels
	var initial: Dictionary = material_values()
	var initial_nodes: int = world.find_children("*", "AudioStreamPlayer3D", true, false).size()
	command(&"maintenance", false)
	var maintenance_materials: Array[Material] = []
	var after_cut: Dictionary = material_values()
	check(initial.keys() == after_cut.keys(), "Switching power keeps rendered materials and batches")
	for material: Material in initial:
		if initial[material].energy > 0 and after_cut.get(material, {}).get("energy", -1) == 0:
			maintenance_materials.append(material)
			check(after_cut[material].albedo.get_luminance() < initial[material].albedo.get_luminance(), "Unpowered emissive facade darkens")
	check(not maintenance_materials.is_empty(), "Maintenance cut reaches actual final rendered emission materials")
	command(&"archives", false)
	var both_cut: Dictionary = material_values()
	var archives_count: int = 0
	for material: Material in after_cut:
		if after_cut[material].energy > 0 and both_cut.get(material, {}).get("energy", -1) == 0:
			archives_count += 1
	check(archives_count > 0, "Archives has independent rendered emissions")
	for low: bool in [true, false, true, false]:
		world.set_quality(low)
		world.refresh()
		assert_lights(low)
	command(&"maintenance", true)
	assert_lights(false)
	world.set_quality(true)
	assert_lights(true)
	world.set_quality(false)
	command(&"maintenance", false)
	player.position = Vector3(0, 0, -60)
	await create_timer(0.65).timeout
	check(world.colossus_triggered, "Colossus event ran in the real world")
	for light: OmniLight3D in world.lights:
		if light.name in [&"ceiling_maintenance", &"ceiling_archives"]:
			check(not light.visible and is_zero_approx(light.light_energy), "Colossus cannot revive a cut circuit")
	await create_timer(1.2).timeout
	assert_lights(false)
	for id: String in ["maintenance", "archives"]:
		command(id, true)
		var fan: Node = world.objects.get("fan_" + id)
		if fan == null: fan = world.find_child("fan_" + id, true, false)
		if not check(fan != null, "Inspectible fan exists for " + id): continue
		var fan_node_count: int = fan.find_children("*", "", true, false).size()
		var running: Dictionary = poses(fan)
		await create_timer(0.12).timeout
		check(poses(fan) != running, "Powered fan rotates visible geometry " + id)
		command(id, false)
		var stopped: Dictionary = poses(fan)
		await create_timer(0.12).timeout
		check(poses(fan) == stopped, "Cut fan preserves rotor angle " + id)
		for sound: AudioStreamPlayer3D in fan.find_children("*", "AudioStreamPlayer3D", true, false):
			check(not sound.playing, "Cut fan stops local airflow")
		command(id, true)
		await create_timer(0.12).timeout
		check(poses(fan) != stopped, "Restored fan resumes rotation " + id)
		for cycle: int in 3:
			command(id, false)
			command(id, true)
		check(fan.find_children("*", "", true, false).size() == fan_node_count, "Fan cycles do not duplicate rotors or sound players " + id)
	for cycle: int in 5:
		for id: String in ["maintenance", "archives"]:
			command(id, false)
			command(id, true)
	check(world.find_children("*", "AudioStreamPlayer3D", true, false).size() == initial_nodes, "Repeated switches do not duplicate sound players")
	check(material_values().keys() == initial.keys(), "Repeated switches do not allocate replacement render materials")
	for material: Material in maintenance_materials:
		check(is_equal_approx(material.emission_energy_multiplier, initial[material].energy), "Power restoration preserves original emission strength")
	assert_lights(false)
	state.discover_relay()
	state.collect("power-test-parts", "components", 3)
	state.repair_relay()
	state.recover_core()
	state.choose_ending("n7")
	command(&"archives", false)
	command(&"archives", true)
	world.set_quality(true)
	world.set_quality(false)
	for light: OmniLight3D in world.lights:
		if str(light.name).begins_with("alarm_"): continue
		check(light.light_color.is_equal_approx(Color("63e9e0")), "Ending tint survives circuit and quality changes")
	for enemy: CharacterBody3D in world.enemies:
		check(not enemy.is_physics_processing(), "Restoring power never reactivates N7 ending enemies")
	await finish()
