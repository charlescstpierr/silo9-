extends SceneTree

const State = preload("res://scripts/run_state.gd")
const Enemy = preload("res://scripts/enemy.gd")
const ROBOT_IDS: Array[String] = ["sentinel_1", "crawler_1", "sentinel_2", "crawler_2", "sentinel_3", "crawler_3"]
var failures: int = 0
var checks: int = 0
var app: Node
var paths: Array[String] = []
var backups: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> bool:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1
	return value

func path_for(label: String) -> String:
	var path := "user://persistence-%d-%s.json" % [OS.get_process_id(), label]
	if not paths.has(path): paths.append(path)
	return path

func write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not check(file != null, "fixture can write " + path.get_file()): return
	file.store_string(value)
	file.close()

func write_json(path: String, data: Dictionary) -> void:
	write_text(path, JSON.stringify(data))

func read_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func preserve_default_save() -> void:
	for path: String in ["user://silo9-save.json", "user://silo9-save.json.tmp"]:
		backups[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null

func start_app() -> void:
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	freeze()
	await settle()

func freeze() -> void:
	app.set_process(false)
	app.player.set_physics_process(false)
	app.world.set_process(false)
	for enemy: Node in app.world.enemies:
		if is_instance_valid(enemy): enemy.set_physics_process(false)

func settle() -> void:
	await physics_frame
	await physics_frame

func reload_app() -> void:
	var old_player: int = app.player.get_instance_id()
	var old_world: int = app.world.get_instance_id()
	app.save_run()
	app.load_run()
	check(app.player.get_instance_id() != old_player and app.world.get_instance_id() != old_world, "main.load_run replaces both Player and World")
	freeze()

func close_app() -> void:
	if is_instance_valid(app): app.queue_free()
	paused = false
	await process_frame

func ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [app.player.get_rid()])
	return app.world.get_world_3d().direct_space_state.intersect_ray(query)

func geometry_ids() -> Dictionary:
	var result: Dictionary = {}
	for mesh: GeometryInstance3D in app.world.find_children("*", "GeometryInstance3D", true, false):
		result[mesh.get_instance_id()] = true
	return result

func new_visible_geometry(previous: Dictionary, origin: Vector3, radius: float) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	for mesh: GeometryInstance3D in app.world.find_children("*", "GeometryInstance3D", true, false):
		if not previous.has(mesh.get_instance_id()) and mesh.is_visible_in_tree() and mesh.global_position.distance_to(origin) < radius:
			result.append(mesh)
	return result

func trace_at(origin: Vector3, yaw: float) -> Node3D:
	for node: Node in app.world.find_children("*", "Node3D", true, false):
		if node is Enemy or not node is Node3D: continue
		if node.global_position.distance_to(origin) > 0.001 or absf(angle_difference(node.global_rotation.y, yaw)) > 0.001: continue
		for mesh: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
			if mesh.is_visible_in_tree(): return node
	return null

func finish(label: String) -> void:
	await close_app()
	for path: String in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		if FileAccess.file_exists(path + ".tmp"): DirAccess.remove_absolute(path + ".tmp")
	for path: String in backups:
		if backups[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(backups[path])
			file.close()
	print("%s: %d checks, %d failures" % [label, checks, failures])
	quit(1 if failures else 0)
