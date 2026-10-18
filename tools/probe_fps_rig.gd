extends SceneTree

var app: Node
var output := "res://.cstack/issue-02"
var cost_mode := false
var inspection_mode := false
var rig: Node3D
var frame: RefCounted

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proof-output="):
			output = argument.trim_prefix("--proof-output=")
		if argument == "--rig-inspection":
			inspection_mode = true
		if argument == "--rig-cost":
			cost_mode = true
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1280,720)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_game()
	app.set_quality(false)
	app.player.teleport(Vector3(0,0,7))
	rig = app.player.get("rig")
	if rig != null:
		frame = load("res://scripts/fps_rig.gd").ViewFrame.new()
	if inspection_mode:
		await inspect()
	elif cost_mode:
		await measure()
	else:
		await demonstrate()
	app.player.set_active(false)
	app.queue_free()
	await process_frame
	quit()

func wait(seconds: float) -> void:
	var until := Time.get_ticks_usec()+int(seconds*1000000)
	while Time.get_ticks_usec()<until:
		await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	print("CAPTURE ",label," position=",app.player.position," ammo=",app.state.ammo," reserve=",app.state.reserve," energy=",app.state.energy)

func demonstrate() -> void:
	await wait(1.0)
	for weapon in 2:
		app.player.teleport(Vector3(0,0,7))
		app.player.equip(weapon)
		await wait(.6)
		await capture("weapon%d-rest"%weapon)
		Input.action_press("forward")
		await wait(.6)
		await capture("weapon%d-walk"%weapon)
		Input.action_press("sprint")
		await wait(.45)
		await capture("weapon%d-run"%weapon)
		Input.action_release("sprint")
		Input.action_release("forward")
		Input.action_press("aim")
		await wait(.7)
		await capture("weapon%d-aim"%weapon)
		var ammo_before: int = app.state.ammo
		var energy_before: float = app.state.energy
		var fired: bool = app.player.fire()
		assert(fired, "real player fire accepted")
		assert(app.state.ammo == ammo_before-1 if weapon == 0 else app.state.energy == energy_before-12, "real shot consumed configured resource")
		print("FIRE accepted=",fired)
		await capture("weapon%d-fire"%weapon)
		await wait(.5)
		Input.action_release("aim")
		var accepted: bool = app.player.reload_weapon()
		assert(accepted, "D9 and ARC accept their timed reload after firing")
		print("RELOAD weapon=",weapon," accepted=",accepted)
		await wait(.65)
		await capture("weapon%d-reload"%weapon)
		await wait(app.player.D9.reload_duration)
		for change in 6:
			app.player.equip(change%2)
			await wait(.07)
		await wait(.5)
		await capture("weapon%d-switches"%weapon)
	app.player.equip(0)
	app.player.teleport(Vector3(2,0,-18))
	await wait(.4)
	await capture("dark-d9")
	app.player.equip(1)
	await wait(.4)
	await capture("dark-arc")

func measure() -> void:
	app.player.set_active(false)
	var records: Array[Dictionary] = []
	for weapon in 2:
		await prepare_weapon(weapon)
		if rig != null:
			rig.reset_pose()
		var visibility_modes := [true,false] if rig != null else [true]
		for visible: bool in visibility_modes:
			if rig != null:
				rig.arms.visible = visible
			await wait(1.0)
			var samples: Array[float] = []
			var cpu_samples: Array[float] = []
			var until := Time.get_ticks_usec()+2000000
			var previous := Time.get_ticks_usec()
			while Time.get_ticks_usec()<until:
				if rig != null:
					var begin := Time.get_ticks_usec()
					rig.update_visual(1.0/60.0,frame)
					cpu_samples.append(float(Time.get_ticks_usec()-begin)/1000.0)
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				samples.append(float(now-previous)/1000.0)
				previous = now
				await process_frame
			samples.sort()
			cpu_samples.sort()
			var record := {"weapon":weapon,"hands_visible":visible,"samples":samples.size(),"frame_p50_ms":samples[samples.size()/2],"frame_p95_ms":samples[int(samples.size()*.95)],"rig_update_call_p50_ms":cpu_samples[cpu_samples.size()/2] if not cpu_samples.is_empty() else 0.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"health":app.state.health}
			records.append(record)
			await capture("cost-weapon%d-"%weapon + ("visible" if visible else "hidden"))
	assert(app.state.health > 0, "cost scene stays alive")
	var result := {"backend":RenderingServer.get_video_adapter_name(),"resolution":"1280x720","godot":Engine.get_version_info().string,"rig_present":rig!=null,"records":records}
	var file := FileAccess.open(output+"/cost.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("COST ",JSON.stringify(result))

func inspect() -> void:
	app.player.set_active(false)
	app.ui.visible = false
	for weapon in 2:
		await prepare_weapon(weapon)
		rig.reset_pose()
		for angle in 3:
			rig.rotation.y = [0.0,-.65,.65][angle]
			rig.position = [Vector3(0,.09,-.05),Vector3(-.28,.09,0),Vector3(.28,.09,-.1)][angle]
			await wait(.3)
			await capture("inspection-%d-%d"%[weapon,angle])

func prepare_weapon(index: int) -> void:
	app.player.set_active(true)
	app.player.equip(index)
	for tick in 120:
		if app.player.reload_cycle.ready and app.player.weapon_index == index: break
		await physics_frame
	assert(app.player.reload_cycle.ready and app.player.weapon_index == index)
	app.player.set_active(false)
