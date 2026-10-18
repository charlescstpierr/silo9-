extends "res://tests/power_fixture.gd"

const SOURCE_NAMES: Array[String] = ["ceiling_refuge", "ceiling_decontamination", "ceiling_maintenance", "ceiling_archives", "ceiling_core_entry", "ceiling_core_end", "reactor", "alarm_maintenance", "alarm_archives"]

func prepare_lighting() -> bool:
	if not await prepare(): return false
	world.set_process(false)
	for consumer: Node in world.power_consumers.values(): consumer.set_process(false)
	var available: bool = check(world.has_method("set_reduced_light_effects"), "World exposes independent reduced-light preference")
	for id: String in SOURCE_NAMES:
		available = check(source(id) != null, "Real named Omni source exists: " + id) and available
	if available: world.call("set_reduced_light_effects", false)
	return available

func source(id: String) -> OmniLight3D:
	return world.find_child(id, true, false) as OmniLight3D

func advance_lighting(seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.000001:
		var delta: float = minf(remaining, 0.02)
		for consumer: Node in world.power_consumers.values(): consumer.call("_process", delta)
		world.call("_process", delta)
		remaining -= delta

func emitting(light: Light3D) -> bool:
	return light.visible and light.light_energy > 0.00001

func cut_stays_dark(id: String) -> void:
	var light := source("ceiling_" + id)
	check(not light.visible and is_zero_approx(light.light_energy), "Cut ceiling remains physically dark: " + id)

func end_mission(ending: String) -> void:
	state.discover_relay()
	state.collect("lighting-test-components", "components", 3)
	state.repair_relay()
	state.recover_core()
	check(state.choose_ending(ending), "Real mission accepts ending " + ending)
