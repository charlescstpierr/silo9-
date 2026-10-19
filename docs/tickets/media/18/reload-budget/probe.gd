extends "res://tests/persistence_fixture.gd"

const WARMUP_RELOADS := 2
const MEASURED_RELOADS := 20
var report: Dictionary = {"warmup_reloads": WARMUP_RELOADS, "measured_reloads": MEASURED_RELOADS, "actions": [], "samples": []}
var expected_poses: Dictionary = {}
var output_dir: String

func counters() -> Dictionary:
	return {"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "static_memory_bytes": OS.get_static_memory_usage()}

func vector_json(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func settled() -> void:
	for frame in 6: await process_frame
	await settle()

func capture_sample(stage: String, cycle: int, save_us: int, load_us: int, settled_us: int, old_player: int, old_world: int) -> Dictionary:
	var meshes: Dictionary = {}
	var materials: Dictionary = {}
	var traces: Array[Dictionary] = []
	var geometry_count: int = 0
	for id: String in ROBOT_IDS:
		var trace: Node3D = app.world.get_node_or_null("Remains_" + id)
		check(trace != null, stage + ": actual trace exists for " + id)
		if trace == null: continue
		var geometry: Array[Dictionary] = []
		for instance: MeshInstance3D in trace.find_children("*", "MeshInstance3D", true, false):
			geometry_count += 1
			var mesh: Mesh = instance.mesh
			var resource_id := str(mesh.get_instance_id())
			var material_id := str(instance.material_override.get_instance_id())
			var vertices := 0
			var indices := 0
			var array_bytes := 0
			for surface in mesh.get_surface_count():
				vertices += mesh.surface_get_array_len(surface)
				indices += mesh.surface_get_array_index_len(surface)
				for array: Variant in mesh.surface_get_arrays(surface):
					if typeof(array) in [TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY]:
						array_bytes += array.size() if array is PackedByteArray else array.to_byte_array().size()
			meshes[resource_id] = {"class": mesh.get_class(), "surfaces": mesh.get_surface_count(), "vertices": vertices, "indices": indices, "attribute_array_bytes": array_bytes}
			materials[material_id] = instance.material_override.get_class()
			geometry.append({"mesh": resource_id, "material": material_id, "visible": instance.is_visible_in_tree(), "shadow": instance.cast_shadow, "range": instance.visibility_range_end})
		var processing := trace.is_processing() or trace.is_physics_processing()
		for node: Node in trace.find_children("*", "", true, false):
			processing = processing or node.is_processing() or node.is_physics_processing()
		traces.append({"id": id, "node_id": str(trace.get_instance_id()), "position": vector_json(trace.global_position), "yaw": trace.global_rotation.y, "geometry": geometry, "processing": processing, "collision_objects": trace.find_children("*", "CollisionObject3D", true, false).size(), "lights": trace.find_children("*", "Light3D", true, false).size(), "timers": trace.find_children("*", "Timer", true, false).size()})
	var crate: Node3D = app.world.get_node("DestructibleCrate")
	var panels: MultiMeshInstance3D = crate.get_node("CratePanels")
	var enemies_alive := 0
	for body: Node in app.world.find_children("*", "CharacterBody3D", true, false):
		if body is Enemy: enemies_alive += 1
	var sample := {"stage": stage, "cycle": cycle, "player_id": str(app.player.get_instance_id()), "world_id": str(app.world.get_instance_id()), "old_player_freed": old_player == 0 or not is_instance_id_valid(old_player), "old_world_freed": old_world == 0 or not is_instance_id_valid(old_world), "enemies": enemies_alive, "traces": traces, "meshes": meshes, "materials": materials, "visible_remains_instances": geometry_count + int(panels.is_visible_in_tree()), "crate": {"visible": panels.is_visible_in_tree(), "panels": panels.multimesh.instance_count, "collision_layer": crate.collision_layer, "collision_mask": crate.collision_mask, "mesh": str(panels.multimesh.mesh.get_instance_id()), "mesh_class": panels.multimesh.mesh.get_class(), "shared_with_world_box": panels.multimesh.mesh == app.world.box_mesh, "material_shared_with_world": panels.material_override == app.world.materials.steel, "shadow": panels.cast_shadow, "range": panels.visibility_range_end}, "snapshot": app.state._snapshot().duplicate(true), "counters": counters(), "audio_nodes_in_tree": app.find_children("*", "AudioStreamPlayer3D", true, false).size() + app.find_children("*", "AudioStreamPlayer", true, false).size(), "save_call_us": save_us, "load_call_us": load_us, "load_plus_settle_us": settled_us}
	return sample

func run() -> void:
	output_dir = OS.get_environment("SILO_RELOAD_OUTPUT")
	if output_dir.is_empty(): output_dir = get_script().resource_path.get_base_dir()
	report["initial_counters"] = counters()
	preserve_default_save()
	await start_app()
	app.set_quality(false)
	await settled()
	app.player.teleport(Vector3(4, 0, -10))
	app.player.camera.look_at(Vector3(4, 0.4, -12))
	app.player.set_physics_process(true)
	app.player.equip(0)
	await create_timer(0.8).timeout
	app.player.set_physics_process(false)
	app.player.camera.look_at(Vector3(4, 0.4, -12))
	var hit := ray(app.player.camera.global_position, Vector3(4, 0.4, -12))
	check(not hit.is_empty() and hit.get("collider") == app.world.get_node("DestructibleCrate"), "actual player ray targets authored crate")
	var ammo_before: int = app.state.ammo
	var started: int = Time.get_ticks_usec()
	var fired: bool = app.player.fire()
	var fire_us := Time.get_ticks_usec() - started
	check(fired and app.state.ammo == ammo_before - 1 and app.state.crate_broken(), "real D9 consumes one round and breaks crate")
	check(not hit.is_empty() and app.player._impact.global_position.distance_to(hit.position) < 0.01, "real hitscan lands on crate")
	report.actions.append({"kind": "crate_player_fire", "us": fire_us, "ammo_before": ammo_before, "ammo_after": app.state.ammo, "accepted": fired})
	for victim in app.world.enemies:
		var id: String = victim.enemy_id
		victim.position += Vector3(0.35, 0, -0.45)
		victim.rotation.y = 0.4 if victim.crawler else -0.7
		expected_poses[id] = {"position": vector_json(victim.global_position), "yaw": victim.global_rotation.y}
		started = Time.get_ticks_usec()
		victim.receive_hit(1000.0, 0.0)
		report.actions.append({"kind": "enemy_receive_hit", "id": id, "us": Time.get_ticks_usec() - started})
	check(app.state.defeated.size() == 6, "six actual Enemy calls record six identified defeats")
	await create_timer(1.0).timeout
	await settled()
	report["expected_poses"] = expected_poses
	report.samples.append(capture_sample("prepared", -1, 0, 0, 0, 0, 0))
	for cycle in WARMUP_RELOADS + MEASURED_RELOADS:
		var old_player: int = app.player.get_instance_id()
		var old_world: int = app.world.get_instance_id()
		started = Time.get_ticks_usec()
		app.save_run()
		var save_us := Time.get_ticks_usec() - started
		var saved: Dictionary = read_json("user://silo9-save.json")
		check(saved.get("crate_broken", false) and saved.get("death_poses", {}).size() == 6, "actual Main save contains all six poses and broken crate")
		started = Time.get_ticks_usec()
		app.load_run()
		var load_us := Time.get_ticks_usec() - started
		check(app.player.get_instance_id() != old_player and app.world.get_instance_id() != old_world, "actual Main load reconstructs Player and World")
		freeze()
		await settled()
		var settle_us := Time.get_ticks_usec() - started
		for repeat in 20: app.world.refresh()
		var stage := "warmup" if cycle < WARMUP_RELOADS else "measured"
		report.samples.append(capture_sample(stage, cycle, save_us, load_us, settle_us, old_player, old_world))
		save_report()
	await close_app()
	for frame in 10: await process_frame
	report["after_teardown_counters"] = counters()
	report["assertions"] = checks
	report["failures"] = failures
	save_report()
	await finish("RELOAD BUDGET")

func save_report() -> void:
	var file := FileAccess.open(output_dir.path_join("measurements.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
