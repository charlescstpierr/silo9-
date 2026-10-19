extends "res://tests/persistence_fixture.gd"

func run() -> void:
	migration_cases()
	schema_four_cases()
	capacity_case()
	utf8_boundary_case()
	file_failure_cases()
	await finish("PERSISTENCE STATE")

func legacy_snapshot(schema: int, phase: int = 0, ending: String = "") -> Dictionary:
	var state := State.new()
	if phase >= 1: state.discover_relay()
	if phase >= 2:
		state.collect("legacy-parts", "components", 3)
		state.repair_relay()
	if phase >= 3: state.recover_core()
	if phase >= 4: state.choose_ending(ending)
	state.mark_defeated("historic-external-id")
	state.add_fact("arc_lock_disabled")
	var data: Dictionary = state._snapshot().duplicate(true)
	data["schema"] = schema
	data.erase("crate_broken")
	data.erase("death_poses")
	if schema == 2: data.erase("circuits")
	else: data["circuits"] = {"maintenance": false, "archives": true}
	return data

func migration_cases() -> void:
	print("CASE migration: schemas 2/3, all phases and both endings")
	for schema: int in [2, 3]:
		for stage: Array in [[0, ""], [1, ""], [2, ""], [3, ""], [4, "mother"], [4, "n7"]]:
			var data := legacy_snapshot(schema, stage[0], stage[1])
			var path := path_for("migration")
			write_json(path, data)
			var state := State.new()
			check(state.load_game(path) == OK, "schema %d phase %d ending %s loads" % [schema, stage[0], stage[1]])
			check(state.phase == stage[0] and state.ending == stage[1] and state.facts == data.facts and state.defeated == data.defeated and state.collected == data.collected, "legacy progression, facts and IDs preserved")
			check(state.circuit_on(&"maintenance") == (schema == 2) and state.circuit_on(&"archives"), "schema 2 defaults ON; schema 3 preserves mixed circuits")
			var migrated: Dictionary = state._snapshot()
			check(migrated.get("schema") == 4 and migrated.get("crate_broken") == false and migrated.get("death_poses") == {}, "SCHEMA_RED migration writes schema 4 with intact crate and no invented poses")
		var full := legacy_snapshot(schema)
		full["defeated"] = []
		for index in 128: full.defeated.append("historic-%03d" % index)
		var bounded := State.new()
		write_json(path_for("legacy-bound"), full)
		check(bounded.load_game(path_for("legacy-bound")) == OK, "legacy schema %d accepts 128 historical IDs" % schema)
		full.defeated.append("historic-overflow")
		assert_rejected(full, bounded, "legacy schema %d rejects ID 129" % schema)

func canonical_four() -> Dictionary:
	var data := legacy_snapshot(3, 3)
	data["schema"] = 4
	data["crate_broken"] = true
	data["defeated"] = ["historic-external-id", "sentinel_1"]
	data["death_poses"] = {"sentinel_1": {"position": [1.25, 0.5, -23.75], "yaw": 0.73}}
	return data

func assert_rejected(data: Dictionary, state: RefCounted, label: String) -> void:
	var before: Dictionary = state._snapshot().duplicate(true)
	var revision: int = state.power_revision
	var events: Array[int] = []
	var capture := func() -> void: events.append(1)
	state.changed.connect(capture)
	write_json(path_for("invalid"), data)
	check(state.load_game(path_for("invalid")) != OK, label)
	check(state._snapshot() == before and state.power_revision == revision and events.is_empty(), label + " is atomic without changed or revision")
	state.changed.disconnect(capture)

func schema_four_cases() -> void:
	print("CASE schema 4: valid poses, strict validation and atomic rejection")
	var valid := canonical_four()
	var state := State.new()
	state.collect("keep-me", "ammo", 7)
	write_json(path_for("four"), valid)
	var accepted := check(state.load_game(path_for("four")) == OK, "SCHEMA_RED valid schema 4 with defeated robot pose loads")
	if accepted:
		var actual: Dictionary = state._snapshot()
		check(actual.crate_broken and actual.death_poses == valid.death_poses and state.defeated == valid.defeated, "schema 4 restores crate and pose annotations")
		check(not state.circuit_on(&"maintenance") and state.circuit_on(&"archives"), "schema 4 retains mixed circuits")
		var events: Array[int] = []
		var capture := func() -> void: events.append(1)
		state.changed.connect(capture)
		state.mark_defeated("sentinel_1")
		state.changed.disconnect(capture)
		check(state._snapshot().death_poses == valid.death_poses and events.is_empty(), "repeated defeat cannot replace existing death pose or emit")
		if check(state.has_method("death_pose"), "loaded robot exposes pose readback"):
			var pose: Variant = state.call("death_pose", "sentinel_1")
			pose.position = Vector3(9, 9, 9)
			pose.yaw = -2.0
			check(state._snapshot().death_poses == valid.death_poses, "returned DeathPose is a defensive copy")
			var incoming: Variant = state.call("death_pose", "sentinel_1")
			incoming.yaw = 7.0 * PI
			state.call("mark_defeated", "crawler_1", incoming)
			var recorded: Dictionary = state._snapshot().duplicate(true)
			incoming.position = Vector3(8, 8, 8)
			incoming.yaw = -1.0
			check(state._snapshot() == recorded, "incoming DeathPose is copied before caller can mutate it")
			check(absf(recorded.death_poses.crawler_1.yaw) <= PI and absf(angle_difference(recorded.death_poses.crawler_1.yaw, 7.0 * PI)) < 0.00001, "death recording normalizes yaw")
			state.call("mark_defeated", "sentinel_1", incoming)
			check(state._snapshot() == recorded, "second defeat with different pose cannot move an existing trace")
		else:
			print("UNEXERCISED: DeathPose copy API unavailable on baseline")
	else:
		print("UNEXERCISED: positive pose roundtrip and copy checks depend on schema 4 acceptance")
	var mutations: Array[Dictionary] = [
		{"crate_broken": 1}, {"crate_broken": "true"}, {"death_poses": []},
		{"death_poses": {"unknown_robot": {"position": [0, 0, 0], "yaw": 0}}},
		{"death_poses": {"crawler_1": {"position": [0, 0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0, 0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": [10000.1, 0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": [-10000.1, 0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": [true, 0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": ["0", 0, 0], "yaw": 0}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0, 0], "yaw": PI + 0.01}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0, 0], "yaw": -PI - 0.01}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0, 0], "yaw": true}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0, 0]}}},
		{"death_poses": {"sentinel_1": {"position": [0, 0, 0], "yaw": 0, "extra": 1}}},
		{"defeated": ["sentinel_1", "sentinel_1"]}, {"extra": true}
	]
	for index in mutations.size():
		var invalid: Dictionary = valid.duplicate(true)
		invalid.merge(mutations[index], true)
		assert_rejected(invalid, state, "reject invalid schema 4 pose/type/key case %02d" % index)
	for missing: String in ["crate_broken", "death_poses"]:
		var invalid: Dictionary = valid.duplicate(true)
		invalid.erase(missing)
		assert_rejected(invalid, state, "reject missing " + missing)
	var edges: Dictionary = valid.duplicate(true)
	edges.death_poses.sentinel_1 = {"position": [-10000, 10000, 10000], "yaw": PI}
	write_json(path_for("edges"), edges)
	check(State.new().load_game(path_for("edges")) == OK, "SCHEMA_RED inclusive pose boundaries remain loadable")
	for field: String in ["position", "yaw"]:
		var nonfinite: Dictionary = valid.duplicate(true)
		if field == "position": nonfinite.death_poses.sentinel_1.position[0] = INF
		else: nonfinite.death_poses.sentinel_1.yaw = NAN
		check(not state._valid_snapshot(nonfinite), "reject nonfinite " + field + " before mutation")
	if not accepted: print("NOTE: invalid schema 4 rejections alone do not prove individual validators before schema 4 exists")

func capacity_case() -> void:
	print("CASE capacity: 128 historical IDs plus six catalog robots")
	var legacy := legacy_snapshot(3)
	legacy["defeated"] = []
	for index in 128: legacy.defeated.append("historic-%03d" % index)
	write_json(path_for("capacity-old"), legacy)
	var state := State.new()
	check(state.load_game(path_for("capacity-old")) == OK, "full historical save loads before six real deaths")
	for id: String in ROBOT_IDS: state.mark_defeated(id)
	check(state.defeated.size() == 134, "CAPACITY_RED six real robot IDs fit beyond 128 historical IDs")
	var retained := true
	for id: String in legacy.defeated:
		if not state.defeated.has(id): retained = false
	for id: String in ROBOT_IDS:
		if not state.defeated.has(id): retained = false
	check(retained, "CAPACITY_RED no historical ID evicted and every real robot recorded")
	state.mark_defeated("historic-overflow")
	check(not state.defeated.has("historic-overflow"), "generic historical IDs remain capped at 128")
	check(state.save_game(path_for("capacity-new")) == OK, "full capacity saves")
	var restored := State.new()
	check(restored.load_game(path_for("capacity-new")) == OK and restored.defeated.size() == 134, "CAPACITY_RED all 134 IDs survive disk roundtrip")
	var overflow := canonical_four()
	overflow["defeated"] = legacy.defeated.duplicate()
	for id: String in ROBOT_IDS: overflow.defeated.append(id)
	overflow.defeated.append("historic-overflow")
	assert_rejected(overflow, restored, "schema 4 rejects 129 generic plus six real IDs")

func sized_state(target_bytes: int) -> RefCounted:
	var state := State.new()
	for index in 256:
		var prefix := "%03d-" % index
		state.collected.append(prefix + "é".repeat(80 - prefix.length()))
	for index in 32: state.memory.append("x")
	for index in 32:
		var remaining := target_bytes - JSON.stringify(state._snapshot()).to_utf8_buffer().size()
		if remaining <= 0: break
		var total := mini(remaining + 1, 960)
		var fours := total / 4
		var ones := total % 4
		if fours + ones > 240:
			# Fill the remaining bytes in the next memory entry.
			fours = 239
			ones = 0
		state.memory[index] = "🙂".repeat(fours) + "x".repeat(ones)
	check(JSON.stringify(state._snapshot()).to_utf8_buffer().size() == target_bytes, "fixture produces exactly %d UTF-8 bytes" % target_bytes)
	check(state._valid_snapshot(state._snapshot()), "UTF-8 fixture satisfies field counts and character limits")
	return state

func utf8_boundary_case() -> void:
	print("CASE file bytes: exact limit, one byte over, old target/temp preservation")
	var path := path_for("utf8")
	var state := sized_state(65536)
	check(state.save_game(path) == OK, "exactly 65536 UTF-8 bytes can be saved")
	check(FileAccess.get_file_as_bytes(path).size() == 65536, "saved file measures 65536 bytes, not characters")
	check(State.new().load_game(path) == OK, "exact limit is readable")
	var original := FileAccess.get_file_as_bytes(path)
	state = sized_state(65537)
	write_text(path + ".tmp", "temporary must remain untouched")
	var before: Dictionary = state._snapshot().duplicate(true)
	var revision: int = state.power_revision
	var events: Array[int] = []
	state.changed.connect(func() -> void: events.append(1))
	check(state.save_game(path) != OK, "SIZE_RED refuse 65537 UTF-8 bytes before touching files")
	check(FileAccess.get_file_as_bytes(path) == original, "SIZE_RED oversized save preserves previous valid file byte-for-byte")
	check(FileAccess.file_exists(path + ".tmp") and FileAccess.get_file_as_string(path + ".tmp") == "temporary must remain untouched", "SIZE_RED oversized save does not open or truncate temporary")
	check(state._snapshot() == before and state.power_revision == revision and events.is_empty(), "oversized save rejection leaves in-memory state and signals unchanged")
	check(State.new().load_game(path) == OK, "SIZE_RED previous valid save remains loadable after refused write")

func file_failure_cases() -> void:
	print("CASE file failures: temporary open, failed rename, controlled write failure")
	var state := State.new()
	var path := path_for("open-error")
	check(state.save_game(path) == OK, "seed file for temporary open error")
	var old := FileAccess.get_file_as_bytes(path)
	check(DirAccess.make_dir_absolute(path + ".tmp") == OK, "fixture blocks temporary path with directory")
	check(state.save_game(path) != OK and FileAccess.get_file_as_bytes(path) == old, "temporary open error preserves old save")
	DirAccess.remove_absolute(path + ".tmp")
	if OS.get_name() != "Linux":
		print("UNEXERCISED: rename permissions and /dev/full fixture require Linux")
		return
	var directory := path_for("rename-dir")
	paths.erase(directory)
	check(DirAccess.make_dir_absolute(directory) == OK, "fixture creates rename-error directory")
	var target := directory + "/save.json"
	check(state.save_game(target) == OK, "seed file for failed rename")
	old = FileAccess.get_file_as_bytes(target)
	write_text(target + ".tmp", "writable temporary")
	check(FileAccess.set_unix_permissions(directory, 365) == OK, "fixture denies directory rename while temp remains writable")
	var result: int = state.save_game(target)
	check(result != OK and FileAccess.get_file_as_bytes(target) == old, "failed rename preserves previous file bytes")
	FileAccess.set_unix_permissions(directory, 493)
	DirAccess.remove_absolute(target + ".tmp")
	DirAccess.remove_absolute(target)
	DirAccess.remove_absolute(directory)
	var reread_path := path_for("reread")
	check(state.save_game(reread_path) == OK, "seed file for controlled write failure")
	old = FileAccess.get_file_as_bytes(reread_path)
	var absolute_temp := ProjectSettings.globalize_path(reread_path + ".tmp")
	check(DirAccess.open("user://").create_link("/dev/full", absolute_temp) == OK, "fixture directs temporary writes to full device")
	result = state.save_game(reread_path)
	check(result != OK, "write failure returns an error")
	check(FileAccess.get_file_as_bytes(reread_path) == old, "write failure preserves previous valid save")
	DirAccess.remove_absolute(reread_path + ".tmp")
	DirAccess.remove_absolute(reread_path)
