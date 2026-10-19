extends "res://tests/power_fixture.gd"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not await prepare():
		await finish()
		return
	check(on(&"maintenance") and on(&"archives"), "New mission starts with both circuits on")
	state.discover_relay()
	state.collect("power-test-parts", "components", 3)
	state.repair_relay()
	var historical: Dictionary = saved()
	historical.erase("circuits")
	historical.erase("crate_broken")
	historical.erase("death_poses")
	historical.schema = 2
	for progress: Array in [[0, ""], [1, ""], [2, ""], [3, ""], [4, "mother"], [4, "n7"]]:
		var legacy_run := State.new()
		if progress[0] >= 1: legacy_run.discover_relay()
		if progress[0] >= 2:
			legacy_run.collect("legacy-parts", "components", 3)
			legacy_run.repair_relay()
		if progress[0] >= 3: legacy_run.recover_core()
		if progress[0] == 4: legacy_run.choose_ending(progress[1])
		check(legacy_run.save_game("user://legacy-source.json") == OK, "Generate valid historical progression through mission API")
		var legacy_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://legacy-source.json"))
		legacy_data.erase("circuits")
		legacy_data.erase("crate_broken")
		legacy_data.erase("death_poses")
		legacy_data.schema = 2
		write_save(legacy_data)
		check(state.load_game("user://power-input.json") == OK, "Migrate historical phase %s ending %s" % progress)
		check(state.phase == progress[0] and state.ending == progress[1] and state.facts == legacy_run.facts, "Migration preserves exact phase, ending and acquired facts")
		check(on(&"maintenance") and on(&"archives"), "All historical mission phases migrate with both circuits on")
	command(&"maintenance", false)
	command(&"archives", false)
	var before_revision: int = revision()
	write_save(historical)
	check(state.load_game("user://power-input.json") == OK, "Valid schema 2 migrates")
	check(on(&"maintenance") and on(&"archives"), "Migration restores both circuits on")
	check(revision() > before_revision, "Loading existing state invalidates prior electrical context")
	command(&"maintenance", false)
	var valid: Dictionary = saved()
	check(valid.schema == 4 and valid.get("circuits") == {"maintenance": false, "archives": true}, "Schema 4 persists the mixed circuit state")
	check(not valid.has("power_revision"), "Runtime revision is not serialized")
	check(state.phase == 2 and state.facts.has("power_restored"), "Cutting power preserves repaired relay and progression")
	command(&"maintenance", true)
	var legacy_three: Dictionary = valid.duplicate(true)
	legacy_three.schema = 3
	legacy_three.erase("crate_broken")
	legacy_three.erase("death_poses")
	write_save(legacy_three)
	check(state.load_game("user://power-input.json") == OK, "Real schema 3 fixture still loads")
	check(not on(&"maintenance") and on(&"archives"), "Historical schema 3 preserves mixed circuits")
	command(&"maintenance", true)
	write_save(valid)
	check(state.load_game("user://power-input.json") == OK, "Schema 4 loads")
	check(not on(&"maintenance") and on(&"archives"), "Mixed state survives roundtrip")
	var rejected: Array[Dictionary] = []
	for circuits: Variant in [{"maintenance": 0, "archives": true}, {"maintenance": false}, {"maintenance": false, "archives": true, "core": true}, [false, true], null]:
		var malformed: Dictionary = valid.duplicate(true)
		malformed.circuits = circuits
		rejected.append(malformed)
	for base: Dictionary in [historical, legacy_three, valid]:
		for mutation: Dictionary in [{"phase": 0}, {"extra": true}, {"relations": {"mother": 0}}, {"facts": ["relay_location"]}, {"schema": 5}]:
			var malformed: Dictionary = base.duplicate(true)
			malformed.merge(mutation, true)
			rejected.append(malformed)
	for base: Dictionary in [historical, legacy_three]:
		var false_upgrade: Dictionary = base.duplicate(true)
		false_upgrade.schema = 4
		rejected.append(false_upgrade)
	var missing: Dictionary = historical.duplicate(true)
	missing.erase("health")
	rejected.append(missing)
	var snapshot: Dictionary = saved()
	var stable_revision: int = revision()
	var signals: Array[int] = []
	state.changed.connect(func() -> void: signals.append(1))
	for malformed: Dictionary in rejected:
		write_save(malformed)
		check(state.load_game("user://power-input.json") != OK, "Malformed current or historical save is refused")
		check(saved() == snapshot and revision() == stable_revision and signals.is_empty(), "Refused load changes no state, revision or signal")
	var oversized := FileAccess.open("user://power-input.json", FileAccess.WRITE)
	oversized.store_string(" ".repeat(65537))
	oversized.close()
	check(state.load_game("user://power-input.json") != OK, "Oversized save remains refused")
	check(saved() == snapshot and signals.is_empty(), "Oversized refusal is atomic")
	await finish()
