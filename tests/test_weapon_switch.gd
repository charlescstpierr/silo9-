extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
var player: Player
var visibility_changes := 0
var unsafe_changes := 0
var hidden_events := 0
var unsafe_hidden_events := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func reset() -> void:
	if is_instance_valid(player): player.free()
	player = Player.new()
	player.setup(State.new())
	player.state.ammo = 4
	player.state.energy = 40
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)
	player.reload_event.connect(observe_hidden)
	for gun in player.rig._weapons:
		gun.visibility_changed.connect(observe_visibility.bind(gun))

func below_frame(gun: Node3D) -> bool:
	for fov in [60.0, 76.0, 90.0]:
		for mesh: MeshInstance3D in gun.find_children("*", "MeshInstance3D", true, false):
			for corner in 8:
				var point := player.camera.to_local(mesh.to_global(mesh.mesh.get_aabb().get_endpoint(corner)))
				if point.z >= -.05 or point.y >= point.z * tan(deg_to_rad(fov) * .5): return false
	return true

func observe_visibility(gun: Node3D) -> void:
	visibility_changes += 1
	if not below_frame(gun): unsafe_changes += 1

func observe_hidden(event: int) -> void:
	if event != Player.Reload.HIDDEN: return
	hidden_events += 1
	if not below_frame(player.rig._weapons[player.weapon_index]) or not coherent(): unsafe_hidden_events += 1

func step(delta: float) -> void:
	player._advance_reload(delta)
	player._update_view(delta)

func coherent() -> bool:
	var rig := player.rig
	var gun := rig._weapons[player.weapon_index]
	var right := rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(3)
	var left := rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(20)
	return rig.weapon_index == player.weapon_index and gun.visible and right.origin.distance_to(gun.get_node("GripRight").global_position) < .002 and left.origin.distance_to(gun.get_node("GripLeft").global_position) < .002 and rig.muzzle.global_position.distance_to(gun.get_node("Muzzle").global_position) < .0001

func run() -> void:
	reset()
	player.equip(1)
	check(not player.reload_cycle.ready and player.weapon_index == 0, "manual selection lowers old weapon before changing identity")
	step(.08)
	player.equip(1)
	step(.081)
	check(player.weapon_index == 1 and not player.reload_cycle.ready, "repeated destination does not restart lower clock")
	step(.14)
	check(player.reload_cycle.ready and coherent(), "first final READY has both grips and muzzle coherent")
	check(player.state.ammo == 4 and player.state.energy == 40, "selection alone preserves resources")
	check(player.fire() and player.state.energy == 28 and player.state.ammo == 4, "final ARC READY spends ARC battery only")
	reset()
	player.equip(1)
	check(not player.fire() and player.state.energy == 40 and player.state.ammo == 4, "normal change refuses fire without resource debit")
	reset()
	player.equip(1)
	check(not player.reload_weapon(), "R routes to effective D9 and refuses during normal descent")
	reset()
	player.equip(1)
	step(.08)
	player.equip(0)
	check(not player.reload_cycle.ready, "reversing before hidden still completes the trajectory")
	step(.23)
	check(player.reload_cycle.ready and player.weapon_index == 0 and coherent(), "pre-hidden reversal returns coherent D9 without an extra trip")
	reset()
	player.equip(1)
	step(.17)
	player.equip(0)
	step(.14)
	check(not player.reload_cycle.ready and not player.fire(), "post-hidden reversal has no usable READY gap")
	step(.31)
	check(player.reload_cycle.ready and player.weapon_index == 0 and coherent(), "post-hidden reversal reaches final D9")
	reset()
	player.equip(1)
	step(10)
	check(player.reload_cycle.ready and player.weapon_index == 1 and coherent(), "large delta consumes lower and raise without requiring a rendered hidden frame")
	reset()
	check(player.reload_weapon(), "same-index hidden fixture starts a D9 reload")
	step(.5)
	player.equip(1)
	player.equip(0)
	var hidden_before := hidden_events
	step(10)
	check(hidden_events == hidden_before + 1 and player.reload_cycle.ready and coherent(), "same-index cancelled exit crosses one hidden milestone with coherent final grips")
	check(player.state.ammo == 4 and player.state.reserve == 48, "same-index cancelled exit never commits D9 resources")
	for cancelled in [false, true]:
		reset()
		if cancelled:
			check(player.reload_weapon(), "cancelled exit starts D9 reload")
			step(.7)
		player.equip(1)
		check(player.activate_scan() and player.state.energy == 20, "scanner remains available through normal or cancelled exit")
		check(player.request_cell(), "normal or cancelled exit accepts one B intention")
		check(not player.request_cell(), "pending B refuses duplicates")
		for tick in 500: step(.01)
		check(player.reload_cycle.ready and player.weapon_index == 1 and player.state.energy == 80 and player.state.cells == 1, "B returns to desired ARC and transfers exactly one cell")
		check(player.state.ammo == 4 and player.state.reserve == 48, "B never commits a cancelled D9 reload")
	reset()
	player.equip(1)
	step(.17)
	check(player.reload_weapon(), "R uses effective ARC during raise and queues one cell")
	check(not player.reload_weapon(), "R cannot duplicate pending ARC cell")
	for tick in 500: step(.01)
	check(player.state.energy == 100 and player.state.cells == 1, "ARC R during raise commits exactly one cell")
	for interruption in ["inactive", "teleport", "death"]:
		reset()
		player.equip(1)
		step(.07)
		match interruption:
			"inactive": player.set_active(false)
			"teleport": player.teleport(Vector3(4, 0, 2))
			"death": player.apply_damage(100)
		var held_right := player.rig.skeleton.get_bone_global_pose(3)
		var held_left := player.rig.skeleton.get_bone_global_pose(20)
		step(.04)
		check(player.rig.skeleton.get_bone_global_pose(3).is_equal_approx(held_right) and player.rig.skeleton.get_bone_global_pose(20).is_equal_approx(held_left), interruption + " preserves both local wrist poses through lowering")
		check(player.state.ammo == 4 and player.state.energy == 40, interruption + " cannot spend resources")
	reset()
	player.equip(1)
	var continuous := true
	var previous: Array[Vector3] = []
	for tick in 65:
		var positions: Array[Vector3] = [player.camera.to_local(player.rig.skeleton.to_global(player.rig.skeleton.get_bone_global_pose(3).origin)), player.camera.to_local(player.rig.skeleton.to_global(player.rig.skeleton.get_bone_global_pose(20).origin)), player.camera.to_local(player.rig._weapons[player.weapon_index].global_position), player.camera.to_local(player.rig.muzzle.global_position)]
		if not previous.is_empty():
			for index in positions.size():
				if previous[index].y > previous[index].z or positions[index].y > positions[index].z:
					continuous = continuous and previous[index].distance_to(positions[index]) < .08
		previous = positions
		step(.005)
	check(continuous, "visible wrists, weapon and muzzle remain continuous during a complete selection")
	reset()
	var node_count := get_node_count()
	var meshes: Array[Mesh] = []
	for mesh: MeshInstance3D in player.rig.find_children("*", "MeshInstance3D", true, false): meshes.append(mesh.mesh)
	var all_coherent := true
	for cycle in 100:
		player.equip(1 - player.weapon_index)
		for delta in [.013, .047, .031, .069, .023, .117, .02]: step(delta)
		all_coherent = all_coherent and player.reload_cycle.ready and coherent()
	check(all_coherent, "100 alternating selections finish with both grips and muzzle coherent")
	check(get_node_count() == node_count, "100 selections do not allocate nodes")
	var index := 0
	var reused := true
	for mesh: MeshInstance3D in player.rig.find_children("*", "MeshInstance3D", true, false):
		reused = reused and mesh.mesh == meshes[index]
		index += 1
	check(reused, "100 selections reuse actual meshes")
	check(visibility_changes >= 200, "visibility observer covers actual model changes")
	check(unsafe_changes == 0, "all visibility changes occur with actual mesh corners below FOV 60/76/90: unsafe=%d" % unsafe_changes)
	check(hidden_events > 0 and unsafe_hidden_events == 0, "every HIDDEN callback exposes a masked coherent assembly including same-index and large deltas: unsafe=%d" % unsafe_hidden_events)
	player.free()
	await create_timer(.3).timeout
	print("WEAPON SWITCH FAILURES: ", failures)
	quit(1 if failures else 0)
