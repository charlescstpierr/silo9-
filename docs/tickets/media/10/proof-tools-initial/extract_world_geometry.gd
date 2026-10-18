extends SceneTree
# External evidence tool. Invoke --path PROJECT --script ABSOLUTE_SCRIPT -- OUTPUT.json.
# No production overrides, registry, emitted-placement copies or scene modification.
var world: Node3D
var player: CharacterBody3D
var data := {"schema": 1, "meshes": [], "segments": [], "volumes": [], "colliders": [], "stats": {}, "targets": [], "mesh_inventory": []}
var errors: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func xf(t: Transform3D) -> Array:
	return vec(t.basis.x) + vec(t.basis.y) + vec(t.basis.z) + vec(t.origin)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected one absolute JSON output path after --")
		quit(2)
		return
	var state = load("res://scripts/run_state.gd").new()
	player = load("res://scripts/player.gd").new()
	player.setup(state)
	root.add_child(player)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	world = load("res://scripts/world.gd").new()
	world.setup(state, player)
	root.add_child(world)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	# Construction has finished synchronously; skip nodes already queued for deletion.
	walk(world, "static")
	walk(player, "actor")
	build_checks()
	data["project"] = ProjectSettings.globalize_path("res://")
	data["engine"] = Engine.get_version_info()
	data["source_sha256"] = {}
	for path in ["scripts/world_art.gd", "scripts/world.gd", "scripts/player.gd", "scripts/data/power_consumers.gd", "tests/test_journey.gd"]:
		data["source_sha256"][path] = FileAccess.get_sha256("res://" + path)
	data["measurement"] = "Constructed/potential geometry, not rendered triangles or draw calls. Initial state, before any physics/process tick."
	if not errors.is_empty():
		for error in errors: printerr(error)
		quit(2)
		return
	var output := FileAccess.open(args[0], FileAccess.WRITE)
	if output == null:
		printerr("Cannot write geometry dump: " + args[0])
		quit(2)
		return
	output.store_string(JSON.stringify(data))
	output.close()
	print("GEOMETRY_DUMP ", args[0], " ", JSON.stringify(data["stats"]))
	quit(0)

func walk(node: Node, group: String) -> void:
	if node.is_queued_for_deletion(): return
	if node == world.art: group = "decor"
	if node is CharacterBody3D: group = "actor"
	if node == world.art.core_rotor or node.name == "Rotor": group = "animated"
	if node is MeshInstance3D and node.mesh != null:
		read_mesh(node, node.mesh, [node.global_transform], group, false)
	elif node is MultiMeshInstance3D and node.multimesh != null and node.multimesh.mesh != null:
		var transforms: Array[Transform3D] = []
		for i in node.multimesh.instance_count:
			transforms.append(node.global_transform * node.multimesh.get_instance_transform(i))
		read_mesh(node, node.multimesh.mesh, transforms, group, true)
	if node is CollisionShape3D and node.shape != null and group != "actor":
		var body := node.get_parent()
		if body is StaticBody3D:
			var record := {"type": node.shape.get_class(), "transform": xf(node.global_transform), "layer": body.collision_layer, "mask": body.collision_mask, "disabled": node.disabled, "margin": node.shape.margin}
			if node.shape is BoxShape3D:
				record["size"] = vec(node.shape.size)
			elif node.shape is SphereShape3D:
				record["radius"] = node.shape.radius
			elif node.shape is CapsuleShape3D or node.shape is CylinderShape3D:
				record["radius"] = node.shape.radius
				record["height"] = node.shape.height
			else:
				errors.append("Unsupported collider must be explicitly serialized: " + str(node.get_path()))
			data["colliders"].append(record)
		elif body is CollisionObject3D:
			errors.append("Non-StaticBody collider outside actor scope: " + str(node.get_path()))
	for child in node.get_children(): walk(child, group)

func read_mesh(node: GeometryInstance3D, mesh: Mesh, transforms: Array, group: String, multi: bool) -> void:
	if not data["stats"].has(group):
		data["stats"][group] = {"mesh_instances": 0, "multimesh_nodes": 0, "instances": 0, "surfaces": 0, "triangles": 0}
	var stats: Dictionary = data["stats"][group]
	stats["multimesh_nodes" if multi else "mesh_instances"] += 1
	stats["instances"] += transforms.size()
	stats["surfaces"] += mesh.get_surface_count() * transforms.size()
	var faces := mesh.get_faces()
	if faces.size() % 3 != 0: errors.append("Incomplete triangle faces: " + str(node.get_path()))
	stats["triangles"] += (faces.size() / 3) * transforms.size()
	var record := {"path": str(world.get_path_to(node)) if group != "actor" else str(player.get_path_to(node)), "group": group, "kind": "MultiMesh" if multi else "MeshInstance", "instances": transforms.size(), "surfaces_per_instance": mesh.get_surface_count(), "triangles_per_instance": faces.size() / 3, "visible_in_tree": node.is_visible_in_tree(), "visibility_range_end": node.visibility_range_end}
	if multi: record["declared_visible_instances"] = node.multimesh.visible_instance_count
	data["mesh_inventory"].append(record)
	if group != "decor": return
	var triangles: Array = []
	for transform: Transform3D in transforms:
		for i in range(0, faces.size(), 3):
			triangles.append([vec(transform * faces[i]), vec(transform * faces[i+1]), vec(transform * faces[i+2])])
	data["meshes"].append({"path": record["path"], "triangles": triangles})

func reserve(label: String, a: Vector3, b: Vector3, radius: float) -> void:
	data["volumes"].append({"name": label, "min": [minf(a.x,b.x)-radius, 0.12, minf(a.z,b.z)-radius], "max": [maxf(a.x,b.x)+radius, 1.85, maxf(a.z,b.z)+radius]})

func build_checks() -> void:
	# Approach positions come from existing journey and native mission probes.
	# Target transforms and eye height come from the objects just constructed.
	var approaches := {
		"relay": Vector3(5.2,0,-25), "breaker_maintenance": Vector3(2,0,-16),
		"breaker_archives": Vector3(2,0,-36), "n7": Vector3(-5.2,0,-42),
		"evidence": Vector3(4.2,0,-46), "component_0": Vector3(-2.5,0,-3),
		"component_1": Vector3(3.3,0,-9), "component_2": Vector3(-5.3,0,-11)}
	var eye: Vector3 = player.camera.global_position - player.global_position
	for id: String in approaches:
		var object: Node3D = world.objects[id]
		var approach: Vector3 = approaches[id]
		var target: Vector3 = object.global_position + Vector3(0,0.25 if id.begins_with("component") else 0.7,0)
		data["targets"].append({"id": id, "transform": xf(object.global_transform), "aim": vec(target), "eye_offset": vec(eye), "approach_source": "tests/test_journey.gd; tools/probe_sector_power.gd"})
		data["segments"].append({"name": id, "from": vec(approach + eye), "to": vec(target)})
		reserve("approach_" + id, Vector3(0,0,approach.z), approach, 0.35)
	# Central route includes all rooms; no room-wide exclusions.
	reserve("central_route", Vector3(0,0,7), Vector3(0,0,-56), 0.35)
	reserve("arc_bypass", Vector3(3.6,0,-56), Vector3(3.6,0,-61), 0.35)
	for enemy in world.enemies:
		if enemy.enemy_id in ["sentinel_1", "crawler_1", "sentinel_2", "crawler_2"]:
			var target: Vector3 = enemy.global_position + Vector3(0,0.35 if enemy.crawler else 1.0,0)
			var origin := Vector3(0,0,enemy.global_position.z + 4.0)
			data["segments"].append({"name": "combat_" + enemy.enemy_id, "from": vec(origin + eye), "to": vec(target)})
			reserve("patrol_" + enemy.enemy_id, enemy.patrol[0], enemy.patrol[1], 0.4)
	for id in world.power_consumers:
		var consumer = world.power_consumers[id]
		for leaf: StaticBody3D in consumer.leaves:
			var shape: CollisionShape3D = leaf.get_child(0)
			var half: Vector3 = shape.shape.size * 0.5
			var pos: Vector3 = shape.global_position
			# Sweep to the closed pose defined in PowerConsumers (3.4m below open).
			data["volumes"].append({"name": "door_sweep_" + str(id) + "_" + str(leaf.name), "min": vec(pos-half-Vector3(0,3.4,0)), "max": vec(pos+half)})
