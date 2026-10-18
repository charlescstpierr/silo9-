extends SceneTree
const State = preload("res://scripts/run_state.gd")
var failures := 0
var checks := 0
var app: Node
func _initialize() -> void:
	run.call_deferred()
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", text)
func run() -> void:
	app = load("res://scripts/main.gd").new()
	app.boot_world = false
	root.add_child(app)
	for phase: int in 6:
		for combination: int in 4:
			var state := State.new()
			if phase >= 1: state.discover_relay()
			if phase >= 2:
				state.collect("review-parts", "components", 3)
				state.repair_relay()
			if phase >= 3: state.recover_core()
			if phase >= 4: state.choose_ending("mother" if phase == 4 else "n7")
			app._start_run(state)
			app.resume_game()
			app.player.set_physics_process(false)
			for enemy in app.world.enemies: enemy.set_physics_process(false)
			var expected_phase: int = state.phase
			var expected_facts: Array = state.facts.duplicate()
			var expected_ending: String = state.ending
			var maintenance: bool = (combination & 1) != 0
			var archives: bool = (combination & 2) != 0
			app.world.set_circuit(&"maintenance", maintenance)
			app.world.set_circuit(&"archives", archives)
			check(state.phase == expected_phase and state.facts == expected_facts and state.ending == expected_ending, "Cut preserves mission")
			app.save_run()
			app.load_run()
			app.player.set_physics_process(false)
			for enemy in app.world.enemies: enemy.set_physics_process(false)
			check(app.state.circuit_on(&"maintenance") == maintenance and app.state.circuit_on(&"archives") == archives, "Main restore preserves combination")
			check(app.state.phase == expected_phase and app.state.facts == expected_facts and app.state.ending == expected_ending, "Main restore preserves mission")
			for id: StringName in [&"maintenance", &"archives"]:
				var consumers = app.world.power_consumers[id]
				check(consumers.powered == app.state.circuit_on(id), "Machine restored to circuit state")
				check(not consumers.alarm.playing and not consumers.alarm_lens.visible and consumers.alarm_remaining == 0.0, "Restore is silent")
			for light in app.world.lights:
				var id: StringName = app.world.Spec.at_z(light.position.z)
				if id != &"" and not app.state.circuit_on(id):
					check(not light.visible and light.light_energy == 0.0, "Restore cannot light a cut sector")
			await physics_frame
			await physics_frame
			for id: StringName in [&"maintenance", &"archives"]:
				check(app.world.power_consumers[id].closed == app.state.circuit_on(id), "Restored empty gate follows circuit safely")
			print("RESTORE CASE phase=", phase, " combination=", combination, " failures=", failures)
	app.free()
	await process_frame
	print("RESTORE REVIEW: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
