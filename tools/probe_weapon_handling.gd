extends SceneTree

var app: Node
var output := "res://.cstack/issue-05/proof"
var mode := "inspection"
var caption: Label
var stage := "warmup"
var recording := false
var anatomy_view := false
var previous_usec := 0
var times: Array[float] = []
var rig_costs: Array[float] = []
var motions: Dictionary = {}
var gestures: Dictionary = {}
var stages: Dictionary = {}
var stage_motion: Dictionary = {}
var events: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var max_contact := 0.0
var max_muzzle := 0.0
var max_speed := 0.0
var draw_min := 2147483647
var draw_max := 0
var triangles_min := 2147483647
var triangles_max := 0
var camera_min := INF
var camera_max := -INF
var recorder := AudioEffectRecord.new()
var film_start := 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="): output = argument.trim_prefix("--proof-output=")
		if argument.begins_with("--probe-mode="): mode = argument.trim_prefix("--probe-mode=")
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_quality(false)
	for enemy in app.world.enemies: enemy.set_physics_process(false)
	app.player.teleport(Vector3(0,0,7))
	app.player.reload_event.connect(log_event)
	caption = Label.new()
	caption.position = Vector2(32,110)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_outline_color",Color.BLACK)
	caption.add_theme_constant_override("outline_size",6)
	app.ui.add_child(caption)
	if mode == "perf": app.ui.visible = false
	await wait(1.0)
	if mode == "film":
		AudioServer.add_bus_effect(0,recorder)
		recorder.set_recording_active(true)
		film_start = Engine.get_process_frames()
	recording = true
	previous_usec = Time.get_ticks_usec()
	await journey()
	recording = false
	if mode == "film":
		recorder.set_recording_active(false)
		var wave := recorder.get_recording()
		wave.save_to_wav(output+"/mixer.wav")
	print("VALIDATION health=",app.state.health," calibration=",app.player.rig.calibration_valid," contact=",max_contact," muzzle=",max_muzzle," speed=",max_speed)
	assert(app.state.health == 100 and app.player.rig.calibration_valid)
	assert(max_contact < .002 and max_muzzle < .0001)
	assert(max_speed > 6.0)
	for required in ["0","1","2","4","5"]:
		assert(motions.has(required), "journey missed manipulation motion " + required)
	times.sort()
	rig_costs.sort()
	var result := {"mode":mode,"renderer":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"resolution":"1280x720","samples":times.size(),"frame_p50_ms":times[times.size()/2],"frame_p95_ms":times[int(times.size()*.95)],"warm_rig_zero_p50_ms":rig_costs[rig_costs.size()/2],"warm_rig_zero_p95_ms":rig_costs[int(rig_costs.size()*.95)],"motions":motions,"gestures":gestures,"stages":stages,"stage_motion":stage_motion,"events":events,"captures":captures,"max_contact_m":max_contact,"max_muzzle_error_m":max_muzzle,"max_actual_speed":max_speed,"draw_calls_min":draw_min,"draw_calls_max":draw_max,"triangles_min":triangles_min,"triangles_max":triangles_max,"camera_y_range_m":camera_max-camera_min,"health":app.state.health,"film_start_frame":film_start,"end_frame":Engine.get_process_frames()}
	var file := FileAccess.open(output+"/journey.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("JOURNEY ",JSON.stringify(result))
	for action in ["forward","sprint","aim"]: Input.action_release(action)
	app.queue_free()
	await create_timer(.4).timeout
	quit()

func _process(_delta: float) -> bool:
	if not recording or not is_instance_valid(app): return false
	var now := Time.get_ticks_usec()
	times.append(float(now-previous_usec)/1000.0)
	previous_usec = now
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var triangles := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	draw_min = mini(draw_min,draws)
	draw_max = maxi(draw_max,draws)
	triangles_min = mini(triangles_min,triangles)
	triangles_max = maxi(triangles_max,triangles)
	var rig: Node3D = app.player.rig
	var cycle: RefCounted = app.player.reload_cycle
	motions[str(cycle.view.motion)] = int(motions.get(str(cycle.view.motion),0))+1
	gestures[str(cycle.view.gesture)] = int(gestures.get(str(cycle.view.gesture),0))+1
	stages[stage] = int(stages.get(stage,0))+1
	var speed: float = Vector2(app.player.get_real_velocity().x,app.player.get_real_velocity().z).length()
	max_speed = maxf(max_speed,speed)
	if not stage_motion.has(stage):
		stage_motion[stage] = {"max_speed":0.0,"grounded_frames":0,"start_wrist":str(rig.skeleton.get_bone_global_pose(3).origin),"end_wrist":""}
	var observed: Dictionary = stage_motion[stage]
	observed.max_speed = maxf(observed.max_speed,speed)
	observed.grounded_frames += 1 if app.player.is_on_floor() else 0
	observed.end_wrist = str(rig.skeleton.get_bone_global_pose(3).origin)
	if app.player.is_on_floor():
		camera_min = minf(camera_min,app.player.camera.position.y)
		camera_max = maxf(camera_max,app.player.camera.position.y)
	var gun: Node3D = rig._weapons[app.player.weapon_index]
	var right: Transform3D = rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(3)
	max_contact = maxf(max_contact,right.origin.distance_to(gun.get_node("GripRight").global_position))
	if rig.left_in_contact:
		var left: Transform3D = rig.skeleton.global_transform*rig.skeleton.get_bone_global_pose(20)
		max_contact = maxf(max_contact,left.origin.distance_to(rig.active_left_grip.global_position))
	max_muzzle = maxf(max_muzzle,rig.muzzle.global_position.distance_to(gun.get_node("Muzzle").global_position))
	var before := Time.get_ticks_usec()
	rig.update_visual(0.0,app.player._view_frame)
	rig_costs.append(float(Time.get_ticks_usec()-before)/1000)
	caption.text = "MANIEMENT / %s\n%s · arme %d | balles %d · énergie %d · cellules %d\n%s" % [stage,cycle.Motion.keys()[cycle.view.motion],app.player.weapon_index,app.state.ammo,app.state.energy,app.state.cells,"Film moteur déterministe à 30 images/s · pas une mesure de fluidité" if mode == "film" else ("Inspection anatomique · effets masqués" if anatomy_view else "Inspection des transformations réelles")]
	return false

func log_event(event: int) -> void:
	if recording: events.append({"frame":Engine.get_process_frames(),"event":event,"stage":stage,"weapon":app.player.weapon_index,"ammo":app.state.ammo,"energy":app.state.energy,"cells":app.state.cells})

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func ready_weapon(index: int) -> void:
	var start := Time.get_ticks_usec()
	app.player.equip(index)
	for tick in 180:
		if app.player.reload_cycle.ready and app.player.weapon_index == index:
			await wait(maxf(.35 - float(Time.get_ticks_usec()-start)/1000000.0, 0.0))
			return
		await physics_frame
	assert(false,"selection did not reach requested final READY")

func sample(label: String, seconds: float, capture_pose: bool = true) -> void:
	stage = label
	await wait(seconds)
	if mode == "inspection" and capture_pose:
		var processing: bool = app.player.is_physics_processing()
		var presenting: bool = app.player.is_processing()
		app.player.set_process(false)
		app.player.set_physics_process(false)
		var rig: Node3D = app.player.rig
		var effects: Array[Node3D] = [app.player._beam,app.player._d9_flash,app.player._arc_pulse,app.player._flash_light,app.player._impact]
		var visibility: Array[bool] = []
		for effect in effects: visibility.append(effect.visible)
		for angle in [0,1]:
			anatomy_view = angle == 1
			rig.rotation.y = .65 if anatomy_view else 0.0
			rig.position = Vector3(0,.15,-.45) if anatomy_view else Vector3.ZERO
			for index in effects.size(): effects[index].visible = visibility[index] and not anatomy_view
			app.player._update_view(0.0)
			await process_frame
			await RenderingServer.frame_post_draw
			var filename := "%s-%s.png"%[label,"fps" if angle == 0 else "oblique"]
			root.get_texture().get_image().save_png(output+"/"+filename)
			captures.append({"file":filename,"motion":app.player.reload_cycle.view.motion,"lower":app.player.reload_cycle.view.lower,"weapon":app.player.weapon_index,"camera_fov":app.player.camera.fov,"anatomy_effects_hidden":anatomy_view,"rig_position":str(rig.position),"rig_yaw":rig.rotation.y})
			rig.rotation = Vector3.ZERO
			rig.position = Vector3.ZERO
		anatomy_view = false
		for index in effects.size(): effects[index].visible = visibility[index]
		app.player._update_view(0.0)
		app.player.set_physics_process(processing)
		app.player.set_process(presenting)

func journey() -> void:
	if mode == "inspection":
		for weapon in [1,0]:
			app.player.set_physics_process(false)
			app.player.equip(weapon)
			app.player._advance_reload(.04)
			app.player._update_view(.04)
			assert(app.player.reload_cycle.view.motion == 2)
			await sample("switch-%d-lower"%weapon,0.0)
			app.player._advance_reload(.23)
			app.player._update_view(.23)
			assert(app.player.reload_cycle.view.motion == 4)
			await sample("switch-%d-raise"%weapon,0.0)
			app.player._advance_reload(.04)
			app.player._update_view(.04)
			app.player.set_physics_process(true)
			await ready_weapon(weapon)
	for weapon in [0,1]:
		stage = "selection-%d"%weapon
		await ready_weapon(weapon)
		await sample("%d-rest"%weapon,.35)
		Input.action_press("forward")
		await sample("%d-walk"%weapon,.45)
		Input.action_press("sprint")
		await sample("%d-sprint"%weapon,.45)
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(22,-8)
		motion.screen_relative = Vector2(22,-8)
		app.player._unhandled_input(motion)
		await sample("%d-look"%weapon,.035)
		assert(app.player.fire())
		await sample("%d-urgent-sprint"%weapon,.05)
		Input.action_release("forward")
		Input.action_release("sprint")
		await sample("%d-stop"%weapon,.2)
		Input.action_press("aim")
		await sample("%d-aim"%weapon,.4)
		assert(app.player.fire())
		await sample("%d-fire"%weapon,.035)
		Input.action_release("aim")
		await wait(.6)
		app.player.teleport(Vector3(0,0,7))
	stage = "d9-selection"
	await ready_weapon(0)
	app.state.ammo = 5
	app.state.reserve = 40
	assert(app.player.reload_weapon())
	await sample("d9-partial",.8)
	await sample("d9-partial-return",2.0,false)
	assert(app.state.ammo == 12 and app.state.reserve == 33)
	app.state.ammo = 0
	assert(app.player.reload_weapon())
	await sample("d9-empty",2.4)
	await sample("d9-empty-return",1.0,false)
	assert(app.state.ammo == 12 and app.state.reserve == 21)
	stage = "arc-selection"
	await ready_weapon(1)
	app.state.energy = 10
	app.state.cells = 4
	assert(app.player.reload_weapon())
	await sample("arc-cell",1.1)
	await sample("arc-cell-return",2.1,false)
	assert(app.state.energy == 70 and app.state.cells == 3)
	stage = "rapid-selection"
	for index in [0,1,0,1,0]:
		app.player.equip(index)
		await wait(.07)
	await ready_weapon(0)
	app.state.energy = 10
	assert(app.player.request_cell())
	await sample("b-from-d9",.8)
	await sample("b-return",3.4,false)
	assert(app.player.reload_cycle.ready and app.player.weapon_index == 0 and app.state.energy == 70 and app.state.cells == 2)
	await sample("final-ready",.4)
