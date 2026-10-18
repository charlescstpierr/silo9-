extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
const Ready = preload("res://tests/weapon_ready.gd")
var failures := 0
var player: Player
var bodies: Array[Node] = []

class Target extends StaticBody3D:
	var damage := 0.0
	var stun := 0.0
	var hits := 0
	func receive_hit(amount: float, duration: float) -> void:
		damage += amount
		stun = duration
		hits += 1

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func box(position: Vector3, size: Vector3, target: bool = false) -> StaticBody3D:
	var body: StaticBody3D = Target.new() if target else StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)
	body.position = position
	bodies.append(body)
	return body

func prepare() -> void:
	for action in ["forward", "back", "left", "right", "sprint", "jump", "crouch", "fire", "aim", "weapon1", "weapon2", "reload", "scan", "interact"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	box(Vector3(0, -.5, 0), Vector3(200, 1, 200))
	await physics_frame

func release_player() -> void:
	for audio in player.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	player.free()

func reset(weapon: int = 0) -> void:
	if is_instance_valid(player): release_player()
	player = Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.set_active(true)
	player.equip(weapon)
	check(Ready.wait_for(player, weapon), "fixture reaches READY")

func present(delta: float) -> void:
	if player.has_method("_process"): player.call("_process", delta)

func submitted() -> void:
	await RenderingServer.frame_post_draw

func configure(camera_strength: float, light_strength: float, budget: int) -> bool:
	var exists := player.has_method("configure_feedback")
	check(exists, "Player exposes configure_feedback")
	if exists: player.call("configure_feedback", camera_strength, light_strength, budget)
	return exists

func casings() -> Node:
	for node in player.find_children("*", "", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path == "res://scripts/casing_pool.gd": return node
	return null

func visible_cases(pool: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for node in pool.find_children("*", "MeshInstance3D", true, false):
		if node.is_visible_in_tree(): result.append(node)
	return result

func finish(label: String) -> void:
	if is_instance_valid(player): release_player()
	for body in bodies:
		if is_instance_valid(body): body.free()
	await create_timer(.3).timeout
	print(label, " FAILURES: ", failures)
	quit(1 if failures else 0)

func departure_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for mesh in player.rig.muzzle.find_children("*", "MeshInstance3D", true, false):
		if mesh.is_visible_in_tree(): result.append(mesh)
	return result

func departure_visible() -> bool:
	return not departure_meshes().is_empty()
