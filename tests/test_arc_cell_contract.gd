extends SceneTree
const Ready = preload("res://tests/weapon_ready.gd")

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
var player: Player
var state: State
var transfer_seconds := 0.0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func reset(energy: float = 40.0, cells: int = 2, upgraded: bool = false) -> void:
	if is_instance_valid(player): player.free()
	state = State.new()
	state.energy = energy
	state.cells = cells
	state.upgraded = upgraded
	player = Player.new()
	player.setup(state)
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)
	player.equip(1)
	check(Ready.wait_for(player, 1), "ARC fixture reaches final READY before service")
	step(.016)

func step(delta: float) -> void:
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	var health := state.health
	player._physics_process(delta)
	if state.health != health: check(false, "physics fixture preserves health")

func finish() -> void:
	for tick in 80:
		step(.1)

func reach_transfer() -> bool:
	var cells := state.cells
	transfer_seconds = 0.0
	for tick in 800:
		step(.01)
		transfer_seconds += .01
		if state.cells < cells: return true
	return false

func run() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.position.y = -.5
	floor_body.add_child(shape)
	root.add_child(floor_body)
	await physics_frame
	for action in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "fire", "aim"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	for energy in [0.0, 10.0, 15.0, 40.0, 99.0, 149.0]:
		reset(energy, 1, energy > 100)
		var accepted := player.reload_weapon()
		check(accepted, "R ARC accepts energy %.0f with one cell" % energy)
		check(state.energy == energy and state.cells == 1, "R request cannot debit before visible manipulation")
		player._shot_time = 0.0
		check(not player.fire() and state.energy == energy, "ARC manipulation blocks fire with zero cooldown")
		finish()
		check(state.cells == 0 and state.energy == minf(energy + 60.0, state.max_energy()), "cell grants 60 capped at current capacity exactly once")
		check(player.weapon_index == 1 and player.rig.weapon_index == 1, "R ARC remains on ARC")
		var charged := state.energy
		player._shot_time = 0.0
		check(player.fire() and state.energy == charged - 12.0, "ready ARC fires using the common battery")
	for energy in [0.0, 10.0, 15.0, 40.0]:
		reset(energy)
		check(player.fire() == (energy >= 12.0), "ARC availability follows common energy %.0f" % energy)
		check(state.energy == energy - (12.0 if energy >= 12 else 0.0), "ARC spends exactly 12 or nothing")
		reset(energy)
		check(player.activate_scan() == (energy >= 20.0), "SCAN availability follows common energy %.0f" % energy)
		check(state.energy == energy - (20.0 if energy >= 20 else 0.0), "SCAN spends exactly 20 or nothing")
	for reason in ["full", "empty", "dead", "inactive"]:
		reset()
		match reason:
			"full": state.energy = 100.0
			"empty": state.cells = 0
			"dead": state.health = 0.0
			"inactive": player.active = false
		var before := Vector2(state.energy, state.cells)
		check(not player.reload_weapon(), reason + " rejects R using current health/activity")
		finish()
		check(Vector2(state.energy, state.cells) == before, reason + " rejection cannot spend or queue a cell")
	reset(40.0, 2)
	check(player.reload_weapon(), "scan coexistence starts an ARC manipulation")
	check(player.activate_scan() and state.energy == 20.0, "SCAN remains available before transfer")
	check(reach_transfer(), "ARC reaches a bounded transfer milestone")
	check(state.energy == 80.0 and state.cells == 1, "transfer uses the energy left by earlier SCAN")
	player._shot_time = 0.0
	check(not player.fire() and state.energy == 80.0, "latch transfer still blocks fire until the hand returns")
	player._scan_time = 0.0
	check(player.activate_scan() and state.energy == 60.0, "SCAN after transfer spends the newly charged balance")
	finish()
	check(state.energy == 60.0 and state.cells == 1, "scan cannot cause double consumption")
	var milestone := transfer_seconds
	reset(40.0, 1)
	check(player.reload_weapon(), "boundary scan scenario starts ARC manipulation")
	for tick in maxi(0, roundi(milestone / .01) - 1): step(.01)
	check(state.cells == 1 and state.energy == 40.0, "last sampled tick before transfer has no early gain")
	check(player.activate_scan() and state.energy == 20.0, "SCAN input immediately before transfer uses old balance")
	step(.01)
	check(state.cells == 0 and state.energy == 80.0, "next tick transfers against the post-SCAN balance")
	reset(15.0, 1)
	check(player.reload_weapon(), "low-energy scan scenario starts ARC manipulation")
	check(not player.activate_scan() and state.energy == 15.0, "insufficient SCAN during manipulation cannot go negative")
	finish()
	check(state.energy == 75.0 and state.cells == 0, "refused SCAN leaves the cell transfer intact")
	for mutation in ["stock", "refuge", "capacity", "inactive", "dead"]:
		reset(40.0, 1)
		check(player.reload_weapon(), mutation + " scenario starts before mutation")
		step(.01)
		match mutation:
			"stock": state.cells = 0
			"refuge": state.recharge()
			"capacity":
				state.upgraded = true
				state.energy = 120.0
			"inactive": player.active = false
			"dead": state.health = 0.0
		finish()
		match mutation:
			"capacity": check(state.energy == 150.0 and state.cells == 0, "transfer revalidates upgraded capacity")
			"refuge": check(state.energy == 100.0 and state.cells == 1, "refuge fill makes pending transfer free of cell consumption")
			"stock": check(state.energy == 40.0 and state.cells == 0, "stock removed before milestone cannot create energy")
			_: check(state.energy == 40.0 and state.cells == 1, "current " + mutation + " prevents economic milestone")
	for interruption in ["equip", "teleport", "inactive", "death"]:
		for after_transfer in [false, true]:
			reset(10.0, 2)
			check(player.reload_weapon(), interruption + " scenario starts")
			if after_transfer: check(reach_transfer(), "interruption after transfer reaches milestone")
			else: step(.01)
			match interruption:
				"equip": player.equip(0)
				"teleport": player.teleport(Vector3.ZERO)
				"inactive": player.set_active(false)
				"death": player.apply_damage(100.0)
			finish()
			check(state.energy == (70.0 if after_transfer else 10.0) and state.cells == (1 if after_transfer else 2), interruption + " preserves committed resources only")
	reset(10.0, 3)
	check(player.reload_weapon(), "large delta scenario starts")
	check(not player.reload_weapon(), "repeated R is rejected while service is active")
	step(100.0)
	check(state.energy == 70.0 and state.cells == 2, "large delta crosses transfer exactly once")
	step(100.0)
	check(state.energy == 70.0 and state.cells == 2, "later large delta cannot duplicate transfer")
	player._shot_time = 0.0
	check(player.fire() and state.energy == 58.0, "large delta finishes visual return before allowing fire")
	reset(10.0, 1)
	check(player.reload_weapon(), "mechanical milestone scenario starts")
	var arc: Node3D = player.rig._weapons[1]
	var cell := arc.get_node_or_null("ArcCell") as Node3D
	var latch := arc.get_node_or_null("ArcLatch") as Node3D
	var socket := arc.get_node_or_null("ArcSocket") as Node3D
	check(cell != null and latch != null and socket != null, "ARC exposes distinct cell, latch and socket")
	if cell != null and latch != null and socket != null:
		check(cell.get_node_or_null("CellGrip") is Marker3D and latch.get_node_or_null("LatchGrip") is Marker3D, "moving ARC pieces own their grip markers")
		var closed := latch.transform
		var seated := cell.transform
		var extracted := false
		var unlocked := false
		for tick in 800:
			step(.01)
			extracted = extracted or not cell.transform.is_equal_approx(seated)
			unlocked = unlocked or not latch.transform.is_equal_approx(closed)
			if state.cells == 0: break
		check(extracted and unlocked, "cell and latch visibly move before transfer")
		check(state.cells == 0 and latch.transform.is_equal_approx(closed), "economic transfer occurs only with latch fully closed")
		finish()
		check(cell.transform.is_equal_approx(seated), "ready ARC has its cell seated")
	player.free()
	floor_body.queue_free()
	await create_timer(.4).timeout
	print("ARC CELL CONTRACT FAILURES: ", failures)
	quit(1 if failures else 0)
