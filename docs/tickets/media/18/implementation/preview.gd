extends SceneTree

var app: Node
var output_dir: String

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	output_dir = get_script().resource_path.get_base_dir()
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_process(false)
	app.world.set_process(false)
	app.player.set_physics_process(false)
	for enemy: Node in app.world.enemies: enemy.set_physics_process(false)
	var crate: Node = app.world.get_node("DestructibleCrate")
	crate.receive_hit(24.0, 0.0)
	var placements: Dictionary = {
		"sentinel_1": {"position": Vector3(2.2, 0, -12), "yaw": 0.55},
		"crawler_1": {"position": Vector3(6.0, 0, -12), "yaw": -0.6},
	}
	for enemy: Node3D in app.world.enemies:
		if placements.has(enemy.enemy_id):
			enemy.position = placements[enemy.enemy_id].position
			enemy.rotation.y = placements[enemy.enemy_id].yaw
			enemy.receive_hit(1000.0, 0.0)
	await process_frame
	var camera := Camera3D.new()
	camera.fov = 55
	root.add_child(camera)
	camera.position = Vector3(4.1, 3.4, -7.0)
	camera.look_at(Vector3(4.1, 0.1, -12.1))
	camera.make_current()
	var report: Dictionary = {"camera_position": str(camera.position), "camera_rotation": str(camera.rotation), "fov": camera.fov, "snapshot": app.state._snapshot(), "captures": []}
	for low: bool in [false, true]:
		app.world.set_quality(low)
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		var filename := "remains-low.png" if low else "remains-normal.png"
		var result: Error = root.get_texture().get_image().save_png(output_dir.path_join(filename))
		report.captures.append({"path": filename, "low": low, "error": result, "render_scale": root.scaling_3d_scale})
	# Count all six after the two-variant composition has been captured.
	for enemy in app.world.enemies:
		if is_instance_valid(enemy): enemy.receive_hit(1000.0, 0.0)
	await process_frame
	var meshes: Dictionary = {}
	var materials: Dictionary = {}
	var traces: Array[Dictionary] = []
	for id: String in app.world._death_traces:
		var trace: Node3D = app.world._death_traces[id]
		var geometry: Array[Dictionary] = []
		for mesh: MeshInstance3D in trace.find_children("*", "MeshInstance3D", true, false):
			materials[mesh.material_override.get_instance_id()] = true
			var mesh_id := mesh.mesh.get_instance_id()
			var vertices: int = 0
			var indices: int = 0
			var array_bytes: int = 0
			for surface in mesh.mesh.get_surface_count():
				vertices += mesh.mesh.surface_get_array_len(surface)
				indices += mesh.mesh.surface_get_array_index_len(surface)
				for array: Variant in mesh.mesh.surface_get_arrays(surface):
					if typeof(array) in [TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY]:
						array_bytes += array.size() if array is PackedByteArray else array.to_byte_array().size()
			meshes[mesh_id] = {"surfaces": mesh.mesh.get_surface_count(), "vertices": vertices, "indices": indices, "attribute_array_bytes": array_bytes}
			geometry.append({"resource": mesh_id, "material": mesh.material_override.get_instance_id(), "shadow": mesh.cast_shadow, "range": mesh.visibility_range_end})
		traces.append({"id": id, "position": str(trace.position), "yaw": trace.rotation.y, "meshes": geometry, "processing": trace.is_processing() or trace.is_physics_processing(), "collision_objects": trace.find_children("*", "CollisionObject3D", true, false).size(), "lights": trace.find_children("*", "Light3D", true, false).size(), "timers": trace.find_children("*", "Timer", true, false).size()})
	var panels: MultiMeshInstance3D = crate.get_node("CratePanels")
	report["traces"] = traces
	report["shared_array_meshes"] = meshes
	report["robot_material_count"] = materials.size()
	report["crate"] = {"collision_layer": crate.collision_layer, "collision_mask": crate.collision_mask, "panels": panels.multimesh.instance_count, "mesh_type": panels.multimesh.mesh.get_class(), "shadow": panels.cast_shadow, "range": panels.visibility_range_end}
	var file := FileAccess.open(output_dir.path_join("preview-measurements.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("PREVIEW: captures=", report.captures.size(), " robots=", traces.size(), " shared_meshes=", meshes.size(), " materials=", materials.size())
	app.queue_free()
	camera.queue_free()
	await process_frame
	quit()
