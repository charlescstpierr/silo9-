class_name SiloWeaponVisual
extends RefCounted

static func build(electric: bool) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * 0.76
	root.position = Vector3(-0.01, -0.005, -0.12)
	var materials: Array[StandardMaterial3D] = [
		_material(Color("608da7") if not electric else Color("466677"), 0.16, 0.42),
		_material(Color("314e66"), 0.12, 0.48),
		_material(Color("263844"), 0.05, 0.7),
		_material(Color("e7ad57"), 0.3, 0.4),
		_material(Color("62c9ce") if electric else Color("edb76d"), 0.15, 0.35, 0.8),
	]
	var batches: Array[SurfaceTool] = []
	for material in materials:
		var batch := SurfaceTool.new()
		batch.begin(Mesh.PRIMITIVE_TRIANGLES)
		batch.set_material(material)
		batches.append(batch)
	_part(batches[1], Vector3(0.104, 0.067, 0.34), Vector3(0, 0.035, -0.035), 0.012)
	_part(batches[2], Vector3(0.065, 0.135, 0.105), Vector3(0, -0.06, 0.075), 0.018, Vector3(-0.22, 0, 0))
	_part(batches[1], Vector3(0.075, 0.025, 0.118), Vector3(0, -0.125, 0.089), 0.008)
	for side: float in [-1.0, 1.0]:
		_part(batches[0], Vector3(0.008, 0.095, 0.063), Vector3(side * 0.034, -0.055, 0.08), 0.002, Vector3(-0.22, 0, 0))
		for rib in 6:
			_part(batches[2], Vector3(0.011, 0.008, 0.061), Vector3(side * 0.035, -0.095 + rib * 0.014, 0.08), 0.002, Vector3(-0.22, 0, 0))
	_part(batches[0], Vector3(0.078, 0.018, 0.132), Vector3(0, -0.065, -0.03), 0.005)
	_part(batches[0], Vector3(0.078, 0.082, 0.018), Vector3(0, -0.027, -0.093), 0.005, Vector3(0.22, 0, 0))
	_part(batches[2], Vector3(0.015, 0.051, 0.014), Vector3(0, -0.024, -0.015), 0.003, Vector3(-0.33, 0, 0))
	if electric:
		_part(batches[0], Vector3(0.132, 0.105, 0.2), Vector3(0, 0.087, 0.005), 0.025)
		_part(batches[1], Vector3(0.104, 0.077, 0.26), Vector3(0, 0.078, -0.13), 0.014)
		_cylinder(batches[2], 0.039, 0.16, Vector3(0, 0.078, -0.125))
		for ring in 6:
			_tube(batches[3], 0.045, 0.032, 0.009, Vector3(0, 0.078, -0.055 - ring * 0.028))
		for side: float in [-1.0, 1.0]:
			_part(batches[0], Vector3(0.028, 0.05, 0.25), Vector3(side * 0.072, 0.083, -0.145), 0.008)
			_part(batches[4], Vector3(0.006, 0.007, 0.13), Vector3(side * 0.087, 0.091, -0.12), 0.002)
			_part(batches[1], Vector3(0.038, 0.066, 0.04), Vector3(side * 0.073, 0.083, -0.269), 0.009)
			_tube(batches[0], 0.015, 0.008, 0.043, Vector3(side * 0.073, 0.083, -0.288))
		_part(batches[4], Vector3(0.025, 0.004, 0.034), Vector3(0, 0.142, 0.045), 0.002)
	else:
		_part(batches[0], Vector3(0.108, 0.076, 0.3), Vector3(0, 0.104, -0.048), 0.012)
		_part(batches[1], Vector3(0.06, 0.012, 0.245), Vector3(0, 0.146, -0.055), 0.004)
		_cylinder(batches[1], 0.026, 0.18, Vector3(0, 0.087, -0.165))
		_tube(batches[0], 0.029, 0.015, 0.035, Vector3(0, 0.087, -0.267))
		_cylinder(batches[2], 0.015, 0.004, Vector3(0, 0.087, -0.247))
		_part(batches[2], Vector3(0.04, 0.012, 0.084), Vector3(0.018, 0.146, -0.025), 0.002)
		_part(batches[3], Vector3(0.012, 0.004, 0.065), Vector3(0.019, 0.153, -0.022), 0.001)
		for side: float in [-1.0, 1.0]:
			for groove in 5:
				_part(batches[2], Vector3(0.003, 0.045, 0.008), Vector3(side * 0.055, 0.1, 0.04 + groove * 0.012), 0.001, Vector3(-0.2, 0, 0))
			_part(batches[3], Vector3(0.004, 0.009, 0.074), Vector3(side * 0.054, 0.057, -0.094), 0.002)
		_part(batches[1], Vector3(0.015, 0.016, 0.018), Vector3(0, 0.161, -0.174), 0.003)
		_part(batches[4], Vector3(0.005, 0.006, 0.006), Vector3(0, 0.166, -0.163), 0.001)
		for side: float in [-1.0, 1.0]:
			_part(batches[1], Vector3(0.012, 0.015, 0.015), Vector3(side * 0.02, 0.158, 0.084), 0.003)
			_part(batches[4], Vector3(0.004, 0.004, 0.004), Vector3(side * 0.02, 0.16, 0.093), 0.001)
	for side: float in [-1.0, 1.0]:
		for depth: float in [-0.12, 0.085]:
			_cylinder(batches[0], 0.006, 0.005, Vector3(side * 0.055, 0.035, depth), Vector3(0, 0, PI * 0.5))
	for index in batches.size():
		var instance := MeshInstance3D.new()
		instance.mesh = batches[index].commit()
		instance.layers = 2
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(instance)
	var grip_basis := Basis(Vector3.UP, Vector3.FORWARD, Vector3.LEFT)
	for entry: Array in [["GripRight", Vector3(0.035, -0.07, 0.158), Basis(Vector3.UP, -0.35) * grip_basis], ["GripLeft", Vector3(-0.075, -0.10, -0.12) if electric else Vector3(-0.068, -0.10, 0.13), Basis(Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT)], ["Muzzle", Vector3(0, 0.087, -0.31), Basis.IDENTITY]]:
		var marker := Marker3D.new()
		marker.name = entry[0]
		marker.transform = Transform3D(entry[2], entry[1])
		root.add_child(marker)
	return root

static func _material(color: Color, metal: float, rough: float, glow: float = 0.035) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metal
	result.roughness = rough
	result.emission_enabled = true
	result.emission = color
	result.emission_energy_multiplier = glow
	return result

static func _part(batch: SurfaceTool, size: Vector3, pos: Vector3, bevel: float, angle: Vector3 = Vector3.ZERO) -> void:
	batch.append_from(_bevel_box(size, bevel), 0, Transform3D(Basis.from_euler(angle), pos))

static func _cylinder(batch: SurfaceTool, radius: float, length: float, pos: Vector3, angle: Vector3 = Vector3(PI * 0.5, 0, 0)) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	cylinder.radial_segments = 16
	cylinder.rings = 1
	batch.append_from(cylinder, 0, Transform3D(Basis.from_euler(angle), pos))

static func _tube(batch: SurfaceTool, outer: float, inner: float, length: float, pos: Vector3) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 16:
		var a := float(index) * TAU / 16.0
		var b := float(index + 1) * TAU / 16.0
		var radial_a := Vector3(cos(a), sin(a), 0)
		var radial_b := Vector3(cos(b), sin(b), 0)
		for radius: float in [outer, inner]:
			var p := radial_a * radius + Vector3(0, 0, -length * 0.5)
			var q := radial_b * radius + Vector3(0, 0, -length * 0.5)
			var normal := (radial_a + radial_b).normalized() * (1.0 if radius == outer else -1.0)
			_quad(surface, p, q, q + Vector3(0, 0, length), p + Vector3(0, 0, length), normal)
		for end: float in [-1.0, 1.0]:
			var z := Vector3(0, 0, end * length * 0.5)
			_quad(surface, radial_a * outer + z, radial_b * outer + z, radial_b * inner + z, radial_a * inner + z, Vector3(0, 0, end))
	surface.index()
	batch.append_from(surface.commit(), 0, Transform3D(Basis.IDENTITY, pos))

static func _bevel_box(size: Vector3, bevel: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := size.x * 0.5
	var y := size.y * 0.5
	var z := size.z * 0.5
	var cut := minf(bevel, minf(x, minf(y, z)) * 0.8)
	var rings: Array[PackedVector3Array] = []
	for layer in 4:
		var inset: float = cut if layer == 0 or layer == 3 else 0.0
		var depth: float = [-z, -z + cut, z - cut, z][layer]
		var width := x - inset
		var height := y - inset
		var corner := minf(cut * 0.5, minf(width, height) * 0.4)
		rings.append(PackedVector3Array([
			Vector3(width - corner, height, depth), Vector3(-width + corner, height, depth),
			Vector3(-width, height - corner, depth), Vector3(-width, -height + corner, depth),
			Vector3(-width + corner, -height, depth), Vector3(width - corner, -height, depth),
			Vector3(width, -height + corner, depth), Vector3(width, height - corner, depth)
		]))
	for layer in 3:
		for edge in 8:
			var next := (edge + 1) % 8
			var center := (rings[layer][edge] + rings[layer][next] + rings[layer + 1][next] + rings[layer + 1][edge]) * 0.25
			_quad(tool, rings[layer][edge], rings[layer][next], rings[layer + 1][next], rings[layer + 1][edge], center.normalized())
	for layer in [0, 3]:
		var normal := Vector3(0, 0, -1 if layer == 0 else 1)
		for edge in 8:
			_triangle(tool, Vector3(0, 0, rings[layer][0].z), rings[layer][edge], rings[layer][(edge + 1) % 8], normal)
	tool.index()
	return tool.commit()

static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
	_triangle(tool, a, b, c, outward)
	_triangle(tool, a, c, d, outward)

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	var vertices := [a, c, b]
	if normal.dot(outward) < 0.0:
		normal = -normal
		vertices = [a, b, c]
	for point: Vector3 in vertices:
		tool.set_normal(normal)
		tool.add_vertex(point)
