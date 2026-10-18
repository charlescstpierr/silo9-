extends SceneTree

var app: Node
var output := ""
var mode := "scenes"
var captures: Array[Dictionary] = []
var events: Array[Dictionary] = []
var frame_number := 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="):
			output = argument.trim_prefix("--proof-output=")
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
	run.call_deferred()

func run() -> void:
	seed(9)
	root.size = Vector2i(1920, 1080) if mode == "scenes" else Vector2i(1280, 720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.new_game()
	app.set_quality("--low" in OS.get_cmdline_user_args())
	if mode == "scenes":
		await scenes()
	else:
		await demonstrate()
	var report := {"mode":mode,"resolution":[root.size.x,root.size.y],"godot":Engine.get_version_info().string,"renderer":RenderingServer.get_video_adapter_name(),"rendering_method":RenderingServer.get_current_rendering_method(),"window_size":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"fixed_fps":30,"exposure":app.world.ambience.environment.tonemap_exposure,"captures":captures,"events":events,"complete":true,"method":"Frozen initial world, identical fixed cameras" if mode == "scenes" else "Real player actions; offline rendered 30 FPS simulation, not realtime performance; empty/partial magazine and energy seeded for demonstrations"}
	var file := FileAccess.open(output + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	app.queue_free()
	paused = false
	await process_frame
	quit()

func capture(filename: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output + "/" + filename)
	if error != OK:
		push_error("PNG write failed: " + filename)
		quit(1)
		return
	var camera: Camera3D = root.get_camera_3d()
	captures.append({"file":filename,"label":label,"frame":frame_number,"camera_position":[camera.global_position.x,camera.global_position.y,camera.global_position.z],"camera_rotation":[camera.global_rotation.x,camera.global_rotation.y,camera.global_rotation.z],"fov":camera.fov,"ammo":app.state.ammo,"reserve":app.state.reserve,"energy":app.state.energy,"reloading":app.player.reloading,"reload_progress":1.0 - app.player.get("_reload_time") / load("res://data/weapons/d9.tres").reload_duration if app.player.reloading else -1.0})

func scenes() -> void:
	app.player.set_active(false)
	app.process_mode = Node.PROCESS_MODE_DISABLED
	paused = true
	app.ui.visible = false
	var positions := [Vector3(0,0,7), Vector3(0,0,-22), Vector3(0,0,-43), Vector3(3,0,-64)]
	var labels := ["refuge", "maintenance", "archives", "reactor"]
	for index in positions.size():
		app.player.teleport(positions[index], atan2(3.0,8.0) if index == 3 else 0.0)
		app.world.art.update_focus(positions[index])
		await process_frame
		await capture(labels[index] + ".png", labels[index])
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(4.7,1.5,-23.0)
	camera.look_at(Vector3(3,0.9,-20))
	camera.fov = 52.0
	camera.current = true
	app.player.visible = false
	app.world.art.update_focus(camera.position)
	await process_frame
	await capture("robot.png", "sentinel initial pose")
	camera.queue_free()

func record(seconds: float, label: String) -> void:
	for index in ceili(seconds * 30.0):
		await process_frame
		await capture("frame-%04d.png" % frame_number, label)
		frame_number += 1

func record_reload(label: String) -> void:
	var duration: float = load("res://data/weapons/d9.tres").reload_duration
	for index in ceili((duration + 1.0) * 30.0):
		if not app.player.reloading:
			break
		await record(1.0 / 30.0, label)
	event(label + " completed", not app.player.reloading)
	await record(0.3, label + " settle")

func event(label: String, accepted: bool) -> void:
	events.append({"label":label,"accepted":accepted,"frame":frame_number,"ammo":app.state.ammo,"reserve":app.state.reserve,"energy":app.state.energy})
	if not accepted:
		push_error("Demo action rejected: " + label)

func demonstrate() -> void:
	app.player.teleport(Vector3(0,0,7))
	await record(0.5,"D9 idle")
	Input.action_press("forward")
	await record(0.6,"walk")
	Input.action_press("sprint")
	await record(0.5,"sprint")
	Input.action_release("sprint")
	Input.action_release("forward")
	await record(0.3,"settle")
	Input.action_press("aim")
	await record(0.4,"D9 aim")
	event("D9 fire", app.player.fire())
	await record(0.3,"D9 shot")
	Input.action_release("aim")
	app.state.reserve = 72
	event("partial reload", app.player.reload_weapon())
	await record_reload("D9 partial reload")
	app.state.ammo = 0
	event("empty reload", app.player.reload_weapon())
	await record_reload("D9 empty reload")
	app.state.ammo = 3
	event("interrupted reload", app.player.reload_weapon())
	await record(0.3,"D9 interrupted reload")
	app.player.equip(1)
	event("switch cancels reload", not app.player.reloading)
	await record(0.6,"ARC equip")
	app.state.energy = 100.0
	Input.action_press("aim")
	await record(0.4,"ARC aim")
	event("ARC fire", app.player.fire())
	await record(0.4,"ARC shot")
	Input.action_release("aim")
	event("shared battery scan", app.player.activate_scan())
	await record(0.8,"Echo scan after ARC shot")
	app.player.equip(0)
	await record(0.5,"D9 equip")
