class_name SiloPlayer
extends CharacterBody3D

const State = preload("res://scripts/run_state.gd")
const WeaponSpec = preload("res://scripts/weapon_spec.gd")
const Audio = preload("res://scripts/player_audio.gd")
const Reload = preload("res://scripts/weapon_handling.gd")
const CasingPool = preload("res://scripts/casing_pool.gd")
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
var flashlight_on: bool = false
var _flashlight: SpotLight3D
var _capture_flashlight: bool = false
var weapon_index: int:
	get: return reload_cycle.weapon_index
var aim_weight: float:
	get: return _view_frame.aim_weight
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
var _d9_flash: MeshInstance3D
var _arc_pulse: MeshInstance3D
var _casings: CasingPool
var _camera_strength := 0.5
var _light_strength := 1.0
var _effects_budget := 2
var _shot_age := 0.0
var _shot_generation := 0
var _submitted_generation := 0
var _drawn_generation := 0
var _shot_spec: WeaponSpec
var _recoil_active := false
var _base_fov := 76.0
var _aim_magnification := 1.25
var _aim_sensitivity := .65
var _aim_progress := 0.0
var _capture_aim := false
var _capture_jump := false
var _fov_impulse := 0.0
var _beam: MeshInstance3D
var _beam_hit := Vector3.ZERO
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
	_build_flashlight()
	_casings = CasingPool.new()
	add_child(_casings)
	RenderingServer.frame_pre_draw.connect(_before_draw)
	RenderingServer.frame_post_draw.connect(_after_draw)
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
		_capture_fire = _fire_held()
		_capture_aim = _aim_held()
		_capture_jump = true
		_capture_flashlight = Input.is_action_pressed("flashlight") if InputMap.has_action("flashlight") else false
	if state.health <= 0:
		flashlight_on = false
		_flashlight.visible = false
	if not active:
		_cancel_reload()
		_clear_motion_input()
		velocity.x = 0.0
		velocity.z = 0.0
		_target = null
		_clear_feedback()
		if reload_cycle.ready:
			rig.reset_pose()

func _build_flashlight() -> void:
	_flashlight = SpotLight3D.new()
	_flashlight.name = "Flashlight"
	_flashlight.position = Vector3(0.38, -0.30, -0.60)
	_flashlight.light_color = Color("f2e8d4")
	_flashlight.light_energy = 2.5
	_flashlight.light_cull_mask = 1
	_flashlight.spot_range = 14
	_flashlight.spot_angle = 32
	_flashlight.shadow_enabled = true
	_flashlight.visible = false
	camera.add_child(_flashlight)
	var housing := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.025
	shape.bottom_radius = 0.03
	shape.height = 0.1
	shape.radial_segments = 8
	housing.mesh = shape
	housing.position = Vector3(0.38, -0.30, -0.55)
	housing.rotation.x = PI / 2
	housing.layers = 2
	housing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("394a57")
	material.roughness = 0.6
	housing.material_override = material
	camera.add_child(housing)

func toggle_flashlight() -> bool:
	if not active or state.health <= 0 or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	flashlight_on = not flashlight_on
	_flashlight.visible = flashlight_on
	return true

func set_flashlight_quality(low: bool) -> void:
	_flashlight.shadow_enabled = not low

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
	_shot_spec = spec
	_shot_age = 0.0
	_shot_generation += 1
	_recoil_active = true
	_compose_feedback()
	_update_view(0.0)
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
		_beam_hit = hit_position
		_update_beam()
	else:
		_casings.emit(rig.ejection.global_transform, velocity)
	_compose_feedback()
	return true

func _update_beam() -> void:
	var start := rig.muzzle.global_position
	_beam.global_position = (start + _beam_hit) * 0.5
	_beam.look_at(_beam_hit, Vector3.UP)
	_beam.scale = Vector3(0.022, 0.022, maxf(start.distance_to(_beam_hit), 0.01))

func reload_weapon() -> bool:
	if not reload_cycle.request_reload(active):
		if weapon_index == 1:
			feedback.emit(reload_cycle.refusal)
		return false
	_cancel_recoil()
	_update_view(0.0)
	feedback.emit("Remplacement de cellule…" if weapon_index == 1 else "Rechargement…")
	return true

func request_cell() -> bool:
	var accepted := reload_cycle.request_cell(active)
	if accepted:
		_cancel_recoil()
		_update_view(0.0)
	feedback.emit("Remplacement de cellule · passage par ARC…" if accepted else reload_cycle.refusal)
	return accepted

func _cancel_reload() -> void:
	reload_cycle.cancel()
	_manipulation_audio.stop()

func _advance_reload(delta: float) -> void:
	var events := reload_cycle.advance(delta, active)
	if events & Reload.HIDDEN:
		_clear_shot()
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
	_clear_feedback()
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
	_capture_fire = _fire_held()
	_reset_aim()
	_event_shot = false

func aim_target() -> Node:
	return _target if is_instance_valid(_target) else null

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("flashlight") and event.is_action_released("flashlight"):
		_capture_flashlight = Input.is_action_pressed("flashlight")
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var yaw: float = -event.screen_relative.x * sensitivity * _look_scale()
		var pitch := camera.rotation.x
		rotate_y(yaw)
		camera.rotation.x = clampf(pitch - event.screen_relative.y * sensitivity * _look_scale(), -1.45, 1.45)
		_look_delta += Vector2(yaw, camera.rotation.x - pitch)
	if InputMap.has_action("flashlight") and event.is_action_pressed("flashlight") and not event.is_echo():
		if not _capture_flashlight:
			toggle_flashlight()
		_capture_flashlight = true
	elif event.is_action_pressed("weapon1", true):
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
			_capture_fire = _capture_fire and _fire_held()
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
	if not _fire_held():
		_capture_fire = false
	_scan_time = maxf(0.0, _scan_time - delta)
	_advance_reload(delta)
	if not active or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_reset_aim()
		_cancel_recoil()
	var aim_held := _aim_held()
	if not aim_held:
		_capture_aim = false
	var aiming := active and state.health > 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and reload_cycle.ready and not _capture_aim and aim_held
	var duration := _weapon().aim_enter_seconds if aiming else _weapon().aim_exit_seconds
	_aim_progress = move_toward(_aim_progress, 1.0 if aiming else 0.0, delta / duration)
	_view_frame.aim_weight = smoothstep(0.0, 1.0, _aim_progress)
	_compose_fov()
	if not active:
		_update_view(delta)
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and InputMap.has_action("look_left"):
		var look := Input.get_vector("look_left", "look_right", "look_up", "look_down", .2) * 2.0 * delta * _look_scale()
		var pitch := camera.rotation.x
		rotate_y(-look.x)
		camera.rotation.x = clampf(pitch - look.y, -1.45, 1.45)
		_look_delta += Vector2(-look.x, camera.rotation.x - pitch)
	if not Input.is_action_pressed("jump") and not Input.is_action_just_pressed("jump"):
		_capture_jump = false
	_set_crouch(Input.is_action_pressed("crouch"))
	var input := Input.get_vector("left", "right", "forward", "back", .2)
	var direction := global_basis * Vector3(input.x, 0.0, input.y)
	var speed: float = 2.2 if _crouched else (6.5 if Input.is_action_pressed("sprint") and not aiming else 4.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 25.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 25.0)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif Input.is_action_just_pressed("jump") and not _capture_jump and not _crouched:
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
	_view_frame.pose = FpsRig.ViewFrame.Pose.RUN if moving and Input.is_action_pressed("sprint") and not aiming else FpsRig.ViewFrame.Pose.REST
	_update_view(delta)
	if not event_shot and not _capture_fire and _fire_held() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		fire()

func _update_view(delta: float) -> void:
	_view_frame.reload = reload_cycle.view
	_view_frame.recoil = _recoil
	_view_frame.energy = state.energy
	_view_frame.capacity = state.max_energy()
	rig.update_visual(delta, _view_frame)
	if _beam.visible:
		_update_beam()

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
	var departure_orange := _material(Color("ff9b32"), 1.3)
	departure_orange.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var departure_cyan := _material(Color("49e7ed"), 1.5)
	departure_cyan.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_d9_flash = MeshInstance3D.new()
	var cross := SurfaceTool.new()
	cross.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arm := BoxMesh.new()
	arm.size = Vector3(.095, .022, .035)
	cross.append_from(arm, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0, -.28)))
	cross.append_from(arm, 0, Transform3D(Basis(Vector3.FORWARD, PI*.5), Vector3(0, 0, -.28)))
	arm.size = Vector3(.015, .015, .28)
	cross.append_from(arm, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0, -.14)))
	_d9_flash.mesh = cross.commit()
	_d9_flash.material_override = departure_orange
	_d9_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.muzzle.add_child(_d9_flash)
	_d9_flash.visible = false
	_arc_pulse = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = .060
	ring.outer_radius = .075
	ring.rings = 16
	ring.ring_segments = 8
	var pulse := SurfaceTool.new()
	pulse.begin(Mesh.PRIMITIVE_TRIANGLES)
	pulse.append_from(ring, 0, Transform3D(Basis(Vector3.RIGHT, PI*.5), Vector3(0, 0, -.42)))
	_arc_pulse.mesh = pulse.commit()
	_arc_pulse.material_override = departure_cyan
	_arc_pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.muzzle.add_child(_arc_pulse)
	_arc_pulse.visible = false
	_flash_light = OmniLight3D.new()
	_flash_light.position = Vector3.ZERO
	_flash_light.omni_range = 2.0
	_flash_light.light_cull_mask = 3
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

func configure_feedback(camera_strength: float, light_strength: float, budget: int) -> void:
	_camera_strength = camera_strength
	_light_strength = light_strength
	_effects_budget = budget
	_casings.set_budget(budget)
	_compose_feedback()

func _before_draw() -> void:
	_submitted_generation = _shot_generation

func _after_draw() -> void:
	_drawn_generation = _submitted_generation

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(_before_draw)
	RenderingServer.frame_post_draw.disconnect(_after_draw)

func _process(delta: float) -> void:
	if _shot_spec == null or (_effect_time == 0.0 and not _recoil_active):
		return
	if _drawn_generation == _shot_generation:
		_shot_age += delta
	_compose_feedback()
	_update_view(0.0)

func _compose_feedback() -> void:
	if _shot_spec != null:
		_effect_time = maxf(0.0, _shot_spec.departure_duration - _shot_age)
		if _recoil_active:
			var envelope := 1.0 - smoothstep(0.0, _shot_spec.recoil_duration, _shot_age)
			_recoil = _shot_spec.recoil * envelope
			_fov_impulse = _shot_spec.fov_impulse * _camera_strength * envelope
			_compose_fov()
			_view_frame.shot_slide = _shot_spec.shot_slide * (1.0 - smoothstep(0.0, _shot_spec.shot_slide_duration, _shot_age))
			if envelope == 0.0:
				_cancel_recoil()
	var electric := _shot_spec == ARC
	var visible_shot := _effect_time > 0.0 and _light_strength > 0.0
	_d9_flash.visible = visible_shot and not electric
	_arc_pulse.visible = visible_shot and electric
	_arc_pulse.scale = Vector3.ONE * (1.0 + clampf(_shot_age / ARC.departure_duration, 0.0, 1.0))
	_beam.visible = visible_shot and electric
	_flash_light.visible = visible_shot and _effects_budget == 2
	_flash_light.light_color = Color("49e7ed") if electric else Color("ff9b32")
	_flash_light.light_energy = 1.5 * _light_strength
	_attenuate(_d9_flash, Color("ff9b32"), 1.3)
	_attenuate(_arc_pulse, Color("49e7ed"), 1.5)
	_attenuate(_beam, Color("49e7ed"), 1.5)
	if _effect_time <= 0.0:
		_impact.visible = false

func _attenuate(mesh: MeshInstance3D, color: Color, energy: float) -> void:
	var material := mesh.material_override as StandardMaterial3D
	material.albedo_color = Color(color.r * _light_strength, color.g * _light_strength, color.b * _light_strength)
	material.emission_energy_multiplier = energy * _light_strength

func _cancel_recoil() -> void:
	if _recoil_active:
		rig.clear_shot_slide()
	_recoil_active = false
	_recoil = 0.0
	_fov_impulse = 0.0
	_compose_fov()
	_view_frame.shot_slide = 0.0

func _clear_shot() -> void:
	_cancel_recoil()
	_shot_spec = null
	_effect_time = 0.0
	_compose_feedback()

func _clear_feedback() -> void:
	_clear_shot()
	_casings.clear()

func configure_aim(base_fov: float, magnification: float, sensitivity_scale: float) -> void:
	_base_fov = base_fov
	_aim_magnification = magnification
	_aim_sensitivity = sensitivity_scale
	_compose_fov()

func _compose_fov() -> void:
	var ads_fov := rad_to_deg(2.0 * atan(tan(deg_to_rad(_base_fov) * .5) / _aim_magnification))
	camera.fov = lerpf(_base_fov, ads_fov, _view_frame.aim_weight) + _fov_impulse

func _look_scale() -> float:
	return lerpf(1.0, _aim_sensitivity, _view_frame.aim_weight)

func _aim_held() -> bool:
	return (InputMap.has_action("aim") and Input.is_action_pressed("aim")) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > .5

func _fire_held() -> bool:
	return (InputMap.has_action("fire") and Input.is_action_pressed("fire")) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > .5

func _reset_aim() -> void:
	_aim_progress = 0.0
	_view_frame.aim_weight = 0.0
	_capture_aim = _aim_held()
	_compose_fov()
