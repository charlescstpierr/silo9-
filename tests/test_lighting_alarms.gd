extends "res://tests/lighting_fixture.gd"

func _initialize() -> void:
	run.call_deferred()

func assert_alarm(id: String, expected: bool) -> void:
	check(emitting(source("alarm_" + id)) == expected, "Actual alarm light state: %s=%s" % [id, expected])
	var consumer: Node = world.power_consumers[StringName(id)]
	check(consumer.alarm_lens.visible == expected, "Rendered lens agrees with alarm light: " + id)

func run() -> void:
	if not await prepare_lighting():
		await finish()
		return
	var initial_nodes: int = world.find_children("*", "", true, false).size()
	var initial_materials: Array = material_values().keys()
	var initial_lights: Array[int] = []
	for light: OmniLight3D in world.lights: initial_lights.append(light.get_instance_id())
	for low: bool in [false, true]:
		world.set_quality(low)
		for reduced: bool in [false, true]:
			world.call("set_reduced_light_effects", reduced)
			for id: String in ["maintenance", "archives"]:
				advance_lighting(9)
				assert_alarm(id, false)
				command(id, false)
				cut_stays_dark(id)
				assert_alarm(id, true)
				var remaining: float = world.power_consumers[StringName(id)].alarm_remaining
				world.refresh()
				world.refresh()
				check(is_equal_approx(world.power_consumers[StringName(id)].alarm_remaining, remaining), "Refresh never restarts alarm clock")
				advance_lighting(0.3)
				var plateau: float = source("alarm_" + id).light_energy
				advance_lighting(0.3)
				if reduced: check(is_equal_approx(source("alarm_" + id).light_energy, plateau), "Reduced alarm envelope is stable")
				advance_lighting(remaining)
				assert_alarm(id, false)
				command(id, true)
				command(id, false)
				assert_alarm(id, false)
				command(id, true)
				advance_lighting(9)
				command(id, false)
				assert_alarm(id, true)
				command(id, true)
				assert_alarm(id, false)
	for cycle: int in 100:
		world.set_quality(cycle % 2 == 0)
		world.call("set_reduced_light_effects", cycle % 3 == 0)
		command(&"maintenance", false)
		command(&"maintenance", true)
		advance_lighting(0.02)
	check(world.find_children("*", "", true, false).size() == initial_nodes, "Repeated compositions allocate no replacement scene nodes")
	check(material_values().keys() == initial_materials, "Repeated compositions preserve rendered material identities")
	var final_lights: Array[int] = []
	for light: OmniLight3D in world.lights: final_lights.append(light.get_instance_id())
	check(final_lights == initial_lights and final_lights.size() == 9, "Nine real fixed Omni instances survive all transitions")
	for light: Light3D in world.find_children("*", "Light3D", true, false):
		check(not light.shadow_enabled, "World owns no exploration shadow after moving it to Player")
	world.set_quality(false)
	advance_lighting(9)
	command(&"maintenance", false)
	assert_alarm("maintenance", true)
	end_mission("n7")
	assert_alarm("maintenance", false)
	advance_lighting(9)
	command(&"maintenance", true)
	command(&"maintenance", false)
	assert_alarm("maintenance", false)
	await finish()
