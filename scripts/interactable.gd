class_name SiloInteractable
extends StaticBody3D
signal disabled
var electrical: bool = false
var is_disabled: bool = false
func receive_hit(_damage: float, stun: float) -> void:
	if electrical and stun > 0.0 and not is_disabled:
		is_disabled = true
		disabled.emit()
