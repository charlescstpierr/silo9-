extends SceneTree
const Handling = preload("res://scripts/weapon_handling.gd")
var app: Node
var output := "res://.cstack/issue-04/proof"
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
	app.player.equip(1)
	await ready_weapon(1)
	caption = Label.new()
	caption.position = Vector2(32,110)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_outline_color",Color.BLACK)
	caption.add_theme_constant_override("outline_size",6)
	app.ui.add_child(caption)
	app.player.reload_event.connect(log_event)
	if mode in ["inspection","fps"]: await inspect()
	else: await film()
	app.queue_free()
	await process_frame
	await create_timer(.4).timeout
	quit()
func _process(_delta: float) -> bool:
	if caption != null and is_instance_valid(app.player):
		var view: Handling.View = app.player.reload_cycle.view
		caption.text = "ARC / %s\n%s · %s | énergie %d · cellules %d\n%s" % [scenario,Handling.Motion.keys()[view.motion],Handling.Gesture.keys()[view.gesture],app.state.energy,app.state.cells,"Capture déterministe du moteur · pas une mesure de fluidité" if mode == "film" else "Inspection moteur"]
	return false
func log_event(event: int) -> void:
	events.append({"frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"event":event,"scenario":scenario,"energy":app.state.energy,"cells":app.state.cells})
func wait(seconds: float) -> void:
	await create_timer(seconds).timeout
func film() -> void:
	AudioServer.add_bus_effect(0,recorder)
	start_frame = Engine.get_process_frames()
	recorder.set_recording_active(true)
	await wait(.5)
	scenario = "TIR → CELLULE → TIR"
	app.state.energy = 40
	app.state.cells = 4
	assert(app.player.fire())
	await wait(.65)
	assert(app.player.reload_weapon())
	await wait(3.4)
	assert(app.state.energy == 88 and app.state.cells == 3)
	assert(app.player.fire())
	await wait(.7)
	scenario = "B DEPUIS D9 · RETOUR AUTOMATIQUE"
	app.player.equip(0)
	app.state.energy = 10
	assert(app.player.request_cell())
	await wait(4.0)
	assert(app.player.weapon_index == 0 and app.state.energy == 70 and app.state.cells == 2)
	scenario = "SCAN AVANT VERROU · BATTERIE COMMUNE"
	app.player.equip(1)
	await ready_weapon(1)
	app.state.energy = 40
	assert(app.player.reload_weapon())
	await wait(1.2)
	assert(app.player.activate_scan())
	await wait(2.2)
	assert(app.state.energy == 80 and app.state.cells == 1)
	scenario = "ANNULATION · AUCUNE CELLULE DÉBITÉE"
	assert(app.player.reload_weapon())
	await wait(.9)
	app.player.equip(0)
	await wait(.6)
	assert(app.state.energy == 80 and app.state.cells == 1)
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
	for angle in ([0] if mode == "fps" else [0,1,2]):
		rig.rotation.y = [0.0,-.65,.65][angle]
		rig.position = [Vector3.ZERO,Vector3(-.28,.04,0),Vector3(.28,.04,-.1)][angle]
		for sample: Array in [["rest",0.0],["unlock",.45],["extracted",1.08],["pocket",1.41],["insert",2.0],["lock",2.5],["transferred",2.67]]:
			app.player.reload_cycle = Handling.new()
			app.player.setup(app.state)
			app.player._view_frame.reload = app.player.reload_cycle.view
			rig.reset_pose()
			app.player.equip(1)
			for tick in 100:
				if app.player.reload_cycle.ready and app.player.weapon_index == 1: break
				app.player._advance_reload(.01)
				app.player._update_view(.01)
			assert(app.player.reload_cycle.ready and app.player.weapon_index == 1)
			app.state.energy = 10
			app.state.cells = 2
			if sample[1] > 0:
				assert(app.player.reload_weapon())
			app.player._physics_process(sample[1])
			assert(rig.calibration_valid)
			await capture("%d-%s"%[angle,sample[0]])

func ready_weapon(index: int) -> void:
	for tick in 120:
		if app.player.reload_cycle.ready and app.player.weapon_index == index: return
		await physics_frame
	assert(false, "selection did not reach final READY")
