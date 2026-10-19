extends RefCounted

static var materials: Array[StandardMaterial3D] = []
static var crawler_materials: Array[StandardMaterial3D] = []
static var sentry_legs: Array[ArrayMesh] = []
static var crawler_legs: Array[ArrayMesh] = []
static var hull: ArrayMesh
static var cylinder: CylinderMesh
static var cube: BoxMesh
static var cached_sentry: Array[ArrayMesh] = []
static var cached_crawler: Array[ArrayMesh] = []
static var cached_friendly: Array[ArrayMesh] = []
static var _fallen_sentry: Array[ArrayMesh] = []
static var _fallen_crawler: Array[ArrayMesh] = []

static func build(parent: Node3D, crawler: bool, eye_material: Material, friendly: bool = false) -> Array[MeshInstance3D]:
	_prepare()
	var cached: Array[ArrayMesh] = cached_friendly if friendly else (cached_crawler if crawler else cached_sentry)
	if cached.is_empty():
		cached.assign(_geometry(crawler, friendly))
		if friendly:
			cached_friendly = cached
		elif crawler:
			cached_crawler = cached
		else:
			cached_sentry = cached
	var palette: Array[StandardMaterial3D] = crawler_materials if crawler or friendly else materials
	for index in cached.size():
		if cached[index] != null:
			_instance(parent, cached[index], Vector3.ONE, Vector3.ZERO, palette[index])
	_build_legs(parent, crawler, palette)
	var body := _instance(parent, hull, Vector3(0.65, 0.25 if crawler else 0.56, 0.49), Vector3(0, 0.38 if crawler else 1.12, 0), palette[0])
	var eye := _instance(parent, cube, Vector3(0.28 if crawler else 0.31, 0.1, 0.04), Vector3(0, 0.44 if crawler else 1.56, -0.275), eye_material)
	return [body, eye]

static func _prepare() -> void:
	if hull != null:
		return
	for color in ["477b9d", "142c48", "ff9b38", "a6cbd8", "f4e5bc"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.metallic = 0.22
		material.roughness = 0.62
		materials.append(material)
	for color in ["38b7ba", "183c51", "f4e5bc", "98d5dc", "fff4d8"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.metallic = 0.18
		material.roughness = 0.62
		crawler_materials.append(material)
	hull = _chamfered_hull()
	cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	cylinder.radial_segments = 12
	cylinder.rings = 1
	cube = BoxMesh.new()

static func _geometry(crawler: bool, friendly: bool = false) -> Array[ArrayMesh]:
	var batches: Array[SurfaceTool] = []
	for index in materials.size():
		var batch := SurfaceTool.new()
		batch.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches.append(batch)
	if crawler:
		_add(batches[1], hull, Vector3(0.38, 0.14, 0.42), Vector3(0, 0.24, 0))
		_add(batches[2], hull, Vector3(0.42, 0.08, 0.32), Vector3(0, 0.55, 0.01))
		_add(batches[1], hull, Vector3(0.39, 0.16, 0.09), Vector3(0, 0.44, -0.23))
		for side in [-1.0, 1.0]:
			_beam(batches[3], Vector3(side * 0.17, 0.23, -0.21), Vector3(side * 0.25, 0.14, -0.4), 0.055)
			_beam(batches[2], Vector3(side * 0.25, 0.14, -0.4), Vector3(side * 0.11, 0.12, -0.5), 0.045)
		for z in [-0.05, 0.02, 0.09]:
			_add(batches[4], cube, Vector3(0.24, 0.006, 0.014), Vector3(0, 0.594, z))
	else:
		_add(batches[1], hull, Vector3(0.44, 0.2, 0.35), Vector3(0, 0.78, 0))
		_add(batches[3], cylinder, Vector3(0.18, 0.18, 0.18), Vector3(0, 1.44, 0))
		_add(batches[0], hull, Vector3(0.52, 0.29, 0.43), Vector3(0, 1.6, 0))
		_add(batches[1], hull, Vector3(0.42, 0.16, 0.1), Vector3(0, 1.56, -0.215))
		_add(batches[2], hull, Vector3(0.54, 0.055, 0.48), Vector3(0, 1.75, -0.025))
		_add(batches[1], hull, Vector3(0.38, 0.42, 0.19), Vector3(0, 1.16, 0.29))
		for side in [-1.0, 1.0]:
			_beam(batches[3], Vector3(side * 0.245, 1.47, -0.28), Vector3(side * 0.245, 1.73, -0.28), 0.025)
			_add(batches[2], hull, Vector3(0.16, 0.26, 0.32), Vector3(side * 0.35, 1.24, 0))
			if friendly:
				_beam(batches[3], Vector3(side * 0.35, 1.13, 0), Vector3(side * 0.38, 0.86, -0.04), 0.075)
				_add(batches[2], hull, Vector3(0.12, 0.12, 0.16), Vector3(side * 0.38, 0.8, -0.04))
			else:
				_beam(batches[1], Vector3(side * 0.34, 1.15, -0.05), Vector3(side * 0.34, 1.08, -0.34), 0.12)
			_add(batches[4], cube, Vector3(0.11, 0.025, 0.008), Vector3(side * 0.17, 1.27, -0.249))
		for y in [1.03, 1.08, 1.13]:
			_add(batches[1], cube, Vector3(0.27, 0.018, 0.012), Vector3(0, y, -0.249))
		_add(batches[2], cube, Vector3(0.055, 0.15, 0.01), Vector3(0, 1.27, -0.25))
	var result: Array[ArrayMesh] = []
	for batch in batches:
		result.append(batch.commit() if batch.commit_to_arrays()[Mesh.ARRAY_VERTEX] != null else null)
	return result

static func _build_legs(parent: Node3D, crawler: bool, palette: Array[StandardMaterial3D]) -> void:
	var meshes: Array[ArrayMesh] = crawler_legs if crawler else sentry_legs
	if meshes.is_empty():
		meshes.assign(_leg_geometry(crawler))
		if crawler:
			crawler_legs = meshes
		else:
			sentry_legs = meshes
	var rig := Node3D.new()
	rig.name = "RobotLegs"
	parent.add_child(rig)
	for side in [-1.0, 1.0]:
		for index in (3 if crawler else 1):
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.24, 0.29, (index - 1) * 0.2) if crawler else Vector3(side * 0.23, 0.76, 0)
			leg.scale.x = side
			leg.rotation.y = (index - 1) * -0.4 * side if crawler else 0.0
			leg.set_meta("base_y", leg.rotation.y)
			leg.set_meta("side", side)
			rig.add_child(leg)
			for material_index in meshes.size():
				_instance(leg, meshes[material_index], Vector3.ONE, Vector3.ZERO, palette[material_index])

static func _leg_geometry(crawler: bool) -> Array[ArrayMesh]:
	var batches: Array[SurfaceTool] = []
	for index in (2 if crawler else 4):
		var batch := SurfaceTool.new()
		batch.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches.append(batch)
	if crawler:
		_beam(batches[0], Vector3.ZERO, Vector3(0.2, -0.06, 0), 0.07)
		_add(batches[0], cylinder, Vector3(0.095, 0.07, 0.095), Vector3(0.2, -0.06, 0), Vector3(0, 0, PI / 2))
		_beam(batches[1], Vector3(0.2, -0.06, 0), Vector3(0.28, -0.25, 0), 0.045)
	else:
		_add(batches[3], cylinder, Vector3(0.17, 0.09, 0.17), Vector3(0.01, 0, 0), Vector3(0, 0, PI / 2))
		_beam(batches[0], Vector3(-0.01, -0.03, 0), Vector3(0.03, -0.33, 0.05), 0.15)
		_add(batches[2], hull, Vector3(0.18, 0.13, 0.17), Vector3(0.03, -0.33, -0.04))
		_beam(batches[1], Vector3(0.03, -0.36, 0.05), Vector3(0.02, -0.64, -0.04), 0.12)
		_beam(batches[3], Vector3(0.06, -0.12, -0.05), Vector3(0.06, -0.58, -0.12), 0.04)
		_add(batches[0], hull, Vector3(0.23, 0.13, 0.34), Vector3(0.02, -0.685, -0.08))
	var result: Array[ArrayMesh] = []
	for batch in batches:
		result.append(batch.commit())
	return result

static func animate_legs(rig: Node3D, crawler: bool, phase: float, speed: float) -> void:
	var amplitude: float = minf(speed * 0.15, 0.3)
	var index: int = 0
	for leg: Node3D in rig.get_children():
		var wave: float = sin(phase + (index % 2) * PI)
		if crawler:
			var side: float = leg.get_meta("side")
			leg.rotation.z = maxf(0, wave) * amplitude * side
			leg.rotation.y = float(leg.get_meta("base_y")) + cos(phase + (index % 2) * PI) * amplitude * 0.4
		else:
			leg.rotation.x = wave * amplitude
		index += 1

static func _add(batch: SurfaceTool, mesh: Mesh, size: Vector3, position: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	batch.append_from(mesh, 0, Transform3D(Basis.from_euler(rotation).scaled(size), position))

static func _beam(batch: SurfaceTool, start: Vector3, end: Vector3, width: float) -> void:
	var axis := (end - start).normalized()
	var reference := Vector3.FORWARD if absf(axis.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x_axis := axis.cross(reference).normalized()
	var basis := Basis(x_axis * width, axis * start.distance_to(end), x_axis.cross(axis) * width)
	batch.append_from(cylinder, 0, Transform3D(basis, (start + end) * 0.5))

static func _instance(parent: Node3D, mesh: Mesh, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.scale = size
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _chamfered_hull() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline: Array[Vector2] = [Vector2(-0.35, -0.5), Vector2(0.35, -0.5), Vector2(0.5, -0.35), Vector2(0.5, 0.35), Vector2(0.35, 0.5), Vector2(-0.35, 0.5), Vector2(-0.5, 0.35), Vector2(-0.5, -0.35)]
	var levels: Array[float] = [-0.5, -0.38, 0.38, 0.5]
	var rings: Array[float] = [0.8, 1.0, 1.0, 0.8]
	for ring in 3:
		for index in 8:
			var next: int = (index + 1) % 8
			var a := Vector3(outline[index].x * rings[ring], levels[ring], outline[index].y * rings[ring])
			var b := Vector3(outline[next].x * rings[ring], levels[ring], outline[next].y * rings[ring])
			var c := Vector3(outline[next].x * rings[ring + 1], levels[ring + 1], outline[next].y * rings[ring + 1])
			var d := Vector3(outline[index].x * rings[ring + 1], levels[ring + 1], outline[index].y * rings[ring + 1])
			for vertex in [a, b, c, a, c, d]:
				tool.add_vertex(vertex)
	for index in 8:
		var next: int = (index + 1) % 8
		for vertex in [Vector3.ZERO + Vector3.UP * 0.5, Vector3(outline[index].x * 0.8, 0.5, outline[index].y * 0.8), Vector3(outline[next].x * 0.8, 0.5, outline[next].y * 0.8), Vector3.DOWN * 0.5, Vector3(outline[next].x * 0.8, -0.5, outline[next].y * 0.8), Vector3(outline[index].x * 0.8, -0.5, outline[index].y * 0.8)]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	tool.index()
	return tool.commit()

static func build_remains(parent: Node3D, crawler: bool) -> void:
	_prepare()
	var meshes: Array[ArrayMesh] = _fallen_crawler if crawler else _fallen_sentry
	if meshes.is_empty():
		meshes = _remains_geometry(crawler)
		if crawler: _fallen_crawler = meshes
		else: _fallen_sentry = meshes
	for index in meshes.size():
		var instance := _instance(parent, meshes[index], Vector3.ONE, Vector3.ZERO, materials[index])
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = 45

static func _remains_geometry(crawler: bool) -> Array[ArrayMesh]:
	var batches: Array[SurfaceTool] = []
	for index in 3:
		var batch := SurfaceTool.new()
		batch.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches.append(batch)
	var fallen := Transform3D(Basis.IDENTITY.scaled(Vector3(1, 0.45, 1)), Vector3(0, 0.025, 0)) if crawler else Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(0, 0.36, -0.85))
	var palette: Array[int] = [0, 1, 2, 1, 2]
	var body: Array[ArrayMesh] = _geometry(crawler)
	for index in body.size():
		if body[index] != null: batches[palette[index]].append_from(body[index], 0, fallen)
	var legs: Array[ArrayMesh] = _leg_geometry(crawler)
	var mirrored_legs: Array[ArrayMesh] = []
	for mesh: ArrayMesh in legs: mirrored_legs.append(_reversed_winding(mesh))
	for side in [-1.0, 1.0]:
		for index in (3 if crawler else 1):
			var origin := Vector3(side * 0.24, 0.29, (index - 1) * 0.2) if crawler else Vector3(side * 0.23, 0.76, 0)
			var angle: float = (index - 1) * -0.4 * side if crawler else 0.0
			var leg := Transform3D(Basis.from_euler(Vector3(0, angle, 0)).scaled_local(Vector3(side, 1, 1)), origin)
			for material_index in legs.size():
				batches[palette[material_index]].append_from(mirrored_legs[material_index] if side < 0 else legs[material_index], 0, fallen * leg)
	var hull_size := Vector3(0.65, 0.25 if crawler else 0.56, 0.49)
	var hull_position := Vector3(0, 0.38 if crawler else 1.12, 0)
	batches[0].append_from(hull, 0, fallen * Transform3D(Basis.IDENTITY.scaled(hull_size), hull_position))
	batches[1].append_from(cube, 0, fallen * Transform3D(Basis.IDENTITY.scaled(Vector3(0.28 if crawler else 0.31, 0.1, 0.04)), Vector3(0, 0.44 if crawler else 1.56, -0.275)))
	var result: Array[ArrayMesh] = []
	for batch in batches: result.append(batch.commit())
	return result

static func _reversed_winding(mesh: ArrayMesh) -> ArrayMesh:
	var arrays: Array = mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for triangle in range(0, indices.size(), 3):
		var second: int = indices[triangle + 1]
		indices[triangle + 1] = indices[triangle + 2]
		indices[triangle + 2] = second
	arrays[Mesh.ARRAY_INDEX] = indices
	var reversed := ArrayMesh.new()
	reversed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return reversed
