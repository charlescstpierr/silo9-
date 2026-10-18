extends StaticBody3D

const State = preload("res://scripts/run_state.gd")
const INTACT = preload("res://assets/kenney/box-large.glb")
var _state: State
var _material: Material
var _panel_mesh: BoxMesh
var _intact: Node3D
var _remains: MultiMeshInstance3D

func setup(run: State, material: Material, panel_mesh: BoxMesh) -> void:
	_state = run
	_material = material
	_panel_mesh = panel_mesh

func _ready() -> void:
	_intact = INTACT.instantiate()
	_intact.scale = Vector3.ONE * 1.5
	add_child(_intact)
	for mesh: MeshInstance3D in _intact.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _material
		mesh.visibility_range_end = 45
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65, 0.825, 1.5)
	collision.shape = shape
	collision.position.y = shape.size.y * 0.5
	add_child(collision)
	_remains = MultiMeshInstance3D.new()
	_remains.name = "CratePanels"
	var panels := MultiMesh.new()
	panels.transform_format = MultiMesh.TRANSFORM_3D
	panels.mesh = _panel_mesh
	panels.instance_count = 3
	panels.set_instance_transform(0, Transform3D(Basis.from_euler(Vector3(0, 0.12, 0)).scaled(Vector3(1.5, 0.09, 1.3)), Vector3(0, 0.065, 0)))
	panels.set_instance_transform(1, Transform3D(Basis.from_euler(Vector3(0.24, -0.3, 0.12)).scaled(Vector3(1.45, 0.1, 0.65)), Vector3(-0.25, 0.17, -0.65)))
	panels.set_instance_transform(2, Transform3D(Basis.from_euler(Vector3(-0.16, 0.45, -0.18)).scaled(Vector3(1.35, 0.1, 0.65)), Vector3(0.35, 0.16, 0.62)))
	_remains.multimesh = panels
	_remains.material_override = _material
	_remains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_remains.visibility_range_end = 45
	add_child(_remains)
	refresh()

func receive_hit(damage: float, stun: float) -> void:
	if is_finite(damage) and is_finite(stun) and damage > 0.0 and stun <= 0.0:
		_state.break_crate()

func refresh() -> void:
	var broken: bool = _state.crate_broken()
	collision_layer = 0 if broken else 1
	collision_mask = 0 if broken else 1
	_intact.visible = not broken
	_remains.visible = broken
