extends "res://tests/lighting_fixture.gd"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if not await prepare_lighting():
		await finish()
		return
	world.set_quality(false)
	world.call("set_reduced_light_effects", true)
	var stable: float = source("ceiling_maintenance").light_energy
	var baseline: Dictionary = material_values()
	var neighbor: float = source("ceiling_archives").light_energy
	world.call("set_reduced_light_effects", false)
	var varied := false
	var emitter_materials: Array[Material] = []
	for step: int in 80:
		advance_lighting(0.1)
		var energy: float = source("ceiling_maintenance").light_energy
		check(energy > 0 and energy <= stable + 0.0001, "Faulty neon remains lit without overshoot")
		check(is_equal_approx(source("ceiling_archives").light_energy, neighbor), "Neon animation does not change neighboring source")
		if energy < stable * 0.99:
			varied = true
			var values: Dictionary = material_values()
			for material: Material in baseline:
				if baseline[material].energy > 0 and values[material].energy < baseline[material].energy * 0.99:
					if not emitter_materials.has(material): emitter_materials.append(material)
					check(is_equal_approx(values[material].energy / baseline[material].energy, energy / stable), "Rendered neon emission follows the real light gain")
	check(varied, "Maintenance neon actually varies during its authored cycle")
	check(not emitter_materials.is_empty(), "Neon variation reaches actual rendered emission material")
	for object_id: String in ["relay", "evidence", "core", "component_3"]:
		for mesh: MeshInstance3D in world.objects[object_id].find_children("*", "MeshInstance3D", true, false):
			for surface: int in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(surface)
				check(not emitter_materials.has(material), "Quest object never shares faulty neon material: " + object_id)
	world.call("set_reduced_light_effects", true)
	for step: int in 80:
		advance_lighting(0.1)
		check(is_equal_approx(source("ceiling_maintenance").light_energy, stable), "Reduced option stabilizes neon across entire cycle")
	world.call("_set_colossus_gain", 0.05)
	check(is_equal_approx(source("ceiling_maintenance").light_energy, stable), "Reduced option suppresses colossus light gain")
	world.call("_set_colossus_gain", 1.0)
	for low: bool in [false, true]:
		world.set_quality(low)
		command(&"maintenance", false)
		world.refresh()
		advance_lighting(0.2)
		cut_stays_dark("maintenance")
		for material: Material in emitter_materials:
			check(is_zero_approx(material.emission_energy_multiplier), "Power cut extinguishes rendered neon emitter")
		world.set_quality(not low)
		cut_stays_dark("maintenance")
		world.call("set_reduced_light_effects", false)
		world.call("_set_colossus_gain", 0.05)
		advance_lighting(7.0)
		cut_stays_dark("maintenance")
		world.call("_set_colossus_gain", 1.0)
		world.call("set_reduced_light_effects", true)
		command(&"maintenance", true)
		check(emitting(source("ceiling_maintenance")), "Restoration relights ceiling after quality and event changes")
	for ending: String in ["mother", "n7"]:
		if ending == "n7":
			world.queue_free()
			player.queue_free()
			await process_frame
			if not await prepare_lighting(): break
		command(&"maintenance", false)
		end_mission(ending)
		for low: bool in [true, false]:
			world.set_quality(low)
			advance_lighting(7)
			cut_stays_dark("maintenance")
		command(&"maintenance", true)
		var final_energy: float = source("ceiling_maintenance").light_energy
		advance_lighting(7)
		check(is_equal_approx(source("ceiling_maintenance").light_energy, final_energy), "Ending stabilizes faulty neon: " + ending)
	await finish()
