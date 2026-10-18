extends SceneTree

const Main = preload("res://scripts/main.gd")
const State = preload("res://scripts/run_state.gd")
var app: Node3D
var output: String
var failures: Array[String] = []
var images: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func vec(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func capture(name: String, position: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new()
	app.add_child(camera)
	camera.position = position
	camera.look_at(target)
	camera.fov = 76
	camera.make_current()
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(position, target, 1)
	if name == "arc": query.exclude = [app.world.objects["device"].get_rid()]
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): failures.append(name + ": collider obscures camera target")
	await RenderingServer.frame_post_draw
	var filename := name + ".png"
	var code := root.get_texture().get_image().save_png(output.path_join(filename))
	if code != OK: failures.append(name + ": PNG write failed")
	images.append({"file": filename, "camera_position": vec(position), "target": vec(target), "fov": camera.fov, "center_ray_clear": hit.is_empty(), "controlled_camera": true})
	camera.queue_free()

func run() -> void:
	output = OS.get_environment("SILO_CAPTURE_OUTPUT")
	var save := OS.get_environment("SILO_CAPTURE_SAVE")
	var state := State.new()
	if state.load_game(save) != OK:
		push_error("Cannot load actual journey save")
		quit(1)
		return
	app = Main.new()
	app.boot_world = false
	root.add_child(app)
	app._start_run(state)
	app.resume_game()
	var low: bool = OS.get_environment("SILO_CAPTURE_LOW") == "1"
	app.set_quality(low)
	app.player.set_active(false)
	app.player.visible = false
	app.world.set_process(false)
	for enemy in app.world.enemies:
		if is_instance_valid(enemy): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	app.ui.visible = false
	await process_frame
	await physics_frame
	var corpse: Node3D = app.world.get_node("Remains_sentinel_1")
	var death: Vector3 = corpse.global_position
	await capture("sentinel_front", Vector3(0, 2, death.z + 3.5), death + Vector3(0, .35, 0))
	await capture("sentinel_back", Vector3(0, 2, death.z - 3.5), death + Vector3(0, .35, 0))
	await capture("crate", Vector3(4, 2, -9), Vector3(4, .25, -12))
	await capture("arc", Vector3(1.4, 1.8, -54.5), Vector3(2.8, .7, -57))
	var report := {"low_quality": low, "save_sha256": FileAccess.get_sha256(save), "death_position": vec(death), "death_yaw": corpse.global_rotation.y, "snapshot": state._snapshot().duplicate(true), "images": images, "failures": failures, "limits": "Actual journey save reconstructed for controlled-camera images. No movement or combat proof. Player rig and HUD hidden for visibility."}
	var file := FileAccess.open(output.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t", true, true))
	file.close()
	app.queue_free()
	await process_frame
	paused = false
	quit(0 if failures.is_empty() else 1)
