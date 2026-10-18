extends "res://tests/shot_feedback_fixture.gd"

func prepare_ads() -> void:
	root.size = Vector2i(1280, 720)
	await prepare()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("aim", event)

func aim(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tick(delta: float) -> void:
	player._physics_process(delta)

func advance(seconds: float) -> void:
	var remaining := seconds
	while remaining > .000001:
		var delta := minf(remaining, .01)
		tick(delta)
		remaining -= delta

func configure_ads(fov: float = 76, zoom: float = 1.25, sensitivity_scale: float = .65) -> bool:
	var available := player.has_method("configure_aim")
	check(available, "Player exposes configure_aim")
	if available: player.call("configure_aim", fov, zoom, sensitivity_scale)
	return available

func zoom_fov(base: float, zoom: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(base) * .5) / zoom))

func near_fov(expected: float) -> bool:
	return absf(player.camera.fov - expected) <= .01

func sight(name: String) -> Node3D:
	return player.rig._weapons[player.weapon_index].find_child(name, true, false) as Node3D

func centered(point: Vector3) -> bool:
	return player.camera.unproject_position(point).distance_to(Vector2(640, 360)) <= 1.0

func contacts_valid() -> bool:
	for side in 2:
		var hand: Transform3D = player.rig.skeleton.global_transform * player.rig.skeleton.get_bone_global_pose(3 + side * 17)
		var grip: Node3D = player.rig._weapons[player.weapon_index].get_node("GripRight") if side == 0 else player.rig.active_left_grip
		if side == 0 or player.rig.left_in_contact:
			if hand.origin.distance_to(grip.global_position) > .002: return false
	return player.rig.calibration_valid

func release_inputs() -> void:
	aim(false)
	for action in ["forward", "back", "left", "right", "sprint", "crouch", "fire", "aim"]:
		Input.action_release(action)
