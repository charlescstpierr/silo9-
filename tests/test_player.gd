extends SceneTree
const Ready = preload("res://tests/weapon_ready.gd")

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures: int = 0

class Target:
	extends StaticBody3D
	var damage_taken: float = 0.0
	var stun_taken: float = 0.0
	func receive_hit(damage: float, stun: float) -> void:
		damage_taken += damage
		stun_taken = stun

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func box(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	root.add_child(body)
	body.position = pos
	return body

func run() -> void:
	for action: String in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "interact", "fire", "reload", "scan", "weapon1", "weapon2", "aim"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var floor_body := box(Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var player := Player.new()
	var run_state := State.new()
	player.setup(run_state)
	root.add_child(player)
	await process_frame
	check(player.camera != null, "ready creates first-person camera")
	check(player.rig.skeleton.get_bone_count() == 35, "player owns articulated rig")
	check(not player.active and not player.fire(), "inactive player cannot shoot")
	player.equip(1)
	player.set_active(true)
	check(Ready.wait_for(player, 1), "inactive equip destination reaches ARC after activation")
	player.equip(5)
	check(player.weapon_index == 1, "invalid equipment ignored")
	player.equip(0)
	check(Ready.wait_for(player, 0), "D9 fixture reaches final READY")
	player.set_active(true)
	check(player.fire() and run_state.ammo == 11, "D9 shot consumes one round")
	check(player._d9_flash.global_position.distance_to(player.rig.muzzle.global_position) < .0001, "shot flash follows current rig muzzle")
	check(not player.fire() and run_state.ammo == 11, "fire cooldown prevents double consumption")
	var pose_rest := player.rig._weapons[0].global_position
	Input.action_press("aim")
	await ticks(12)
	check(player._view_frame.aim_weight > 0.0 and player.rig._weapons[0].global_position.x < pose_rest.x - .1, "aim input moves both hands and selected weapon")
	Input.action_release("aim")
	check(player.reload_weapon(), "partial magazine accepts reload")
	await ticks(5)
	check(player.rig._frame.reload.motion == player.Reload.Motion.RELOAD, "reload is presented before switch")
	player.equip(1)
	check(player.rig._frame.reload.motion == player.Reload.Motion.LOWER_ABORT, "switch begins continuous cancellation in same tick")
	check(not player.reloading and run_state.ammo == 11, "switch cancels reload without free rounds")
	await create_timer(0.6).timeout
	check(player.fire() and run_state.energy == 88.0, "ARC shot consumes shared energy")
	check(player.activate_scan() and run_state.energy == 68.0, "scan consumes same battery")
	check(not player.activate_scan() and run_state.energy == 68.0, "scanner cooldown prevents repeat emission")
	player.equip(0)
	check(Ready.wait_for(player, 0), "D9 reaches final READY before reload")
	check(player.reload_weapon(), "reload restarts after switch")
	await create_timer(Player.D9.reload_duration + .2).timeout
	check(not player.reloading and run_state.ammo == 12 and run_state.reserve == 47, "reload transfers exact missing rounds after delay")
	player.set_active(false)
	check(not player.fire() and not player.activate_scan(), "inactive actions cannot consume resources")
	player.set_active(true)
	player.teleport(Vector3.ZERO)
	var wall := box(Vector3(0, 1.5, -3), Vector3(4, 3, 0.3))
	await ticks(3)
	Input.action_press("forward")
	await ticks(80)
	Input.action_release("forward")
	check(player.global_position.z > -2.6 and player.global_position.z < -2.0, "physical forward movement stops at wall")
	Input.action_press("jump")
	await ticks(10)
	Input.action_release("jump")
	check(player.global_position.y > 0.5, "jump lifts capsule from floor")
	await ticks(60)
	check(player.is_on_floor() and absf(player.global_position.y) < 0.05, "gravity returns player to floor")
	wall.queue_free()
	await ticks(2)
	player.teleport(Vector3(5, 0, 2))
	var step := box(Vector3(5, 0.125, 0), Vector3(2, 0.25, 1))
	await ticks(3)
	Input.action_press("forward")
	var highest: float = 0.0
	for tick in 60:
		await physics_frame
		highest = maxf(highest, player.global_position.y)
	Input.action_release("forward")
	print("STEP POSITION ", player.global_position, " HEIGHT ", highest)
	check(player.global_position.z < -0.5 and highest >= 0.2, "capsule climbs authored low step")
	step.queue_free()
	player.teleport(Vector3(10, 0, 2))
	Input.action_press("crouch")
	await ticks(20)
	var ceiling := box(Vector3(10, 1.6, 0), Vector3(3, 0.6, 3))
	player.teleport(Vector3(10, 0, 0))
	await ticks(3)
	Input.action_release("crouch")
	await ticks(20)
	check(player.camera.position.y < 1.1, "low ceiling prevents standing into geometry")
	player.teleport(Vector3(10, 0, 3))
	await ticks(20)
	check(player.camera.position.y > 1.5, "standing resumes after leaving ceiling")
	ceiling.queue_free()
	player.teleport(Vector3(0, 0, 4))
	var target := Target.new()
	var target_shape := CollisionShape3D.new()
	var target_box := BoxShape3D.new()
	target_box.size = Vector3(1, 2, 1)
	target_shape.shape = target_box
	target.add_child(target_shape)
	root.add_child(target)
	target.position = Vector3(0, 1, 0)
	await ticks(3)
	player.equip(0)
	check(Ready.wait_for(player, 0), "D9 reaches final READY before damage assertion")
	check(player.fire() and target.damage_taken == 28.0, "D9 hits real collider and applies configured damage")
	await ticks(20)
	player.equip(1)
	check(Ready.wait_for(player, 1), "ARC reaches final READY before damage assertion")
	check(player.fire() and target.damage_taken == 67.0 and target.stun_taken == 2.3, "ARC hits real collider with damage and stun")
	var console := box(Vector3(0, 1.58, 2), Vector3(0.5, 0.5, 0.5))
	console.add_to_group("interactable")
	await ticks(10)
	check(player.aim_target() == console, "aim cache resolves nearby interactable")
	console.queue_free()
	await ticks(10)
	check(player.aim_target() == null, "aim cache clears freed target")
	target.queue_free()
	await ticks(35)
	player.equip(0)
	check(Ready.wait_for(player, 0), "D9 reaches final READY before reload")
	check(player.reload_weapon(), "reload can start before death")
	player.apply_damage(100.0)
	check(not player.active and not player.reloading and not player.fire(), "death cancels reload and blocks fire")
	check(player.reload_cycle.view.motion == player.Reload.Motion.LOWER_ABORT, "death preserves manipulation for safe lowering")
	player.equip(1)
	player.teleport(Vector3.ZERO)
	check(player.reload_cycle.view.motion == player.Reload.Motion.LOWER_ABORT, "teleport does not snap an interrupted manipulation")
	floor_body.queue_free()
	player.queue_free()
	await create_timer(0.35).timeout
	print("PLAYER TEST FAILURES: ", failures)
	quit(1 if failures else 0)
