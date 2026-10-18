extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
const Ready = preload("res://tests/weapon_ready.gd")
var failures := 0
var player: Player

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func release_player() -> void:
	if not is_instance_valid(player): return
	for stream in [player._audio, player._manipulation_audio, player._scan_audio]:
		stream.stop()
		stream.stream = null
	player.free()

func reset() -> void:
	Input.action_release("fire")
	release_player()
	player = Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)

func click(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	if pressed: Input.action_press("fire")
	else: Input.action_release("fire")
	player._unhandled_input(event)

func step(delta: float) -> void:
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player._physics_process(delta)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("DISPLAY REQUIRED: run with X11 and --rendering-driver dummy to exercise captured mouse input")
		quit(2)
		return
	for action in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "fire", "aim", "weapon1", "weapon2", "reload", "scan", "interact"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	for weapon in [0, 1]:
		reset()
		player.equip(weapon)
		check(Ready.wait_for(player, weapon), "click fixture reaches final READY")
		click(true)
		click(false)
		check(player.state.ammo == (11 if weapon == 0 else 12) and player.state.energy == (88 if weapon == 1 else 100), "short READY click spends exactly one shot before physics for weapon %d" % weapon)
		var after_click := Vector2(player.state.ammo, player.state.energy)
		step(.01)
		check(Vector2(player.state.ammo, player.state.energy) == after_click, "released short click cannot be replayed by physics")
		reset()
		player.equip(weapon)
		check(Ready.wait_for(player, weapon), "held fixture reaches final READY")
		click(true)
		step(.01)
		check(player.state.ammo == (11 if weapon == 0 else 12) and player.state.energy == (88 if weapon == 1 else 100), "input plus held physics path spends only once inside cooldown")
		step(player._weapon().cooldown + .01)
		check(player.state.ammo == (10 if weapon == 0 else 12) and player.state.energy == (76 if weapon == 1 else 100), "held trigger repeats when cooldown expires")
		click(false)
	reset()
	click(true)
	check(player.state.ammo == 11, "READY press fires synchronously before a long tick")
	step(.30)
	check(player.state.ammo == 11, "first long tick cannot spend time from before the input to duplicate shot")
	step(Player.D9.cooldown + .01)
	check(player.state.ammo == 10, "later elapsed cooldown allows held second shot")
	click(false)
	reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	click(true)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and player.state.ammo == 12, "capture click only recaptures cursor")
	step(.02)
	step(.5)
	check(player.state.ammo == 12, "same capture click remains suppressed through held physics until release")
	click(false)
	step(Player.D9.cooldown + .01)
	var before_fresh := player.state.ammo
	click(true)
	click(false)
	check(player.state.ammo == before_fresh - 1, "fresh click after capture release fires normally")
	for manipulation in ["switch", "reload"]:
		reset()
		player.state.ammo = 4
		if manipulation == "switch": player.equip(1)
		else: check(player.reload_weapon(), "refused click fixture begins reload")
		click(true)
		click(false)
		check(player.state.ammo == 4 and player.state.energy == 100, manipulation + " refuses short click without debit")
		for tick in 400: step(.01)
		check(player.state.energy == 100 and player.state.ammo == (4 if manipulation == "switch" else 12), manipulation + " refused click is not queued for READY")
	reset()
	player.equip(1)
	step(.17)
	player.equip(0)
	click(true)
	step(.14)
	check(player.state.ammo == 12 and player.state.energy == 100, "held fire cannot use intermediate READY during reversed change")
	for tick in 40:
		step(.01)
		if player.state.ammo < 12: break
	check(player.reload_cycle.ready and player.weapon_index == 0 and player.state.ammo == 11 and player.state.energy == 100, "held fire retries at first final READY with final weapon")
	click(false)
	reset()
	click(true)
	step(.01)
	player.set_active(true)
	step(Player.D9.cooldown + .01)
	check(player.state.ammo == 10, "repeated activation preserves an already active held trigger")
	click(false)
	reset()
	click(true)
	var before_inactive := player.state.ammo
	player.set_active(false)
	player.set_active(true)
	step(.5)
	check(player.state.ammo == before_inactive, "reactivation cannot replay a held pre-deactivation click")
	click(false)
	for stream in [player._audio, player._manipulation_audio, player._scan_audio]:
		stream.stop()
		stream.stream = null
	await create_timer(.2).timeout
	release_player()
	await create_timer(.3).timeout
	print("WEAPON INPUT FAILURES: ", failures)
	quit(1 if failures else 0)
