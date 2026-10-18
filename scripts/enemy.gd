class_name SiloEnemy
extends CharacterBody3D

const State = preload("res://scripts/run_state.gd")
const RobotVisual = preload("res://scripts/robot_visual.gd")
const BULKHEAD_Z: Array[float] = [2.0, -14.0, -34.0, -54.0]
var state: State
var target: CharacterBody3D
var enemy_id: String = ""
var crawler: bool = false
var health: float = 60.0
var mode: String = "patrol"
var stunned: float = 0.0
var patrol: Array[Vector3] = []
var patrol_index: int = 0
var destination: Vector3
var portal_z: float = 0.0
var portal_direction: float = 0.0
var last_known: Vector3
var search_remaining: float = 0.0
var sense_remaining: float = 0.0
var attack_remaining: float = 0.0
var sees_target: bool = false
var body_mesh: MeshInstance3D
var eye_mesh: MeshInstance3D
var hit_remaining: float = 0.0
var eye_material: StandardMaterial3D
var leg_rig: Node3D
var stride_phase: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 3
	add_to_group("enemies")
	var height: float = 0.6 if crawler else 1.8
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = height
	capsule.radius = 0.28 if crawler else 0.4
	shape.shape = capsule
	shape.position.y = height / 2.0
	add_child(shape)
	eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color("ff7041")
	eye_material.emission_enabled = true
	eye_material.emission = Color("ff4020")
	eye_material.emission_energy_multiplier = 2.5
	var visual: Array[MeshInstance3D] = RobotVisual.build(self, crawler, eye_material)
	body_mesh = visual[0]
	eye_mesh = visual[1]
	leg_rig = get_node("RobotLegs")
	if not patrol.is_empty():
		destination = patrol[0]
	else:
		destination = global_position
	last_known = global_position

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or health <= 0.0:
		return
	if target.get("active") == false or target.global_position.distance_squared_to(global_position) > 2025.0:
		return
	stunned = maxf(0.0, stunned - delta)
	attack_remaining = maxf(0.0, attack_remaining - delta)
	hit_remaining = maxf(0.0, hit_remaining - delta)
	body_mesh.scale.x = 0.73 if hit_remaining > 0 else 0.65
	if stunned > 0.0:
		velocity.x = 0
		velocity.z = 0
		eye_material.emission = Color("77ffff")
	else:
		sense_remaining -= delta
		if sense_remaining <= 0:
			sense_remaining = 0.2
			_sense()
		_step_brain(delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()
	if stunned <= 0.0:
		var actual_speed: float = Vector2(get_real_velocity().x, get_real_velocity().z).length()
		stride_phase += actual_speed * delta * (7.0 if crawler else 4.0)
		RobotVisual.animate_legs(leg_rig, crawler, stride_phase, actual_speed)

func _sense() -> void:
	var offset: Vector3 = target.global_position - global_position
	var distance: float = offset.length()
	var forward := -global_transform.basis.z
	var in_cone: bool = distance < 3.0 or forward.dot(offset.normalized()) > 0.15 or mode == "chase"
	sees_target = false
	if distance < (10.0 if crawler else 17.0) and in_cone:
		var from := global_position + Vector3(0, 0.4 if crawler else 1.4, 0)
		var query := PhysicsRayQueryParameters3D.create(from, target.global_position + Vector3(0, 1.0, 0), 3, [get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		sees_target = hit.is_empty() or hit.collider == target
	if sees_target and mode != "retreat":
		mode = "chase"
		last_known = target.global_position
		search_remaining = 5.0
	elif mode == "chase" and not sees_target:
		mode = "search"
		destination = last_known
	eye_material.emission = Color("ff3010") if mode == "chase" else Color("ffa83b")

func _step_brain(delta: float) -> void:
	var speed: float = 1.6 if not crawler else 2.5
	match mode:
		"patrol":
			if not patrol.is_empty() and global_position.distance_to(destination) < 0.7:
				patrol_index = (patrol_index + 1) % patrol.size()
				destination = patrol[patrol_index]
		"chase":
			destination = target.global_position
			speed = 4.1 if crawler else 2.6
			var attack_range: float = 1.4 if crawler else 7.0
			if sees_target and global_position.distance_to(target.global_position) < attack_range:
				speed = 0.0
				if attack_remaining <= 0.0:
					if target.has_method("apply_damage"):
						target.call("apply_damage", 9.0 if crawler else 7.0)
					attack_remaining = 1.25 if crawler else 1.6
					_flash_attack()
					if crawler:
						mode = "retreat"
						destination = global_position + (global_position - target.global_position).normalized() * 4.0
						search_remaining = 1.3
		"investigate", "search":
			search_remaining -= delta
			if search_remaining <= 0.0:
				mode = "return"
				destination = patrol[patrol_index] if not patrol.is_empty() else global_position
		"retreat":
			speed = 4.5
			search_remaining -= delta
			if search_remaining <= 0:
				mode = "search"
				destination = last_known
				search_remaining = 4.0
		"return":
			if global_position.distance_to(destination) < 0.8:
				mode = "patrol"
	var waypoint: Vector3 = _route_waypoint(destination)
	var direction := waypoint - global_position
	direction.y = 0
	if direction.length() < 0.4:
		speed = 0
	else:
		direction = direction.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.12)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func _route_waypoint(goal: Vector3) -> Vector3:
	if portal_direction != 0.0:
		var goal_across: bool = (goal.z - portal_z) * portal_direction > 0.0
		var cleared: bool = (global_position.z - portal_z) * portal_direction >= 0.9
		if not goal_across or cleared:
			portal_direction = 0.0
	if portal_direction == 0.0:
		var nearest: float = INF
		for boundary in BULKHEAD_Z:
			if (global_position.z - boundary) * (goal.z - boundary) < 0.0:
				var distance: float = absf(global_position.z - boundary)
				if distance < nearest:
					nearest = distance
					portal_z = boundary
					portal_direction = signf(goal.z - boundary)
	if portal_direction == 0.0:
		return goal
	if absf(global_position.x) > 1.2:
		return Vector3(0, global_position.y, global_position.z)
	return Vector3(0, global_position.y, portal_z + portal_direction * 1.3)

func _flash_attack() -> void:
	eye_mesh.scale.y = 0.32
	create_tween().tween_property(eye_mesh, "scale:y", 0.1, 0.15)

func hear_noise(origin: Vector3, radius: float) -> void:
	if health <= 0.0 or global_position.distance_to(origin) > radius * (1.4 if crawler else 1.0):
		return
	if mode != "chase":
		mode = "investigate"
		destination = origin
		last_known = origin
		search_remaining = 7.0

func receive_hit(damage: float, stun: float) -> void:
	if health <= 0.0:
		return
	health = maxf(0, health - damage)
	stunned = maxf(stunned, stun)
	hit_remaining = 0.18
	if is_instance_valid(target):
		hear_noise(target.global_position, 100)
	if health <= 0:
		if state != null:
			state.mark_defeated(enemy_id)
		collision_layer = 0
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(self, "rotation:z", 1.5, 0.3)
		tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.45).set_delay(1.5)
		tween.tween_callback(queue_free)
