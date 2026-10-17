class_name SiloPlayer
extends CharacterBody3D

const State = preload("res://scripts/run_state.gd")
const WeaponSpec = preload("res://scripts/weapon_spec.gd")
const Audio = preload("res://scripts/player_audio.gd")
const D9: Resource = preload("res://data/weapons/d9.tres")
const ARC: Resource = preload("res://data/weapons/arc3.tres")
const STANDING_HEIGHT: float = 1.8
const CROUCH_HEIGHT: float = 1.12
const STEP_HEIGHT: float = 0.3

signal interacted(target: Node)
signal scanned(origin: Vector3)
signal noise_emitted(origin: Vector3, radius: float)
signal feedback(message: String)

var state: State
var camera: Camera3D
var active: bool = false
var weapon_index: int = 0
var sensitivity: float = 0.002
var reloading: bool = false
var _body_shape: CollisionShape3D
var _capsule: CapsuleShape3D
var _headroom_shape: CapsuleShape3D
var _headroom_query := PhysicsShapeQueryParameters3D.new()
var _aim_query := PhysicsRayQueryParameters3D.new()
var _shot_query := PhysicsRayQueryParameters3D.new()
var _step_query := PhysicsRayQueryParameters3D.new()
var _step_collision := KinematicCollision3D.new()
var _gun_root: Node3D
var _guns: Array[Node3D] = []
var _muzzle: MeshInstance3D
var _beam: MeshInstance3D
var _impact: MeshInstance3D
var _flash_light: OmniLight3D
var _audio: AudioStreamPlayer
var _scan_audio: AudioStreamPlayer
var _sounds: Dictionary[String, AudioStreamWAV] = {}
var _target: Node
var _aim_time: float = 0.0
var _shot_time: float = 0.0
var _reload_time: float = 0.0
var _scan_time: float = 0.0
var _effect_time: float = 0.0
var _recoil: float = 0.0
var _crouched: bool = false
var _walk_phase: float = 0.0

func setup(run: State) -> void:
	state = run

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(48.0)
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.32
	_capsule.height = STANDING_HEIGHT
	_body_shape = CollisionShape3D.new()
	_body_shape.shape = _capsule
	_body_shape.position.y = STANDING_HEIGHT * 0.5
	add_child(_body_shape)
	_headroom_shape = CapsuleShape3D.new()
	_headroom_shape.radius = 0.31
	_headroom_shape.height = STANDING_HEIGHT - 0.03
	_headroom_query.shape = _headroom_shape
	_headroom_query.collision_mask = 1
	_headroom_query.exclude = [get_rid()]
	_aim_query.collision_mask = 1
	_aim_query.exclude = [get_rid()]
	_shot_query.collision_mask = 1
	_shot_query.exclude = [get_rid()]
	_step_query.collision_mask = 1
	_step_query.exclude = [get_rid()]
	camera = Camera3D.new()
	camera.position.y = 1.58
	camera.fov = 76.0
	camera.near = 0.05
	camera.far = 180.0
	camera.current = true
	add_child(camera)
	_build_weapons()
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -11.0
	add_child(_audio)
	_scan_audio = AudioStreamPlayer.new()
	_scan_audio.volume_db = -13.0
	add_child(_scan_audio)
	for kind: String in ["shot", "arc", "scan", "reload", "hurt"]:
		_sounds[kind] = Audio.synthesize(kind)

func set_active(value: bool) -> void:
	active = value and state != null and state.health > 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	if not active:
		_cancel_reload()
		velocity.x = 0.0
		velocity.z = 0.0
		_target = null

func equip(index: int) -> void:
	if index < 0 or index > 1:
		return
	if index != weapon_index:
		_cancel_reload()
	weapon_index = index
	for slot in _guns.size():
		_guns[slot].visible = slot == index

func _weapon() -> WeaponSpec:
	return D9 if weapon_index == 0 else ARC

func fire() -> bool:
	if not active or state == null or state.health <= 0.0 or reloading or _shot_time > 0.0:
		return false
	var spec := _weapon()
	if spec.energy_cost > 0.0:
		if not state.spend_energy(spec.energy_cost):
			feedback.emit("Énergie insuffisante · recharge dans l’ascenseur")
			return false
	elif not state.fire_round():
		feedback.emit("Chargeur vide · R pour recharger")
		return false
	_shot_time = spec.cooldown
	_recoil = spec.recoil
	_effect_time = 0.09 if weapon_index == 0 else 0.16
	_muzzle.visible = true
	_flash_light.visible = true
	_flash_light.light_color = Color(1.0, 0.58, 0.19) if weapon_index == 0 else Color(0.12, 0.85, 1.0)
	noise_emitted.emit(global_position, spec.noise_radius)
	_play("shot" if weapon_index == 0 else "arc")
	_shot_query.from = camera.global_position
	_shot_query.to = camera.global_position - camera.global_basis.z * spec.reach
	var result := get_world_3d().direct_space_state.intersect_ray(_shot_query)
	var hit_position: Vector3 = _shot_query.to
	if not result.is_empty():
		hit_position = result["position"]
		_impact.global_position = hit_position
		_impact.visible = true
		var target: Object = result["collider"]
		if target.has_method("receive_hit"):
			target.call("receive_hit", spec.damage, spec.stun)
			feedback.emit("IMPACT" if weapon_index == 0 else "SYSTÈME IMMOBILISÉ")
	if weapon_index == 1:
		var start := _muzzle.global_position
		_beam.global_position = (start + hit_position) * 0.5
		_beam.look_at(hit_position, Vector3.UP)
		_beam.scale = Vector3(0.022, 0.022, maxf(start.distance_to(hit_position), 0.01))
		_beam.visible = true
	return true

func reload_weapon() -> bool:
	if not active or state == null or state.health <= 0.0 or weapon_index != 0 or reloading or state.ammo >= D9.capacity or state.reserve <= 0:
		return false
	reloading = true
	_reload_time = D9.reload_duration
	_play("reload")
	feedback.emit("Rechargement…")
	return true

func _cancel_reload() -> void:
	reloading = false
	_reload_time = 0.0

func activate_scan() -> bool:
	if not active or state == null or state.health <= 0.0 or _scan_time > 0.0:
		return false
	if not state.spend_energy(20.0):
		feedback.emit("SCAN ÉCHO requiert 20 énergie · recharge dans l’ascenseur")
		return false
	_scan_time = 2.5
	_scan_audio.stream = _sounds["scan"]
	_scan_audio.play()
	scanned.emit(global_position)
	feedback.emit("SCAN ÉCHO · signatures révélées")
	return true

func apply_damage(amount: float) -> void:
	if state == null:
		return
	state.damage(amount)
	_play("hurt")
	if state.health <= 0.0:
		set_active(false)

func teleport(pos: Vector3, yaw: float = 0.0) -> void:
	global_position = pos
	rotation.y = yaw
	velocity = Vector3.ZERO
	_cancel_reload()
	_target = null
	_aim_time = 0.0
	if camera != null:
		camera.rotation = Vector3.ZERO

func aim_target() -> Node:
	return _target if is_instance_valid(_target) else null

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.45, 1.45)
	if event.is_action_pressed("weapon1"):
		equip(0)
	elif event.is_action_pressed("weapon2"):
		equip(1)
	elif event.is_action_pressed("reload"):
		reload_weapon()
	elif event.is_action_pressed("scan"):
		activate_scan()
	elif event.is_action_pressed("interact"):
		_update_target()
		if is_instance_valid(_target):
			interacted.emit(_target)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_shot_time = maxf(0.0, _shot_time - delta)
	_scan_time = maxf(0.0, _scan_time - delta)
	if _effect_time > 0.0:
		_effect_time -= delta
		if _effect_time <= 0.0:
			_muzzle.visible = false
			_beam.visible = false
			_impact.visible = false
			_flash_light.visible = false
	_recoil = move_toward(_recoil, 0.0, delta * 0.2)
	if not active:
		return
	if reloading:
		_reload_time -= delta
		if _reload_time <= 0.0:
			state.reload_rounds(D9.capacity)
			_cancel_reload()
	if Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		fire()
	_set_crouch(Input.is_action_pressed("crouch"))
	var input := Input.get_vector("left", "right", "forward", "back")
	var direction := global_basis * Vector3(input.x, 0.0, input.y)
	var speed: float = 2.2 if _crouched else (6.5 if Input.is_action_pressed("sprint") else 4.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 25.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 25.0)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif Input.is_action_just_pressed("jump") and not _crouched:
		velocity.y = 7.0
	var stepped: bool = false
	if is_on_floor() and velocity.y <= 0.0:
		stepped = _try_step(Vector3(velocity.x, 0.0, velocity.z) * delta)
	floor_snap_length = 0.0 if stepped else 0.35
	move_and_slide()
	if global_position.y < -20.0:
		apply_damage(100.0)
	_aim_time -= delta
	if _aim_time <= 0.0:
		_update_target()
		_aim_time = 0.1
	var moving := is_on_floor() and input.length_squared() > 0.01
	if moving:
		_walk_phase += delta * speed * 1.7
	var bob: float = sin(_walk_phase) * 0.008 if moving else 0.0
	camera.position.y = move_toward(camera.position.y, (0.94 if _crouched else 1.58) + bob, delta * 4.0)
	_gun_root.position.y = -0.24 + bob - (sin((_reload_time / D9.reload_duration) * PI) * 0.17 if reloading else 0.0)
	_gun_root.position.z = -0.42 + _recoil

func _set_crouch(wanted: bool) -> void:
	if wanted == _crouched:
		return
	if not wanted:
		_headroom_query.transform = Transform3D(global_basis, global_position + Vector3.UP * (STANDING_HEIGHT * 0.5 + 0.015))
		if not get_world_3d().direct_space_state.intersect_shape(_headroom_query, 1).is_empty():
			return
	_crouched = wanted
	_capsule.height = CROUCH_HEIGHT if wanted else STANDING_HEIGHT
	_body_shape.position.y = _capsule.height * 0.5

func _try_step(motion: Vector3) -> bool:
	if motion.length_squared() < 0.000001 or not test_move(global_transform, motion, _step_collision):
		return false
	if _step_collision.get_normal().y > 0.65:
		return false
	var lift := Vector3.UP * STEP_HEIGHT
	if test_move(global_transform, lift):
		return false
	var raised := global_transform.translated(lift)
	if test_move(raised, motion):
		return false
	var probe := global_position + motion.normalized() * (_capsule.radius + motion.length() + 0.02)
	_step_query.from = probe + lift
	_step_query.to = probe + Vector3.UP * 0.025
	var support := get_world_3d().direct_space_state.intersect_ray(_step_query)
	if support.is_empty():
		return false
	var normal: Vector3 = support["normal"]
	var surface: Vector3 = support["position"]
	if normal.y < 0.65 or surface.y <= global_position.y + 0.025:
		return false
	global_position.y = surface.y + 0.01
	return true

func _update_target() -> void:
	_aim_query.from = camera.global_position
	_aim_query.to = camera.global_position - camera.global_basis.z * 3.5
	var hit := get_world_3d().direct_space_state.intersect_ray(_aim_query)
	_target = null
	if not hit.is_empty():
		var candidate: Node = hit["collider"]
		if candidate.is_in_group("interactable"):
			_target = candidate

func _play(kind: String) -> void:
	if _audio != null:
		_audio.stream = _sounds[kind]
		_audio.play()

func _material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.7
	material.roughness = 0.35
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material

func _box(parent: Node3D, size: Vector3, pos: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = pos
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh

func _build_weapons() -> void:
	var steel := _material(Color("37444b"))
	var dark := _material(Color("111c23"))
	var orange := _material(Color("f6a63d"), 1.8)
	var cyan := _material(Color("49e7ed"), 2.2)
	var grip := _material(Color("232d2e"))
	_gun_root = Node3D.new()
	_gun_root.position = Vector3(0.24, -0.24, -0.42)
	camera.add_child(_gun_root)
	for index in 2:
		var gun := Node3D.new()
		_gun_root.add_child(gun)
		_guns.append(gun)
		var handle := _box(gun, Vector3(0.095, 0.19, 0.115), Vector3(0, -0.04, 0.08), grip)
		handle.rotation.x = -0.2
		_box(gun, Vector3(0.125, 0.105, 0.37), Vector3(0, 0.07, -0.03), steel)
		_box(gun, Vector3(0.1, 0.045, 0.31), Vector3(0, 0.137, -0.035), dark)
		_box(gun, Vector3(0.04, 0.036, 0.045), Vector3(0, 0.17, -0.17), orange if index == 0 else cyan)
		_box(gun, Vector3(0.04, 0.04, 0.06), Vector3(0, 0.075, -0.245), dark)
		for rib in 4:
			_box(gun, Vector3(0.132, 0.016, 0.012), Vector3(0, 0.09, 0.05 + rib * 0.025), dark)
		if index == 1:
			for side in [-1.0, 1.0]:
				_box(gun, Vector3(0.028, 0.065, 0.31), Vector3(side * 0.095, 0.065, -0.12), cyan)
				_box(gun, Vector3(0.055, 0.085, 0.06), Vector3(side * 0.095, 0.065, -0.26), steel)
			_box(gun, Vector3(0.085, 0.035, 0.16), Vector3(0, 0.01, -0.11), cyan)
		gun.visible = index == 0
	_muzzle = _box(_gun_root, Vector3(0.08, 0.08, 0.13), Vector3(0, 0.075, -0.31), orange)
	_muzzle.visible = false
	_flash_light = OmniLight3D.new()
	_flash_light.position = Vector3(0, 0.075, -0.3)
	_flash_light.omni_range = 3.0
	_flash_light.light_energy = 1.5
	_flash_light.shadow_enabled = false
	_flash_light.visible = false
	_gun_root.add_child(_flash_light)
	_beam = _box(self, Vector3.ONE, Vector3.ZERO, cyan)
	_beam.top_level = true
	_beam.visible = false
	_impact = _box(self, Vector3(0.055, 0.055, 0.055), Vector3.ZERO, orange)
	_impact.top_level = true
	_impact.visible = false
