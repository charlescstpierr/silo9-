extends Node

var app: Node
var frames: Array[float] = []
var samples: Array[Dictionary] = []
var previous_usec: int = 0
var measuring: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if measuring and previous_usec > 0:
		frames.append(float(now - previous_usec) / 1000.0)
	previous_usec = now

func _run() -> void:
	get_tree().root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if app == null:
		app = load("res://main.tscn").instantiate()
		get_tree().root.add_child(app)
	await get_tree().process_frame
	app.new_game()
	app.show_perf = true
	var low: bool = "--low" in OS.get_cmdline_user_args()
	app.world.set_quality(low)
	var stations: Array[Vector3] = [Vector3(0, 0, 7), Vector3(0, 0, -22), Vector3(0, 0, -43), Vector3(0, 0, -66)]
	for i: int in range(stations.size()):
		app.player.teleport(stations[i])
		app.player.set_active(true)
		app.player.set_physics_process(false)
		await get_tree().create_timer(1.5).timeout
		frames.clear()
		measuring = true
		if i == 1:
			app.world.scan(stations[i])
		await get_tree().create_timer(3.0).timeout
		measuring = false
		frames.sort()
		var count: int = frames.size()
		if count == 0:
			push_error("No rendered frame samples")
			get_tree().quit(1)
			return
		samples.append({"sector": app.world.sector_at(stations[i]), "frames": count, "p50_ms": frames[count / 2], "p95_ms": frames[mini(int(count * 0.95), count - 1)], "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "objects": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0 if OS.is_debug_build() else null, "player_alive": app.state.health > 0, "enemy_modes": app.world.enemies.filter(func(e): return is_instance_valid(e)).map(func(e): return e.mode)})
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png("user://sector-%d.png" % i)
	var report: Dictionary = {"renderer": RenderingServer.get_video_adapter_name(), "godot": Engine.get_version_info().string, "resolution": [1920, 1080], "quality": "low" if low else "normal", "render_scale": get_tree().root.scaling_3d_scale, "vsync_requested": false, "method": "1.5s warmup + 3s rendered samples per station; camera positioned at four sectors; enemy simulation active; scan in maintenance. Not a human playthrough.", "samples": samples}
	var output: String = "user://performance-%s.json" % ("low" if low else "normal")
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print(JSON.stringify(report))
	app.queue_free()
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().quit(0)
