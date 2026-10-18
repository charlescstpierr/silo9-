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
	var batches := _batches(materials)
	_part(batches[1], Vector3(0.104, 0.067, 0.34), Vector3(0, 0.035, -0.035), 0.012)
	_part(batches[2], Vector3(0.065, 0.135, 0.105), Vector3(0, -0.06, 0.075), 0.018, Vector3(-0.22, 0, 0))
	if electric:
		_part(batches[1], Vector3(0.075, 0.025, 0.118), Vector3(0, -0.125, 0.089), 0.008)
	for side: float in [-1.0, 1.0]:
		_part(batches[0], Vector3(0.008, 0.095, 0.063), Vector3(side * 0.034, -0.055, 0.08), 0.002, Vector3(-0.22, 0, 0))
		for rib in 6:
			_part(batches[2], Vector3(0.011, 0.008, 0.061), Vector3(side * 0.035, -0.095 + rib * 0.014, 0.08), 0.002, Vector3(-0.22, 0, 0))
	_part(batches[0], Vector3(0.078, 0.018, 0.132), Vector3(0, -0.065, -0.03), 0.005)
	_part(batches[0], Vector3(0.078, 0.082, 0.018), Vector3(0, -0.027, -0.093), 0.005, Vector3(0.22, 0, 0))
	_part(batches[2], Vector3(0.015, 0.051, 0.014), Vector3(0, -0.024, -0.015), 0.003, Vector3(-0.33, 0, 0))
	if electric:
		_part(batches[1], Vector3(0.078, 0.025, 0.12), Vector3(0, 0.003, -0.21), 0.005)
		_part(batches[2], Vector3(0.065, 0.14, 0.10), Vector3(0, -0.07, -0.21), 0.012)
		_part(batches[3], Vector3(0.075, 0.016, 0.108), Vector3(0, -0.14, -0.21), 0.004)
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
		_arc_parts(root, materials)
		_part(batches[1], Vector3(.014, .13, .018), Vector3(0, .175, -.25), .003)
		_part(batches[1], Vector3(.052, .09, .018), Vector3(0, .20, .10), .004)
		_sights(root, batches, .27, .10, -.25)
	else:
		var slide := Node3D.new()
		slide.name = "Slide"
		root.add_child(slide)
		var slide_batches := _batches(materials)
		_part(slide_batches[0], Vector3(0.108, 0.076, 0.3), Vector3(0, 0.104, -0.048), 0.012)
		_part(slide_batches[1], Vector3(0.06, 0.012, 0.245), Vector3(0, 0.146, -0.055), 0.004)
		_part(slide_batches[2], Vector3(0.04, 0.012, 0.084), Vector3(0.018, 0.146, -0.025), 0.002)
		_part(slide_batches[3], Vector3(0.012, 0.004, 0.065), Vector3(0.019, 0.153, -0.022), 0.001)
		for side: float in [-1.0, 1.0]:
			for groove in 5:
				_part(slide_batches[2], Vector3(0.003, 0.045, 0.008), Vector3(side * 0.055, 0.1, 0.04 + groove * 0.012), 0.001, Vector3(-0.2, 0, 0))
			_part(slide_batches[3], Vector3(0.004, 0.009, 0.074), Vector3(side * 0.054, 0.057, -0.094), 0.002)
		_sights(slide, slide_batches, .169, .093, -.163)
		_cylinder(batches[1], 0.026, 0.18, Vector3(0, 0.087, -0.165))
		_tube(batches[0], 0.029, 0.015, 0.035, Vector3(0, 0.087, -0.267))
		_cylinder(batches[2], 0.015, 0.004, Vector3(0, 0.087, -0.247))
		_meshes(slide, slide_batches)
		_marker(slide, "Grip", Vector3(-.083,.09,.095), Basis(Vector3.DOWN,Vector3.FORWARD,Vector3.RIGHT))
		var magazine := Node3D.new()
		magazine.name = "Magazine"
		magazine.position = Vector3(0,-.125,.089)
		root.add_child(magazine)
		var mag_batches := _batches(materials)
		_part(mag_batches[2],Vector3(.053,.125,.077),Vector3(0,.055,-.006),.008,Vector3(-.22,0,0))
		_part(mag_batches[1],Vector3(.075,.025,.118),Vector3.ZERO,.008)
		_part(mag_batches[3],Vector3(.045,.009,.068),Vector3(0,-.015,.009),.003)
		_meshes(magazine,mag_batches)
		_marker(magazine,"Grip",Vector3(-.065,-.005,.055),Basis(Vector3.DOWN,Vector3.FORWARD,Vector3.RIGHT))
		_marker(root,"MagazineSeat",magazine.position,Basis.IDENTITY)
		_marker(root,"Ejection",Vector3(.058,.13,-.025),Basis.IDENTITY)
	for side: float in [-1.0, 1.0]:
		for depth: float in [-0.12, 0.085]:
			_cylinder(batches[0], 0.006, 0.005, Vector3(side * 0.055, 0.035, depth), Vector3(0, 0, PI * 0.5))
	_meshes(root,batches)
	var grip_basis := Basis(Vector3.UP, Vector3.FORWARD, Vector3.LEFT)
	for entry: Array in [["GripRight", Vector3(0.035, -0.07, 0.158), Basis(Vector3.UP, -0.35) * grip_basis], ["GripLeft", Vector3(-0.062, -0.10, -0.12) if electric else Vector3(-0.068, -0.10, 0.13), Basis(Vector3.DOWN, Vector3.FORWARD, Vector3.RIGHT)], ["Muzzle", Vector3(0, 0.087, -0.31), Basis.IDENTITY]]:
		var marker := Marker3D.new()
		marker.name = entry[0]
		marker.transform = Transform3D(entry[2], entry[1])
		root.add_child(marker)
	return root

static func _sights(parent: Node3D, batches: Array[SurfaceTool], height: float, rear_z: float, front_z: float) -> void:
	var front := Vector3(0, height, front_z)
	var rear := Vector3(0, height, rear_z)
	_part(batches[1], Vector3(.014, .03, .018), front - Vector3(0, .015, 0), .002)
	_part(batches[4], Vector3(.006, .008, .006), front + Vector3(0, -.004, .009), .001)
	for side: float in [-1.0, 1.0]:
		_part(batches[1], Vector3(.012, .025, .016), rear + Vector3(side * .019, -.0125, 0), .002)
		_part(batches[4], Vector3(.004, .004, .004), rear + Vector3(side * .019, -.004, .008), .001)
	_marker(parent, "SightRear", rear, Basis.IDENTITY)
	_marker(parent, "SightFront", front, Basis.IDENTITY)

static func _arc_parts(root: Node3D, materials: Array[StandardMaterial3D]) -> void:
	var socket := Node3D.new()
	socket.name = "ArcSocket"
	socket.position = Vector3(-.06,.19,.015)
	root.add_child(socket)
	var shell := _batches(materials)
	for y in [-.045,.045]:
		_part(shell[0],Vector3(.13,.014,.14),Vector3(0,y,0),.004)
	for z in [-.063,.063]:
		_part(shell[1],Vector3(.13,.08,.014),Vector3(0,0,z),.004)
	_part(shell[2],Vector3(.012,.08,.12),Vector3(.065,0,0),.003)
	for z in [-.032,.032]:
		_part(shell[3],Vector3(.01,.027,.018),Vector3(.055,0,z),.002)
	_meshes(socket,shell)
	var cell := Node3D.new()
	cell.name = "ArcCell"
	cell.position = Vector3(-.075,.19,.015)
	root.add_child(cell)
	var capsule := _batches(materials)
	_part(capsule[1],Vector3(.10,.068,.105),Vector3.ZERO,.013)
	_part(capsule[0],Vector3(.014,.076,.112),Vector3(-.045,0,0),.008)
	for z in [-.032,.032]:
		_part(capsule[3],Vector3(.012,.025,.018),Vector3(.052,0,z),.002)
	_part(capsule[2],Vector3(.009,.055,.07),Vector3(-.055,0,0),.004)
	_meshes(cell,capsule)
	_marker(cell,"CellGrip",Vector3(-.065,-.06,0),Basis(Vector3.BACK,Vector3.RIGHT,Vector3.UP))
	var latch := Node3D.new()
	latch.name = "ArcLatch"
	latch.position = Vector3(-.14,.235,.015)
	root.add_child(latch)
	var lever := _batches(materials)
	_part(lever[3],Vector3(.018,.072,.018),Vector3(0,-.028,0),.005)
	_part(lever[0],Vector3(.064,.08,.10),Vector3(.02,-.06,0),.006)
	_meshes(latch,lever)
	_marker(latch,"LatchGrip",Vector3(-.036,-.06,.04),Basis(Vector3.DOWN,Vector3.FORWARD,Vector3.RIGHT))
	var indicator := Node3D.new()
	indicator.name = "EnergyIndicator"
	indicator.position = Vector3(0,.15,.123)
	root.add_child(indicator)
	var light := _batches(materials)
	_part(light[4],Vector3(.08,.012,.008),Vector3.ZERO,.002)
	_meshes(indicator,light)
	var housing := _batches(materials)
	_part(housing[2],Vector3(.09,.03,.04),Vector3(0,.145,.10),.003)
	_meshes(root,housing)
	var connection := Node3D.new()
	connection.name = "ConnectionIndicator"
	connection.position = Vector3(-.06,.25,.08)
	root.add_child(connection)
	var connected := _batches(materials)
	_part(connected[4],Vector3(.012,.008,.008),Vector3.ZERO,.002)
	_meshes(connection,connected)

static func _batches(materials: Array[StandardMaterial3D]) -> Array[SurfaceTool]:
	var result: Array[SurfaceTool] = []
	for material in materials:
		var batch := SurfaceTool.new()
		batch.begin(Mesh.PRIMITIVE_TRIANGLES)
		batch.set_material(material)
		result.append(batch)
	return result

static func _meshes(parent: Node3D, batches: Array[SurfaceTool]) -> void:
	for batch in batches:
		if batch.commit_to_arrays()[Mesh.ARRAY_VERTEX] == null:
			continue
		var instance := MeshInstance3D.new()
		instance.mesh = batch.commit()
		instance.layers = 2
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)

static func _marker(parent: Node3D, label: String, pos: Vector3, basis: Basis) -> void:
	var marker := Marker3D.new()
	marker.name = label
	marker.transform = Transform3D(basis,pos)
	parent.add_child(marker)

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
