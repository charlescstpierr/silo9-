extends SceneTree
var output := ""
var candidate := false
func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="): output = argument.trim_prefix("--proof-output=")
		if argument == "--candidate": candidate = true
	run.call_deferred()
func run() -> void:
	root.size = Vector2i(1280,720)
	var app: Node = load("res://main.tscn").instantiate()
	root.add_child(app)
	await create_timer(.5).timeout
	app.new_game()
	app.set_quality(false)
	app.player.teleport(Vector3(0,0,7))
	app.player.equip(1)
	for tick in 120:
		if app.player.reload_cycle.ready and app.player.weapon_index == 1: break
		await physics_frame
	assert(app.player.reload_cycle.ready and app.player.weapon_index == 1)
	app.player.set_physics_process(false)
	app.ui.visible = false
	var rows: Array[Dictionary] = []
	for active in ([false,true] if candidate else [false]):
		await create_timer(1.0).timeout
		var times: Array[float] = []
		var costs: Array[float] = []
		var gestures: Dictionary = {}
		var draws: Array[int] = []
		var triangles: Array[int] = []
		var transfers := 0
		var starts := 0
		var end := Time.get_ticks_usec()+8000000
		var previous := Time.get_ticks_usec()
		var delta := 1.0/60.0
		while Time.get_ticks_usec()<end:
			if active and app.player.reload_cycle.ready:
				app.state.energy = 10
				app.state.cells = 1
				assert(app.player.reload_weapon())
				starts += 1
			var cells_before: int = app.state.cells
			app.player._physics_process(delta)
			if app.state.cells < cells_before:
				transfers += 1
				assert(app.state.energy == 70 and app.state.cells == 0)
			var cycle: RefCounted = app.player.get("reload_cycle")
			gestures[str(cycle.view.gesture)] = true
			var before := Time.get_ticks_usec()
			app.player.rig.update_visual(0.0,app.player._view_frame)
			costs.append(float(Time.get_ticks_usec()-before)/1000)
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			delta = float(now-previous)/1000000
			times.append(delta*1000)
			draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			triangles.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
			previous = now
			await process_frame
		times.sort()
		costs.sort()
		assert(app.state.health == 100.0 and app.player.rig.calibration_valid)
		if active:
			assert(transfers >= 2)
			for gesture in range(10,20): assert(gestures.has(str(gesture)))
		rows.append({"active_cell":active,"samples":times.size(),"frame_p50_ms":times[times.size()/2],"frame_p95_ms":times[int(times.size()*.95)],"rig_call_p50_ms":costs[costs.size()/2],"rig_call_p95_ms":costs[int(costs.size()*.95)],"draw_calls_min":draws.min(),"draw_calls_max":draws.max(),"triangles_min":triangles.min(),"triangles_max":triangles.max(),"health":app.state.health,"gestures":gestures.keys(),"starts":starts,"transfers":transfers})
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output+"/cost.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"resolution":"1280x720","records":rows},"\t"))
	print("COST ",rows)
	app.queue_free()
	await create_timer(.4).timeout
	quit()
