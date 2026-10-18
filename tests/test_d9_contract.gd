extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
const REMOVE := 1
const INSERT := 2
const PULL := 4
const RELEASE := 8
const COMMIT := 16
const HIDDEN := 32
var failures := 0
var events: Array[int] = []
var player: Player
var state: State

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func step(delta: float) -> void:
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	var was_alive := state.health > 0.0
	player._physics_process(delta)
	check(not was_alive or state.health == 100.0,"harness step cannot kill player by falling")

func reset(ammo: int, reserve: int) -> void:
	if player != null:
		player.free()
	state = State.new()
	state.ammo = ammo
	state.reserve = reserve
	player = Player.new()
	player.setup(state)
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)
	events.clear()
	if player.has_signal("reload_event"):
		player.connect("reload_event",func(event: int) -> void: events.append(event))

func run() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = Vector3(100,1,100)
	shape.shape = geometry
	floor_body.position.y = -.5
	floor_body.add_child(shape)
	root.add_child(floor_body)
	await physics_frame
	for action in ["forward","back","left","right","sprint","jump","crouch","fire","aim"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	reset(0,15)
	check(player.reload_weapon(),"empty reload accepted")
	step(Player.D9.reload_duration+.001)
	check(player.reloading and state.ammo == 0 and state.reserve == 15,"empty reload must still rearm when partial duration ends")
	player._shot_time = 0.0
	check(not player.fire() and state.ammo == 0,"empty weapon cannot fire before rearm and return")
	reset(0,15)
	player.reload_weapon()
	step(10.0)
	check(state.ammo == 12 and state.reserve == 3,"empty transfer occurs once at end")
	check(events == [REMOVE,INSERT,PULL,RELEASE,COMMIT],"empty cues ordered, release before commit")
	step(1.0)
	check(events.count(COMMIT) == 1,"empty commit never repeats")
	reset(4,3)
	player.reload_weapon()
	step(Player.D9.reload_duration-.001)
	check(state.ammo == 4 and state.reserve == 3,"short reserve does not transfer early")
	check(not player.fire(),"partial reload blocks firing until return")
	step(.002)
	check(state.ammo == 7 and state.reserve == 0,"short reserve transfers only available rounds")
	check(events == [REMOVE,INSERT,COMMIT],"partial sequence omits rack cues")
	reset(3,17)
	player.reload_weapon()
	step(.5)
	player.equip(1)
	player._shot_time = 0.0
	check(not player.fire() and state.energy == 100.0,"interrupted switch blocks fire without cooldown masking")
	step(.17)
	player._shot_time = 0.0
	check(not player.fire() and state.energy == 100.0,"raise blocks fire without cooldown masking")
	player.equip(0)
	step(.13)
	check(not player.fire(),"new destination during raise stays blocked")
	step(.31)
	check(player.weapon_index == 0 and player.rig.weapon_index == 0,"pending switch consumes large delta without losing destination")
	check(state.ammo == 3 and state.reserve == 17 and not events.has(COMMIT),"interrupted switch never commits")
	for interrupt in ["inactive","teleport","death"]:
		reset(5,12)
		player.reload_weapon()
		step(Player.D9.reload_duration*.8)
		match interrupt:
			"inactive": player.set_active(false)
			"teleport": player.teleport(Vector3.ZERO)
			"death": player.apply_damage(100)
		var audio: AudioStreamPlayer = player.get("_manipulation_audio")
		check(audio != null and not audio.playing,interrupt+" stops dedicated manipulation audio")
		step(.8)
		check(state.ammo == 5 and state.reserve == 12 and not events.has(COMMIT),interrupt+" conserves resources after insertion")
	reset(7,13)
	player.reload_weapon()
	step(.5)
	var magazine: Node3D = player.rig._weapons[0].get_node("Magazine")
	var seat: Marker3D = player.rig._weapons[0].get_node("MagazineSeat")
	check(not magazine.position.is_equal_approx(seat.position),"extraction moves the visible magazine before large tick")
	step(Player.D9.reload_duration)
	check(magazine.position.is_equal_approx(seat.position),"large completion tick restores visible magazine before firing")
	reset(7,13)
	player.reload_weapon()
	step(.5)
	player.equip(0)
	check(player.reloading,"same-weapon request alone keeps reload")
	player.equip(1)
	player.equip(0)
	step(.5)
	check(player.weapon_index == 0 and player.rig.weapon_index == 0,"last request back to current weapon cancels pending ARC")
	check(state.ammo == 7 and state.reserve == 13,"return-to-D9 cancellation never commits")
	reset(7,13)
	player.reload_weapon()
	step(100)
	check(state.ammo == 12 and state.reserve == 8,"large reload delta commits once")
	check(events == [REMOVE,INSERT,COMMIT],"large delta retains canonical event order")
	var audio: AudioStreamPlayer = player.get("_manipulation_audio")
	check(audio != null and not audio.playing,"large delta does not play obsolete cues")
	player.free()
	await process_frame
	floor_body.queue_free()
	await create_timer(.4).timeout
	print("D9 CONTRACT FAILURES: ",failures)
	quit(1 if failures else 0)
