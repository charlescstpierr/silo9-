extends Node3D

const Spec = preload("res://scripts/data/circuit_spec.gd")
var spec: Spec
var powered: bool = true
var breaker: StaticBody3D
var lever: Node3D
var status: Label3D
var fan: Node3D
var rotor: MultiMeshInstance3D
var airflow: AudioStreamPlayer3D
var alarm: AudioStreamPlayer3D
var alarm_lens: MeshInstance3D
var leaves: Array[StaticBody3D] = []
var closed: bool = false
var alarm_remaining: float = 0.0
var cooldown_remaining: float = 0.0
var closure_query := PhysicsShapeQueryParameters3D.new()
var _box := BoxMesh.new()

func build(config: Spec, body: StaticBody3D, palette: Dictionary) -> void:
	spec = config
	breaker = body
	for child: Node in breaker.get_children():
		if child is MeshInstance3D: child.queue_free()
	part(breaker, Vector3(0, 0.8, 0), Vector3(0.85, 1.6, 0.5), palette.teal)
	for x: float in [-0.48, 0.48]:
		part(breaker, Vector3(x, 0.85, 0.08), Vector3(0.12, 1.85, 0.65), palette.yellow)
	part(breaker, Vector3(0, 1.05, 0.27), Vector3(0.52, 0.85, 0.06), palette.dark)
	lever = Node3D.new()
	lever.position = Vector3(0, 1.05, 0.36)
	breaker.add_child(lever)
	part(lever, Vector3(0, 0.22, 0), Vector3(0.08, 0.44, 0.08), palette.steel)
	part(lever, Vector3(0, 0.44, 0), Vector3(0.36, 0.14, 0.16), palette.yellow)
	status = Label3D.new()
	status.position = Vector3(0, 1.6, 0.32)
	status.font_size = 30
	status.pixel_size = 0.002
	breaker.add_child(status)
	fan = Node3D.new()
	fan.name = "fan_" + str(spec.id)
	fan.position = spec.fan_position
	add_child(fan)
	part(fan, Vector3.ZERO, Vector3(1.1, 1.1, 0.12), palette.dark)
	for x: float in [-0.55, 0.55]: part(fan, Vector3(x, 0, 0.08), Vector3(0.08, 1.2, 0.12), palette.yellow)
	var hull := StaticBody3D.new()
	fan.add_child(hull)
	var hull_shape := CollisionShape3D.new()
	var hull_box := BoxShape3D.new()
	hull_box.size = Vector3(1.2, 1.2, 0.2)
	hull_shape.shape = hull_box
	hull.add_child(hull_shape)
	rotor = MultiMeshInstance3D.new()
	rotor.name = "Rotor"
	rotor.position.z = 0.15
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = _box
	multi.instance_count = 3
	for i: int in 3:
		var angle: float = i * TAU / 3.0
		multi.set_instance_transform(i, Transform3D(Basis(Vector3.FORWARD, angle).scaled_local(Vector3(0.18, 0.42, 0.06)), Vector3(sin(angle) * 0.23, cos(angle) * 0.23, 0)))
	rotor.multimesh = multi
	rotor.material_override = palette.steel
	fan.add_child(rotor)
	airflow = sound(fan, Vector3.ZERO, tone(1.0, true), -31, 9)
	alarm = sound(self, spec.alarm_position, tone(spec.alarm_duration, false), -13, 16)
	alarm_lens = part(self, spec.alarm_position, Vector3(0.35, 0.16, 0.2), palette.glow)
	alarm_lens.visible = false
	var query_shape := BoxShape3D.new()
	query_shape.size = Vector3(1.0, 3.4, 0.35)
	var clearance := BoxShape3D.new()
	clearance.size = query_shape.size + Vector3.ONE * 0.2
	closure_query.shape = clearance
	closure_query.collision_mask = 3
	for side: float in [-1.0, 1.0]:
		var leaf := StaticBody3D.new()
		leaf.name = "SasGauche" if side < 0 else "SasDroit"
		leaf.position = Vector3(side * 2.1, 5.1, spec.gate_z)
		leaf.collision_layer = 0
		add_child(leaf)
		var collision := CollisionShape3D.new()
		collision.shape = query_shape
		leaf.add_child(collision)
		part(leaf, Vector3.ZERO, query_shape.size, palette.teal)
		part(leaf, Vector3(0, 0, 0.2), Vector3(0.12, 3.2, 0.06), palette.yellow)
		leaves.append(leaf)
	assert(is_instance_valid(rotor) and is_instance_valid(alarm) and leaves.size() == 2)

func part(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _box
	mesh.position = pos
	mesh.scale = size
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func sound(parent: Node3D, pos: Vector3, stream: AudioStreamWAV, volume: float, distance: float) -> AudioStreamPlayer3D:
	var audio := AudioStreamPlayer3D.new()
	audio.position = pos
	audio.stream = stream
	audio.volume_db = volume
	audio.max_distance = distance
	parent.add_child(audio)
	return audio

func tone(duration: float, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 11025
	var count: int = int(duration * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i: int in count:
		var t: float = float(i) / stream.mix_rate
		var sample: float = sin(TAU * (73.0 if looped else 660.0) * t)
		var envelope: float = 1.0 if looped else sin(PI * t / duration) * (0.4 + 0.6 * pow(sin(TAU * 3 * t), 2))
		bytes.encode_s16(i * 2, int(sample * envelope * 9000))
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func apply(enabled: bool) -> void:
	powered = enabled
	if not powered: _pose_leaves(false)
	if powered and not airflow.playing: airflow.play()
	elif not powered: airflow.stop()
	lever.rotation.x = -0.55 if powered else 2.55
	status.text = spec.title + "\n" + ("ON · SOUS TENSION" if powered else "OFF · HORS TENSION")
	breaker.set_meta("prompt", ("Couper " if powered else "Rétablir ") + spec.title.to_lower())
	if powered: stop_alarm()

func cut_alarm() -> bool:
	if cooldown_remaining > 0: return false
	cooldown_remaining = spec.alarm_cooldown
	alarm_remaining = spec.alarm_duration
	alarm_lens.visible = true
	alarm.play()
	return true

func stop_alarm() -> void:
	alarm_remaining = 0
	alarm.stop()
	alarm_lens.visible = false

func _pose_leaves(value: bool) -> void:
	closed = value
	for leaf: StaticBody3D in leaves:
		leaf.position.y = 1.7 if value else 5.1
		leaf.collision_layer = 1 if value else 0

func _physics_process(_delta: float) -> void:
	if not powered or closed: return
	for leaf: StaticBody3D in leaves:
		closure_query.transform = Transform3D(Basis.IDENTITY, Vector3(leaf.global_position.x, 1.7, spec.gate_z))
		for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(closure_query, 64):
			if hit.collider is CharacterBody3D: return
	_pose_leaves(true)

func _process(delta: float) -> void:
	if powered: rotor.rotation.z += delta * 1.2
	cooldown_remaining = maxf(0, cooldown_remaining - delta)
	if alarm_remaining > 0:
		alarm_remaining -= delta
		if alarm_remaining <= 0: stop_alarm()
