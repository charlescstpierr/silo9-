extends Node

const MINIMUM_SAMPLES := 20

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
	app.show_perf = false
	var low: bool = "--low" in OS.get_cmdline_user_args()
	app.set_quality(low)
	var stations: Array[Vector3] = [Vector3(0, 0, 7), Vector3(0, 0, -22), Vector3(0, 0, -43), Vector3(0, 0, -66)]
	for i: int in range(stations.size()):
		app.state.health = 100.0
		app.player.teleport(stations[i])
		app.player.set_active(true)
		app.player.set_physics_process(false)
		await _wait_wall(1.5)
		frames.clear()
		var measurement_started: int = Time.get_ticks_usec()
		measuring = true
		if i == 1:
			app.player.activate_scan()
		await _wait_wall(3.0)
		measuring = false
		var measurement_seconds: float = float(Time.get_ticks_usec() - measurement_started) / 1000000.0
		if app.state.health <= 0 or app.mode != "playing" or get_tree().paused:
			push_error("Benchmark station interrupted: live gameplay required")
			get_tree().quit(1)
			return
		frames.sort()
		var count: int = frames.size()
		if count < MINIMUM_SAMPLES:
			push_error("Insufficient rendered frame samples")
			get_tree().quit(1)
			return
		samples.append({"sector": app.world.sector_at(stations[i]), "frames": count, "measurement_seconds": measurement_seconds, "p50_ms": frames[count / 2], "p95_ms": frames[mini(int(count * 0.95), count - 1)], "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "objects": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0 if OS.is_debug_build() else null, "player_alive": app.state.health > 0, "enemy_modes": app.world.enemies.filter(func(e): return is_instance_valid(e)).map(func(e): return e.mode)})
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png("user://sector-%d.png" % i)
	var report: Dictionary = {"renderer": RenderingServer.get_video_adapter_name(), "rendering_method": RenderingServer.get_current_rendering_method(), "sample_minimum": MINIMUM_SAMPLES, "godot": Engine.get_version_info().string, "resolution": [1920, 1080], "quality": "low" if low else "normal", "render_scale": get_tree().root.scaling_3d_scale, "vsync_requested": false, "method": "1.5s wall-clock warmup; measure until both 3s wall-clock and 20 rendered frames have elapsed per station. Four stationary cameras; enemy motion and attacks active; artificial health reset to 100 before each benchmark frame, including warmup; scan in maintenance. Not a human playthrough.", "samples": samples}
	var output: String = "user://performance-%s.json" % ("low" if low else "normal")
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print(JSON.stringify(report))
	app.queue_free()
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().quit(0)

func _wait_wall(seconds: float) -> void:
	var deadline: int = Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline or (measuring and frames.size() < MINIMUM_SAMPLES):
		app.state.health = 100.0
		await get_tree().process_frame
