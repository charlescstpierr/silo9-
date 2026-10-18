extends SceneTree
const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
class SoundPlayer extends SiloPlayer:
	var played: Array[String] = []
	func _play(kind: String) -> void:
		played.append(kind)
var failures := 0
func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for action in ["forward","back","left","right","sprint","jump","crouch","fire","aim"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var player := SoundPlayer.new()
	var state := State.new()
	player.setup(state)
	root.add_child(player)
	player.set_physics_process(false)
	await process_frame
	player.set_active(true)
	var gun: Node3D = player.rig._weapons[0]
	for part in ["Magazine","SpareMagazine","Slide","MagazineGrip","RackGrip"]:
		check(gun.get_node_or_null(part) != null,"physical reload part " + part)
	state.ammo = 0
	state.reserve = 5
	var committed_pose: Array[float] = []
	var previous_ammo := [state.ammo]
	var on_changed := func():
		if state.ammo != previous_ammo[0]:
			committed_pose.append(player.rig._frame.reload_progress)
			previous_ammo[0] = state.ammo
	state.changed.connect(on_changed)
	check(player.reload_weapon(),"empty reload accepted")
	player._physics_process(player.D9.reload_duration * .99)
	check(state.ammo == 0 and state.reserve == 5 and not player.fire(),"no ammo or firing before mechanical completion")
	player._physics_process(player.D9.reload_duration * 3)
	check(state.ammo == 5 and state.reserve == 0 and not player.reloading,"long frame commits exact limited reserve")
	check(committed_pose.size() == 1 and is_equal_approx(committed_pose[0],1.0),"ammo commit samples final mechanical pose")
	player._physics_process(1.0)
	check(committed_pose.size() == 1,"completion cannot commit twice")
	for interruption in ["equip","teleport","pause","death"]:
		state.health = 100
		state.ammo = 3
		state.reserve = 20
		player.set_active(true)
		player.equip(0)
		check(player.reload_weapon(),interruption + " reload starts")
		player._physics_process(player.D9.reload_duration * .65)
		match interruption:
			"equip": player.equip(1)
			"teleport": player.teleport(Vector3.ZERO)
			"pause": player.set_active(false)
			"death": player.apply_damage(100)
		player._physics_process(player.D9.reload_duration * 2)
		check(state.ammo == 3 and state.reserve == 20 and not player.reloading,interruption + " cancels without delayed ammo")
	for empty in [false,true]:
		state.health = 100
		state.ammo = 0 if empty else 4
		state.reserve = 20
		player.set_active(true)
		player.teleport(Vector3(0,10,0))
		player._physics_process(.4)
		player.equip(0)
		player.played.clear()
		check(player.reload_weapon(),"sound sequence reload starts")
		check(player.played.is_empty(),"reload starts without premature mechanical sound")
		player._physics_process(player.D9.reload_duration * .17)
		check(player.played == ["mag_out"],"withdrawal sound follows magazine grasp")
		player._physics_process(player.D9.reload_duration * .58)
		check(player.played == ["mag_out","mag_in"],"insertion sound follows physical seating")
		player._physics_process(player.D9.reload_duration * .18)
		check(player.played == (["mag_out","mag_in","rack"] if empty else ["mag_out","mag_in"]),"rack sound only on empty reload")
		player._physics_process(player.D9.reload_duration * .10)
		check(player.played.size() == (3 if empty else 2),"completion does not replay mechanical cues")
	state.health = 100
	state.ammo = 2
	state.energy = 100
	player.set_active(true)
	player.teleport(Vector3(0,10,0))
	player._shot_time = 0.0
	player.equip(0)
	check(player.fire(),"D9 shot before energy weapon switch")
	player.equip(1)
	check(player.rig._frame.recoil == 0.0,"D9 recoil cannot trigger ARC energy pulse")
	player._shot_time = 0.0
	var charge: StandardMaterial3D = player.rig._arc_emissive[0]
	var resting_glow := charge.emission_energy_multiplier
	check(player.fire() and charge.emission_energy_multiplier > resting_glow,"accepted ARC shot pulses charge material")
	var glow_after_shot := charge.emission_energy_multiplier
	check(not player.fire() and charge.emission_energy_multiplier == glow_after_shot and state.energy == 88,"rejected ARC shot cannot pulse or spend twice")
	state.changed.disconnect(on_changed)
	player.queue_free()
	await create_timer(.35).timeout
	print("RELOAD FAILURES: ",failures)
	quit(1 if failures else 0)
