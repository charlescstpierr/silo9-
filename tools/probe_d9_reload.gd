extends SceneTree

const Reload = preload("res://scripts/weapon_handling.gd")
var app: Node
var output := "res://.cstack/issue-03/proof"
var mode := "film"
var caption: Label
var scenario := "PRÊT"
var recorder := AudioEffectRecord.new()
var events: Array[Dictionary] = []
var start_frame := 0

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
	await wait(.5)
	app.new_game()
	app.set_quality(false)
	app.player.teleport(Vector3(0,0,7))
	caption = Label.new()
	caption.position = Vector2(32,110)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_outline_color",Color.BLACK)
	caption.add_theme_constant_override("outline_size",6)
	app.ui.add_child(caption)
	app.player.reload_event.connect(log_event)
	if mode == "inspection":
		await inspect()
	else:
		await film()
	app.queue_free()
	await process_frame
	await create_timer(.4).timeout
	quit()

func _process(_delta: float) -> bool:
	if caption != null and is_instance_valid(app.player):
		var view: Reload.View = app.player.reload_cycle.view
		caption.position.y = 535 if paused else 110
		caption.text = "D9  /  %s\n%s · %s  |  %d / 12 · réserve %d\n%s" % [scenario,Reload.Motion.keys()[view.motion],Reload.Gesture.keys()[view.gesture],app.state.ammo,app.state.reserve,"Capture déterministe du moteur · pas une mesure de fluidité" if mode == "film" else "Inspection moteur"]
	return false

func log_event(event: int) -> void:
	events.append({"frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"event":event,"scenario":scenario,"ammo":app.state.ammo,"reserve":app.state.reserve})

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func press_reload() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key.pressed = false
	Input.parse_input_event(key)

func film() -> void:
	AudioServer.add_bus_effect(0,recorder)
	start_frame = Engine.get_process_frames()
	recorder.set_recording_active(true)
	await wait(.8)
	scenario = "PARTIEL · 5 balles"
	app.state.ammo = 5
	app.state.reserve = 19
	await press_reload()
	await wait(app.player.D9.reload_duration+.6)
	assert(app.state.ammo == 12 and app.state.reserve == 12)
	scenario = "VIDE · réarmement nécessaire"
	app.state.ammo = 0
	app.state.reserve = 24
	await press_reload()
	await wait(app.player.D9.reload_empty_duration+.6)
	assert(app.state.ammo == 12 and app.state.reserve == 12)
	scenario = "INTERROMPU · changement d’arme"
	app.state.ammo = 5
	app.state.reserve = 19
	await press_reload()
	await wait(.9)
	app.player.equip(1)
	await wait(.65)
	assert(app.state.ammo == 5 and app.state.reserve == 19)
	app.player.equip(0)
	for tick in 120:
		if app.player.reload_cycle.ready and app.player.weapon_index == 0: break
		await physics_frame
	assert(app.player.reload_cycle.ready and app.player.weapon_index == 0)
	scenario = "INTERROMPU APRÈS INSERTION · pause"
	app.state.ammo = 0
	await press_reload()
	await wait(app.player.D9.reload_duration*.8)
	app.open_pause()
	await wait(.8)
	app.resume_game()
	await wait(.6)
	assert(app.state.ammo == 0 and app.state.reserve == 19)
	scenario = "REPRISE · aucune balle créée par annulation"
	await press_reload()
	await wait(app.player.D9.reload_empty_duration+.6)
	assert(app.state.ammo == 12 and app.state.reserve == 7)
	recorder.set_recording_active(false)
	var wave := recorder.get_recording()
	wave.save_to_wav(output+"/mixer.wav")
	var file := FileAccess.open(output+"/events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"recorder_start_frame":start_frame,"end_frame":Engine.get_process_frames(),"capture_fps":30,"events":events,"mixer_bytes":wave.data.size(),"mixer_rate":wave.mix_rate},"\t"))
	print("FILM events=",events.size()," mixer_bytes=",wave.data.size())

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	print("CAPTURE ",label)

func inspect() -> void:
	app.player.set_physics_process(false)
	app.ui.visible = false
	var rig: Node3D = app.player.rig
	for angle in [0,1,2]:
		rig.rotation.y = [0.0,-.65,.65][angle]
		rig.position = [Vector3.ZERO,Vector3(-.28,.09,0),Vector3(.28,.09,-.1)][angle]
		for sample: Array in [["rest",0.0],["grasp",.338],["extracted",.728],["pocket",1.144],["insertion",1.9],["slide-grasp",2.262],["slide-pulled",2.457],["return",2.85]]:
			app.player.reload_cycle = Reload.new()
			app.player.reload_cycle.state = app.state
			app.player._view_frame.reload = app.player.reload_cycle.view
			rig.reset_pose()
			app.state.ammo = 0
			app.state.reserve = 24
			app.player.reload_weapon()
			app.player._physics_process(sample[1])
			assert(rig.calibration_valid)
			await capture("%d-%s"%[angle,sample[0]])
