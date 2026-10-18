extends RefCounted

const Spec = preload("res://scripts/data/circuit_spec.gd")
var records: Dictionary = {}

func for_sector(source: Material, circuit: StringName) -> Material:
	if not source is BaseMaterial3D or not source.emission_enabled: return source
	var key: String = str(circuit) + ":" + str(source.get_instance_id())
	if not records.has(key):
		var copy: BaseMaterial3D = source.duplicate()
		records[key] = {"material": copy, "circuit": circuit, "albedo": source.albedo_color, "emission": source.emission, "energy": source.emission_energy_multiplier}
	return records[key].material

func at_position(source: Material, pos: Vector3) -> Material:
	return for_sector(source, Spec.at_z(pos.z))

func apply(state: SiloState) -> void:
	for record: Dictionary in records.values():
		var powered: bool = record.circuit == &"" or state.circuit_on(record.circuit)
		var material: BaseMaterial3D = record.material
		material.albedo_color = record.albedo if powered else record.albedo.darkened(0.8)
		material.emission_energy_multiplier = record.energy if powered else 0.0
		material.emission = record.emission if state.ending.is_empty() else (Color("ff6737") if state.ending == "mother" else Color("63e9e0"))
