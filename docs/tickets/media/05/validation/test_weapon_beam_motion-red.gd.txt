extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for action in ["forward","back","left","right","sprint","jump","crouch","fire","aim"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200,1,200)
	shape.shape = box
	floor_body.add_child(shape)
	root.add_child(floor_body)
	floor_body.position.y = -.5
	var player := Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_active(true)
	player.equip(1)
	for tick in 100:
		await physics_frame
		if player.reload_cycle.ready and player.weapon_index == 1: break
	assert(player.reload_cycle.ready and player.weapon_index == 1)
	Input.action_press("forward")
	Input.action_press("sprint")
	for tick in 30: await physics_frame
	assert(Vector2(player.get_real_velocity().x,player.get_real_velocity().z).length() > 6)
	assert(player.fire())
	var hit := player._beam.to_global(Vector3(0,0,-.5))
	var origin := player.global_position
	for tick in 3: await physics_frame
	var endpoint := player._beam.to_global(Vector3(0,0,.5))
	var error := endpoint.distance_to(player.rig.muzzle.global_position)
	var attached: bool = player._beam.visible and error < .0001
	var unchanged: bool = hit.distance_to(player._beam.to_global(Vector3(0,0,-.5))) < .0001 and player.state.energy == 88 and player.state.ammo == 12
	assert(player.global_position.distance_to(origin) > .1)
	print("PASS: active ARC beam follows moving muzzle" if attached else "FAIL: active ARC beam leaves moving muzzle", " error_m=",error)
	print("PASS: moving beam preserves original impact and shot resources" if unchanged else "FAIL: moving beam changes impact or resources")
	Input.action_release("forward")
	Input.action_release("sprint")
	player._audio.stop()
	player._audio.stream = null
	await create_timer(.2).timeout
	player.free()
	floor_body.free()
	await create_timer(.2).timeout
	quit(0 if attached and unchanged else 1)
