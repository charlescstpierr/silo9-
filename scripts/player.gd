class_name SiloPlayer
extends CharacterBody3D

const State = preload("res://scripts/run_state.gd")
const WeaponSpec = preload("res://scripts/weapon_spec.gd")
const Audio = preload("res://scripts/player_audio.gd")
const Reload = preload("res://scripts/weapon_handling.gd")
const FpsRig = preload("res://scripts/fps_rig.gd")
const RELOAD_EVENTS := [Reload.REMOVE, Reload.INSERT, Reload.RACK_PULL, Reload.RACK_RELEASE, Reload.COMMIT, Reload.HIDDEN, Reload.CELL_UNLOCK, Reload.CELL_REMOVE, Reload.CELL_INSERT, Reload.CELL_TRANSFER, Reload.CELL_DONE, Reload.CELL_REFUSED]
const D9: Resource = preload("res://data/weapons/d9.tres")
const ARC: Resource = preload("res://data/weapons/arc3.tres")
const STANDING_HEIGHT: float = 1.8
const CROUCH_HEIGHT: float = 1.12
const STEP_HEIGHT: float = 0.3

signal interacted(target: Node)
signal scanned(origin: Vector3)
signal noise_emitted(origin: Vector3, radius: float)
signal feedback(message: String)
signal reload_event(event: int)

var state: State
var camera: Camera3D
var active: bool = false
var weapon_index: int:
	get: return reload_cycle.weapon_index
var sensitivity: float = 0.002
var reload_cycle := Reload.new()
var reloading: bool:
	get: return reload_cycle.view.motion in [Reload.Motion.RELOAD, Reload.Motion.CELL]
var _body_shape: CollisionShape3D
var _capsule: CapsuleShape3D
var _headroom_shape: CapsuleShape3D
var _headroom_query := PhysicsShapeQueryParameters3D.new()
var _aim_query := PhysicsRayQueryParameters3D.new()
var _shot_query := PhysicsRayQueryParameters3D.new()
var _step_query := PhysicsRayQueryParameters3D.new()
var _step_collision := KinematicCollision3D.new()
var rig: FpsRig
var _view_frame := FpsRig.ViewFrame.new()
var _muzzle: MeshInstance3D
var _beam: MeshInstance3D
var _impact: MeshInstance3D
var _flash_light: OmniLight3D
var _audio: AudioStreamPlayer
var _manipulation_audio: AudioStreamPlayer
var _scan_audio: AudioStreamPlayer
var _sounds: Dictionary[String, AudioStreamWAV] = {}
var _target: Node
var _aim_time: float = 0.0
var _shot_time: float = 0.0
var _scan_time: float = 0.0
var _effect_time: float = 0.0
var _recoil: float = 0.0
var _crouched: bool = false
var _look_delta := Vector2.ZERO
var _capture_fire := false
var _event_shot := false

func setup(run: State) -> void:
	state = run
	reload_cycle.state = run

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
	_manipulation_audio = AudioStreamPlayer.new()
	_manipulation_audio.volume_db = -8.0
	add_child(_manipulation_audio)
	_view_frame.reload = reload_cycle.view
	for kind: String in ["shot", "arc", "scan", "remove", "insert", "rack_pull", "rack_release", "cell_unlock", "cell_remove", "cell_insert", "cell_transfer", "hurt"]:
		_sounds[kind] = Audio.synthesize(kind)

func set_active(value: bool) -> void:
	var was_active := active
	active = value and state != null and state.health > 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	if active and not was_active:
		_capture_fire = InputMap.has_action("fire") and Input.is_action_pressed("fire")
	if not active:
		_cancel_reload()
		_clear_motion_input()
		velocity.x = 0.0
		velocity.z = 0.0
		_target = null
		_recoil = 0.0
		if reload_cycle.ready:
			rig.reset_pose()

func equip(index: int) -> void:
	if index < 0 or index > 1:
		return
	reload_cycle.select(index)
	if reload_cycle.view.motion == Reload.Motion.LOWER_ABORT:
		_manipulation_audio.stop()

func _weapon() -> WeaponSpec:
	return D9 if weapon_index == 0 else ARC

func fire() -> bool:
	if not active or state == null or state.health <= 0.0 or not reload_cycle.ready or _shot_time > 0.0:
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
	_update_view(0.0)
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
	if not reload_cycle.request_reload(active):
		if weapon_index == 1:
			feedback.emit(reload_cycle.refusal)
		return false
	feedback.emit("Remplacement de cellule…" if weapon_index == 1 else "Rechargement…")
	return true

func request_cell() -> bool:
	var accepted := reload_cycle.request_cell(active)
	feedback.emit("Remplacement de cellule · passage par ARC…" if accepted else reload_cycle.refusal)
	return accepted

func _cancel_reload() -> void:
	reload_cycle.cancel()
	_manipulation_audio.stop()

func _advance_reload(delta: float) -> void:
	var events := reload_cycle.advance(delta, active)
	if events & Reload.HIDDEN:
		rig.apply_hidden_weapon(weapon_index)
	elif events & (Reload.COMMIT | Reload.CELL_DONE):
		rig.restore_reload_parts()
	var cue := ""
	for event: int in RELOAD_EVENTS:
		if events & event:
			reload_event.emit(event)
			match event:
				Reload.REMOVE: cue = "remove"
				Reload.INSERT: cue = "insert"
				Reload.RACK_PULL: cue = "rack_pull"
				Reload.RACK_RELEASE: cue = "rack_release"
				Reload.CELL_UNLOCK: cue = "cell_unlock"
				Reload.CELL_REMOVE: cue = "cell_remove"
				Reload.CELL_INSERT: cue = "cell_insert"
				Reload.CELL_REFUSED: feedback.emit(reload_cycle.refusal)
				Reload.CELL_TRANSFER:
					cue = "cell_transfer" if reload_cycle.view.transferred else "cell_unlock"
					feedback.emit("Batterie rechargée." if reload_cycle.view.transferred else "Cellule conservée · transfert devenu inutile ou indisponible.")
	if not cue.is_empty() and not events & (Reload.COMMIT | Reload.CELL_DONE) and reload_cycle.cue_age < .16:
		_manipulation_audio.stream = _sounds[cue]
		_manipulation_audio.play()

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
	_clear_motion_input()
	_target = null
	_aim_time = 0.0
	_recoil = 0.0
	if reload_cycle.ready:
		rig.reset_pose()
	if camera != null:
		camera.rotation = Vector3.ZERO

func _clear_motion_input() -> void:
	_look_delta = Vector2.ZERO
	_view_frame.look_delta = Vector2.ZERO
	_view_frame.local_velocity = Vector3.ZERO
	_view_frame.grounded = false
	_view_frame.pose = FpsRig.ViewFrame.Pose.REST
	_capture_fire = InputMap.has_action("fire") and Input.is_action_pressed("fire")
	_event_shot = false

func aim_target() -> Node:
	return _target if is_instance_valid(_target) else null

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var yaw: float = -event.screen_relative.x * sensitivity
		var pitch := camera.rotation.x
		rotate_y(yaw)
		camera.rotation.x = clampf(pitch - event.screen_relative.y * sensitivity, -1.45, 1.45)
		_look_delta += Vector2(yaw, camera.rotation.x - pitch)
	if event.is_action_pressed("weapon1", true):
		equip(0)
	elif event.is_action_pressed("weapon2", true):
		equip(1)
	elif event.is_action_pressed("reload"):
		reload_weapon()
	elif event.is_action_pressed("scan"):
		activate_scan()
	elif event.is_action_pressed("interact"):
		_update_target()
		if is_instance_valid(_target):
			interacted.emit(_target)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_capture_fire = false
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_capture_fire = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not _capture_fire and fire():
			_event_shot = true

func _physics_process(delta: float) -> void:
	var event_shot := _event_shot
	_event_shot = false
	if not event_shot:
		_shot_time = maxf(0.0, _shot_time - delta)
	if not Input.is_action_pressed("fire"):
		_capture_fire = false
	_scan_time = maxf(0.0, _scan_time - delta)
	if _effect_time > 0.0:
		_effect_time -= delta
		if _effect_time <= 0.0:
			_muzzle.visible = false
			_beam.visible = false
			_impact.visible = false
			_flash_light.visible = false
	_recoil = move_toward(_recoil, 0.0, delta * 0.2)
	_advance_reload(delta)
	if not active:
		_update_view(delta)
		return
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
	_view_frame.local_velocity = global_basis.inverse() * get_real_velocity()
	_view_frame.grounded = is_on_floor()
	_view_frame.crouched = _crouched
	_view_frame.look_delta = _look_delta
	_look_delta = Vector2.ZERO
	var moving := is_on_floor() and Vector2(_view_frame.local_velocity.x, _view_frame.local_velocity.z).length_squared() > .01
	camera.position.y = move_toward(camera.position.y, 0.94 if _crouched else 1.58, delta * 4.0)
	_view_frame.pose = FpsRig.ViewFrame.Pose.RUN if moving and Input.is_action_pressed("sprint") else FpsRig.ViewFrame.Pose.REST
	if InputMap.has_action("aim") and Input.is_action_pressed("aim"):
		_view_frame.pose = FpsRig.ViewFrame.Pose.AIM
	_update_view(delta)
	if not event_shot and not _capture_fire and Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		fire()

func _update_view(delta: float) -> void:
	_view_frame.reload = reload_cycle.view
	_view_frame.recoil = _recoil
	_view_frame.energy = state.energy
	_view_frame.capacity = state.max_energy()
	rig.update_visual(delta, _view_frame)

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
	var orange := _material(Color("f6a63d"), 1.3)
	var cyan := _material(Color("49e7ed"), 1.5)
	rig = FpsRig.new()
	camera.add_child(rig)
	var key := OmniLight3D.new()
	key.position = Vector3(-0.25, 0.32, 0.06)
	key.light_color = Color("d0e7ef")
	key.light_energy = 0.42
	key.light_specular = 0.45
	key.omni_range = 1.4
	key.omni_attenuation = 0.8
	key.light_cull_mask = 2
	key.shadow_enabled = false
	camera.add_child(key)
	_muzzle = _box(rig.muzzle, Vector3(0.045, 0.045, 0.07), Vector3.ZERO, orange)
	_muzzle.visible = false
	_flash_light = OmniLight3D.new()
	_flash_light.position = Vector3.ZERO
	_flash_light.omni_range = 3.0
	_flash_light.light_energy = 1.5
	_flash_light.shadow_enabled = false
	_flash_light.visible = false
	rig.muzzle.add_child(_flash_light)
	_beam = _box(self, Vector3.ONE, Vector3.ZERO, cyan)
	_beam.top_level = true
	_beam.visible = false
	_impact = _box(self, Vector3(0.055, 0.055, 0.055), Vector3.ZERO, orange)
	_impact.top_level = true
	_impact.visible = false
