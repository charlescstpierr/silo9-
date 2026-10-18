extends SceneTree

const State = preload("res://scripts/run_state.gd")
const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
var failures: int = 0
var state: RefCounted
var world: Node3D
var player: CharacterBody3D
var outcomes: Dictionary = {}

func check(value: bool, label: String) -> bool:
	if not value:
		failures += 1
		printerr("FAIL: " + label)
	return value

func has_property(object: Object, key: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if property.name == key:
			return true
	return false

func prepare() -> bool:
	state = State.new()
	var available: bool = state.has_method("circuit_on") and state.has_method("power_summary") and has_property(state, "power_revision")
	if not check(available, "Sector power must expose readable circuit state, filtered summary and revision"):
		return false
	player = Player.new()
	player.setup(state)
	root.add_child(player)
	player.position = Vector3(0, 0, 7)
	player.active = true
	player.set_physics_process(false)
	world = World.new()
	world.setup(state, player)
	root.add_child(world)
	for enemy: CharacterBody3D in world.enemies:
		enemy.set_physics_process(false)
	await settle()
	if not check(world.has_method("set_circuit"), "Sector power must provide the world command"):
		return false
	var constants: Dictionary = world.get_script().get_script_constant_map()
	outcomes = constants.get("PowerOutcome", {})
	return check(outcomes.has_all(["CHANGED", "UNCHANGED", "UNKNOWN_CIRCUIT", "BUSY", "INACTIVE"]), "Circuit command distinguishes changes, retries and refusals")

func settle() -> void:
	await physics_frame
	await physics_frame

func command(id: StringName, enabled: bool, expected: String = "CHANGED") -> void:
	check(world.call("set_circuit", id, enabled) == outcomes[expected], "Circuit %s -> %s returns %s" % [id, enabled, expected])

func on(id: StringName) -> bool:
	return state.call("circuit_on", id)

func revision() -> int:
	return state.get("power_revision")

func write_save(data: Dictionary, path: String = "user://power-input.json") -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func saved(path: String = "user://power-output.json") -> Dictionary:
	check(state.save_game(path) == OK, "Save commits successfully")
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func finish() -> void:
	if is_instance_valid(world): world.queue_free()
	if is_instance_valid(player): player.queue_free()
	await process_frame
	print("SECTOR POWER: %d failures" % failures)
	quit(1 if failures else 0)

func blocked(x: float, z: float, exclusions: Array[RID] = []) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 1.0, z + 0.7), Vector3(x, 1.0, z - 0.7), 1, exclusions)
	return not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func material_values() -> Dictionary:
	var values: Dictionary = {}
	for node: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh
		if node is MeshInstance3D: mesh = node.mesh
		elif node is MultiMeshInstance3D and node.multimesh != null: mesh = node.multimesh.mesh
		if mesh == null: continue
		for surface: int in mesh.get_surface_count():
			var material: Material = node.material_override
			if material == null and node is MeshInstance3D: material = node.get_surface_override_material(surface)
			if material == null: material = mesh.surface_get_material(surface)
			if material is BaseMaterial3D:
				values[material] = {"energy": material.emission_energy_multiplier if material.emission_enabled else 0.0, "albedo": material.albedo_color}
	return values
