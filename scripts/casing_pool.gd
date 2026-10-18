class_name SiloCasingPool
extends Node3D

const CAPACITY := 8
enum Motion { FREE, MOBILE, RESTING }

class Slot extends RefCounted:
	var mesh: MeshInstance3D
	var motion := Motion.FREE
	var velocity := Vector3.ZERO
	var age := 0.0
	var generation := 0
	var contacts := 0

var _slots: Array[Slot] = []
var _query := PhysicsRayQueryParameters3D.new()
var _budget := 2
var _generation := 0
var _submitted_generation := 0
var _drawn_generation := 0

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	var mesh := CylinderMesh.new()
	mesh.top_radius = .004
	mesh.bottom_radius = .004
	mesh.height = .018
	mesh.radial_segments = 8
	mesh.rings = 1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("d9a954")
	material.metallic = .65
	material.roughness = .4
	for index in CAPACITY:
		var slot := Slot.new()
		slot.mesh = MeshInstance3D.new()
		slot.mesh.mesh = mesh
		slot.mesh.material_override = material
		slot.mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		slot.mesh.visible = false
		add_child(slot.mesh)
		_slots.append(slot)
	_query.collision_mask = 1
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.hit_from_inside = true
	RenderingServer.frame_pre_draw.connect(_before_draw)
	RenderingServer.frame_post_draw.connect(_after_draw)
	set_physics_process(false)

func emit(port: Transform3D, inherited_velocity: Vector3) -> void:
	if _budget == 0:
		return
	var chosen: Slot
	var count := 0
	for slot in _slots:
		if slot.motion != Motion.FREE:
			count += 1
	if count >= _limit():
		chosen = _oldest()
	else:
		for slot in _slots:
			if slot.motion == Motion.FREE:
				chosen = slot
				break
	_generation += 1
	chosen.motion = Motion.MOBILE
	chosen.age = 0.0
	chosen.contacts = 0
	chosen.generation = _generation
	chosen.velocity = inherited_velocity + port.basis * Vector3(1.5, 1.7, .3)
	chosen.mesh.global_transform = port
	chosen.mesh.visible = true
	set_physics_process(true)

func set_budget(budget: int) -> void:
	_budget = budget
	var count := 0
	for slot in _slots:
		if slot.motion != Motion.FREE:
			if slot.age >= _ttl():
				_retire(slot)
			else:
				count += 1
	while count > _limit():
		_retire(_oldest())
		count -= 1
	set_physics_process(count > 0)

func clear() -> void:
	for slot in _slots:
		_retire(slot)
	set_physics_process(false)

func _limit() -> int:
	return 8 if _budget == 2 else (2 if _budget == 1 else 0)

func _ttl() -> float:
	return 2.0 if _budget == 2 else .8

func _oldest() -> Slot:
	var oldest: Slot
	for slot in _slots:
		if slot.motion != Motion.FREE and (oldest == null or slot.generation < oldest.generation):
			oldest = slot
	return oldest

func _retire(slot: Slot) -> void:
	slot.motion = Motion.FREE
	slot.mesh.visible = false

func _before_draw() -> void:
	_submitted_generation = _generation

func _after_draw() -> void:
	_drawn_generation = _submitted_generation

func _exit_tree() -> void:
	RenderingServer.frame_pre_draw.disconnect(_before_draw)
	RenderingServer.frame_post_draw.disconnect(_after_draw)

func _physics_process(delta: float) -> void:
	var count := 0
	var step := minf(delta, 1.0 / 30.0)
	for slot in _slots:
		if slot.motion == Motion.FREE:
			continue
		if slot.generation <= _drawn_generation:
			slot.age += delta
			if slot.age >= _ttl():
				_retire(slot)
				continue
			if slot.motion == Motion.MOBILE:
				_move(slot, step)
		if slot.motion != Motion.FREE:
			count += 1
	set_physics_process(count > 0)

func _move(slot: Slot, step: float) -> void:
	slot.velocity.y -= 9.8 * step
	_query.from = slot.mesh.global_position
	_query.to = _query.from + slot.velocity * step
	var hit := get_world_3d().direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		slot.mesh.global_position = _query.to
		slot.mesh.rotate_object_local(Vector3.RIGHT, step * 12.0)
		return
	var normal: Vector3 = hit["normal"]
	if normal.is_zero_approx():
		_retire(slot)
		return
	slot.contacts += 1
	slot.mesh.global_position = hit["position"] + normal * .004
	slot.velocity = slot.velocity.bounce(normal) * .4
	if normal.y > .65 and (slot.velocity.length_squared() < .25 or slot.contacts >= 3):
		slot.motion = Motion.RESTING
		slot.velocity = Vector3.ZERO
	elif slot.contacts >= 6:
		_retire(slot)
