class_name CircuitSpec
extends Resource

@export var id: StringName
@export var title: String
@export var sector: String
@export var breaker_position: Vector3
@export var fan_position: Vector3
@export var gate_z: float
@export var alarm_position: Vector3
@export var alarm_duration: float = 1.5
@export var alarm_cooldown: float = 8.0
@export var alarm_radius: float = 12.0

func valid() -> bool:
	return id in [&"maintenance", &"archives"] and not title.is_empty() and not sector.is_empty() and breaker_position.is_finite() and fan_position.is_finite() and alarm_position.is_finite() and is_finite(gate_z) and alarm_duration > 0 and is_finite(alarm_duration) and alarm_cooldown >= alarm_duration and is_finite(alarm_cooldown) and alarm_radius > 0 and is_finite(alarm_radius)

static func at_z(z: float) -> StringName:
	if z <= -14 and z > -34: return &"maintenance"
	if z <= -34 and z > -54: return &"archives"
	return &""
