class_name SiloWorld
extends Node3D

const RobotVisual = preload("res://scripts/robot_visual.gd")
const Art = preload("res://scripts/world_art.gd")
const State = preload("res://scripts/run_state.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Interactable = preload("res://scripts/interactable.gd")
signal message(text: String)
signal conversation_requested(character: String)
signal ending_requested
var player: CharacterBody3D
var state: State
var spawn_position := Vector3(0, 0, 7)
var materials: Dictionary = {}
var art: Art
var objects: Dictionary = {}
var enemies: Array[Enemy] = []
var lights: Array[OmniLight3D] = []
var box_mesh := BoxMesh.new()
var relay_position := Vector3(7, 0, -26)
var scan_timer: float = 0
var pulse: MeshInstance3D
var colossus_triggered: bool = false
var colossus_sound: AudioStreamPlayer3D
var hidden_panel: Node3D
var reactor_gate: Node3D
var reactor_gate_open: bool = false
var barrier: Node3D
var barrier_disabled: bool = false
var ambience: WorldEnvironment
var time_to_check: float = 0.0
var neutral_phase: float = 0.0

func setup(run: State, actor: CharacterBody3D) -> void:
	state = run
	player = actor

func _ready() -> void:
	_materials()
	art = Art.new()
	art.prepare_materials(materials)
	add_child(art)
	_environment()
	_build_structure()
	_build_interactables()
	_build_enemies()
	_batch_static_geometry()
	art.build()
	art.build_core(objects["core"])
	art.build_console(objects["mother"])
	art.build_console(objects["relay"])
	_build_audio()
	state.changed.connect(refresh)
	refresh()

func _materials() -> void:
	for entry in [["wall", "8ab7c5"], ["floor", "397ca0"], ["steel", "8ab7c5"], ["dark", "142b48"], ["yellow", "ed8741"], ["red", "b95132"], ["teal", "397ca0"]]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(entry[1])
		material.roughness = 0.75
		material.metallic = 0.5 if entry[0] != "floor" else 0.15
		materials[entry[0]] = material
	for entry in [["glow", "ffa84b"], ["cyan", "5be4e5"], ["danger", "ff4d2b"]]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(entry[1])
		material.emission_enabled = true
		material.emission = Color(entry[1])
		material.emission_energy_multiplier = 0.7
		materials[entry[0]] = material

func _environment() -> void:
	ambience = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("08111b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("7c9eac")
	environment.ambient_light_energy = 0.18
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("172a32")
	environment.fog_density = 0.006
	ambience.environment = environment
	add_child(ambience)

func _box(pos: Vector3, size: Vector3, material: String, solid: bool = false, parent: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = box_mesh
	mesh.position = pos
	mesh.scale = size
	mesh.material_override = materials[material]
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
	return mesh

func _text(text: String, pos: Vector3, size: int = 44, color: Color = Color("bed3d6"), angle: float = 0.0, parent: Node3D = self) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.rotation.y = angle
	label.font_size = size
	label.pixel_size = 0.009
	label.modulate = color
	label.outline_size = 2
	parent.add_child(label)
	return label

func _light(pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	add_child(light)
	lights.append(light)

func _bulkhead(z: float, number: String, title: String, locked: bool = false) -> void:
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 6.4, 2.5, z), Vector3(7.2, 5, 0.5), "wall", true)
	_box(Vector3(0, 4.3, z), Vector3(5.6, 1.4, 0.5), "dark", true)
	_text(number + "  /  " + title, Vector3(0, 4.12, z + 0.37), 38)
	_box(Vector3(0, 3.55, z + 0.3), Vector3(4.9, 0.08, 0.1), "danger" if locked else "cyan")
	_box(Vector3(0, 0.04, z), Vector3(5.2, 0.025, 0.7), "steel")
	_box(Vector3(0, 0.062, z + 0.31), Vector3(5.2, 0.012, 0.06), "yellow")

func _build_structure() -> void:
	_box(Vector3(0, -0.3, -34), Vector3(20, 0.6, 88), "floor", true).visible = false
	_box(Vector3(0, 5.2, -34), Vector3(20, 0.4, 88), "dark", true).visible = false
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 10, 2.5, -34), Vector3(0.5, 5, 88), "wall", true).visible = false
	_box(Vector3(0, 2.5, 10), Vector3(20, 5, 0.5), "wall", true)
	_box(Vector3(0, 2.5, -78), Vector3(20, 5, 0.5), "wall", true)
	_bulkhead(2, "01", "DÉCONTAMINATION")
	_bulkhead(-14, "02", "MAINTENANCE")
	_bulkhead(-34, "03", "ARCHIVES")
	_bulkhead(-54, "04", "CŒUR / ACCÈS RÉSERVÉ", true)
	reactor_gate = Node3D.new()
	add_child(reactor_gate)
	_box(Vector3(0,1.7,-54), Vector3(5.1,3.4,0.35), "steel", true, reactor_gate)
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 1.4,1.7,-53.8), Vector3(0.1,3.2,0.05), "danger", false, reactor_gate)
	_text("VERROUILLÉ / RELAIS HORS LIGNE", Vector3(0,1.8,-53.78), 22, Color("ffab6a"), 0, reactor_gate)
	for z in range(-76, 10, 4):
		for side in [-1.0, 1.0]:
			_box(Vector3(side * 9.7, 2.5, z), Vector3(0.35, 5, 0.25), "steel")
			_box(Vector3(side * 2.1, 0.025, z), Vector3(0.08, 0.03, 2.5), "yellow")
			_box(Vector3(side * 9.6, 0.5, z), Vector3(0.12, 0.08, 1.7), "cyan")
		_box(Vector3(0, 5, z), Vector3(20, 0.22, 0.2), "steel")
		_box(Vector3(0, 0.012, z), Vector3(20, 0.02, 0.035), "dark")
	for z in [6, -5, -22, -42, -63, -73]:
		_box(Vector3(0, 4.9, z), Vector3(3.8, 0.08, 0.18), "glow")
		_light(Vector3(-1.3, 3.8, z), Color("b0d6df") if z in [-5,-42] else Color("ffd19d"), 1.3, 13)
	for z in [-30, -58]:
		_box(Vector3(-9.6, 3.6, z), Vector3(0.16, 0.4, 0.7), "danger")
		_light(Vector3(-8, 2.9, z), Color("ff6439"), 1.5, 7)
	for z in [-6, -19, -29, -40, -49, -62]:
		var side: float = -1 if int(z) % 2 == 0 else 1
		_box(Vector3(side * 6.6, 0.8, z), Vector3(2.3, 1.6, 2.5), "dark", true)
		_box(Vector3(side * 6.6, 1.62, z), Vector3(2.5, 0.1, 2.7), "steel")
		_box(Vector3(side * 6.6, 1.15, z + 1.26), Vector3(1.6, 0.35, 0.035), "teal")
		_text("RÉVISION D9 / 29\nOUTILS DE MAINTENANCE" if z == -29 else "S9 / " + str(absi(int(z))) + "\nSYSTÈME AUXILIAIRE", Vector3(side * 6.6, 0.8, z + 1.29), 18)
	for z in [-4, -24, -44, -64]:
		_text("↓", Vector3(0, 0.04, z), 95, Color("c19449")).rotation_degrees.x = -90
	_lift()
	_archives()
	_reactor()
	_kenney_props()

func _lift() -> void:
	_text("S I L O   9", Vector3(0, 3.7, 9.7), 80, Color("ffc27d"), PI)
	_text("ASCENSEUR  /  REFUGE MOBILE\nÉTAGE 009 — AUCUNE LIAISON SURFACE", Vector3(0, 2.7, 9.7), 26, Color("bed3d6"), PI)
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 4.8, 2.2, 6), Vector3(0.35, 4.4, 7.5), "steel", true)
		_box(Vector3(side * 4.6, 1.1, 6), Vector3(0.15, 0.12, 7), "yellow")
	_box(Vector3(0, 0.015, 6), Vector3(9.5, 0.03, 7.5), "dark")
	_text("RETOUR REFUGE  →", Vector3(-6, 2, 1.6), 30, Color("5be4e5"), PI)

func _archives() -> void:
	for side in [-1.0, 1.0]:
		for z in [-38, -46, -51]:
			_box(Vector3(side * 9, 1.6, z), Vector3(1.3, 3.2, 2.7), "dark", true)
			for y in [0.4, 1.0, 1.6, 2.2, 2.8]:
				_box(Vector3(side * 8.3, y, z), Vector3(0.04, 0.06, 2), "cyan")
	_text("LES ARCHIVES NE MENTENT PAS.\nLES VOIX, PARFOIS.", Vector3(5, 2.5, -53.7), 35, Color("5be4e5"))

func _reactor() -> void:
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 4.5, 1.2, -69), Vector3(0.18, 0.16, 13), "yellow")
		for z in [-63, -68, -74]:
			_box(Vector3(side * 4.5, 0.6, z), Vector3(0.12, 1.2, 0.12), "steel")
			_box(Vector3(side * 7.5, 2.2, z), Vector3(2, 4.4, 2), "dark", true)
			_box(Vector3(side * 7.5, 2.2, z + 1.02), Vector3(0.12, 3.5, 0.05), "danger")
	_box(Vector3(0, 0.3, -72), Vector3(3.6, 0.6, 3.6), "steel", true)
	_text("CŒUR MÉMORIEL\nNE PAS EXTRAIRE SOUS TENSION", Vector3(0, 3.2, -77.20), 38, Color("ffc27d"))
	_light(Vector3(0, 2.7, -72), Color("56e6ed"), 3, 8)

func _batch_static_geometry() -> void:
	var batches: Dictionary = {}
	for child in get_children():
		if child is MeshInstance3D and child.mesh == box_mesh and child != hidden_panel and child.visible:
			var bucket: int = clampi(int((-child.position.z + 14.0) / 20.0), 0, 4)
			var key: String = str(bucket) + ":" + str(child.material_override.get_instance_id())
			if not batches.has(key):
				batches[key] = []
			batches[key].append(child)
	for key: String in batches:
		var meshes: Array = batches[key]
		var origin := Vector3(0, 0, -float(key.get_slice(":", 0).to_int()) * 20.0)
		var instances := MultiMeshInstance3D.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = box_mesh
		multi.instance_count = meshes.size()
		instances.multimesh = multi
		instances.material_override = meshes[0].material_override
		instances.position = origin
		instances.visibility_range_end = 70
		for i in meshes.size():
			var transform: Transform3D = meshes[i].transform
			transform.origin -= origin
			multi.set_instance_transform(i, transform)
			meshes[i].queue_free()
		add_child(instances)

func _kenney_props() -> void:
	for entry in [["machine", Vector3(8.5, 0, -7), Vector3(1.8,1.95,2.25)], ["machine-fortified", Vector3(-8, 0, -25), Vector3(1.8,2.03,2.4)], ["box-large", Vector3(4, 0, -12), Vector3(1.65,0.825,1.5)], ["pipe-large-valve", Vector3(8, 1, -58), Vector3(1.5,1.5,1.52)]]:
		var path: String = "res://assets/kenney/" + entry[0] + ".glb"
		if ResourceLoader.exists(path):
			var packed := load(path) as PackedScene
			if packed != null:
				var prop := packed.instantiate() as Node3D
				prop.position = entry[1]
				prop.scale = Vector3.ONE * 1.5
				add_child(prop)
				var collision_box: Vector3 = entry[2]
				_box(entry[1] + Vector3(0, collision_box.y / 2.0, 0), collision_box, "dark", true).visible = false
				for mesh in prop.find_children("*", "MeshInstance3D", true, false):
					mesh.visibility_range_end = 45
					mesh.material_override = materials["steel"]

func _object(id: String, prompt: String, pos: Vector3, color: String = "cyan", size: Vector3 = Vector3(0.8, 1.2, 0.45)) -> StaticBody3D:
	var object := Interactable.new()
	object.position = pos
	object.set_meta("id", id)
	object.set_meta("prompt", prompt)
	object.add_to_group("interactable")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	object.add_child(shape)
	add_child(object)
	_box(Vector3(0, size.y / 2.0, 0), size, "dark", false, object)
	_box(Vector3(0, size.y * 0.7, size.z / 2.0 + 0.02), Vector3(size.x * 0.8, size.y * 0.3, 0.04), color, false, object)
	objects[id] = object
	return object

func _build_interactables() -> void:
	_object("mother", "Parler à MÈRE", Vector3(3.8, 0, 4))
	_text("MÈRE", Vector3(3.8, 1.75, 4), 30)
	_object("recharge", "Recharger la batterie · gratuit", Vector3(-3.8, 0, 4), "glow")
	_text("ÉNERGIE ∞", Vector3(-3.8, 1.75, 4), 25, Color("ffc27d"))
	_object("upgrade", "Améliorer batterie · 3 composants", Vector3(-3.8, 0, 8), "glow")
	_text("ÉTABLI / 150 E", Vector3(-3.8, 1.75, 8), 23)
	_object("ending", "Console de descente / choix final", Vector3(0, 0, 9), "glow")
	var relay := _object("relay", "Réparer le relais · 3 composants", relay_position, "glow")
	relay.visible = false
	relay.collision_layer = 0
	hidden_panel = _box(relay_position + Vector3(0, 1, 0.5), Vector3(2, 2, 0.1), "wall")
	_text("ANOMALIE ÉLECTROMAGNÉTIQUE\nSCAN ÉCHO REQUIS [SCAN]", Vector3(7, 2.7, -26), 25, Color("5be4e5"))
	var n7 := _object("n7", "Parler à N-7", Vector3(-7, 0, -43), "cyan", Vector3(0.8, 1.6, 0.7))
	for child in n7.get_children():
		if child is MeshInstance3D: child.queue_free()
	var n7_visual := Node3D.new()
	n7_visual.name = "Visual"
	n7_visual.rotation.y = -PI / 2.0
	n7.add_child(n7_visual)
	RobotVisual.build(n7_visual, false, materials["cyan"], true)
	var n7_label := _text("N — 7", Vector3(-7, 2.3, -43), 30, Color("5be4e5"))
	n7_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_object("evidence", "Lire l'archive : signal de surface", Vector3(6, 0, -47), "cyan")
	_object("core", "Extraire le cœur mémoriel", Vector3(0, 0.6, -72), "cyan", Vector3(0.7, 1.3, 0.7))
	var device := _object("device", "Verrou électrique · ARC-3 ou détour latéral", Vector3(2.8, 0, -57), "danger") as Interactable
	device.electrical = true
	device.disabled.connect(_disable_barrier)
	barrier = Node3D.new()
	add_child(barrier)
	for x in [-1.5, -0.75, 0.0, 0.75, 1.5]:
		_box(Vector3(x, 1.5, -58), Vector3(0.05, 3, 0.05), "danger", false, barrier)
	_box(Vector3(0, 1.5, -58), Vector3(4.1, 3, 0.15), "dark", true, barrier).visible = false
	_text("ARC-3  /  CONTOURNEMENT →", Vector3(0, 3.5, -58), 30, Color("ff8c64"))
	var positions: Array[Vector3] = [Vector3(-4,0,-3), Vector3(5,0,-9), Vector3(-7,0,-11), Vector3(5,0,-19), Vector3(-4,0,-23), Vector3(-7,0,-30), Vector3(4,0,-38), Vector3(6,0,-51), Vector3(-6,0,-60)]
	for i in positions.size():
		var item := _object("component_" + str(i), "Récupérer un composant", positions[i], "glow", Vector3(0.5,0.4,0.5))
		item.set_meta("kind", "components")
	for entry in [["ammo_1", "ammo", Vector3(3,0,-11), 24], ["ammo_2", "ammo", Vector3(-5,0,-39), 24], ["cell_1", "cell", Vector3(-4,0,-18), 1], ["cell_2", "cell", Vector3(6,0,-45), 1], ["med_1", "medkit", Vector3(4,0,-31), 1]]:
		var item := _object(entry[0], "Récupérer : " + entry[1], entry[2], "cyan", Vector3(0.6,0.3,0.5))
		item.set_meta("kind", entry[1])
		item.set_meta("amount", entry[3])

func _build_enemies() -> void:
	for entry in [["sentinel_1", false, Vector3(3,0,-20)], ["crawler_1", true, Vector3(-5,0,-28)], ["sentinel_2", false, Vector3(-3,0,-45)], ["crawler_2", true, Vector3(3,0,-51)], ["sentinel_3", false, Vector3(0,0,-66)], ["crawler_3", true, Vector3(-3,0,-70)]]:
		var enemy := Enemy.new()
		enemy.enemy_id = entry[0]
		enemy.crawler = entry[1]
		enemy.health = 35.0 if enemy.crawler else 65.0
		enemy.state = state
		enemy.target = player
		enemy.position = entry[2]
		enemy.patrol = [entry[2], entry[2] + Vector3(0,0,4), entry[2] + Vector3(-2,0,2)]
		add_child(enemy)
		enemies.append(enemy)

func interact(target: Node) -> void:
	if target == null or not target.has_meta("id"):
		return
	var id: String = target.get_meta("id")
	if target.has_meta("kind"):
		if state.collect(id, target.get_meta("kind"), target.get_meta("amount", 1)):
			message.emit("Ressource récupérée.")
		return
	match id:
		"mother", "n7": conversation_requested.emit(id)
		"recharge":
			state.recharge()
			message.emit("Batterie rechargée. L'ascenseur reste votre refuge.")
		"upgrade": message.emit("Batterie améliorée : 150 énergie." if state.upgrade() else "L'établi demande 3 composants, amélioration unique.")
		"relay":
			message.emit("Alimentation rétablie. Le cœur est accessible." if state.repair_relay() else "Révélez le relais au SCAN ÉCHO, puis apportez 3 composants.")
		"evidence":
			state.add_fact("surface_signal")
			state.remember("Le joueur a découvert un signal humain à la surface.")
			message.emit("ARCHIVE 09 : une voix humaine a émis depuis la surface il y a 6 heures. MÈRE a classé le signal « bruit ».")
		"core": message.emit("Cœur récupéré. Retournez à l'ascenseur et choisissez à qui le confier." if state.recover_core() else "Cœur verrouillé. Réparez le relais de maintenance.")
		"ending":
			if state.phase == 3:
				ending_requested.emit()
			else:
				message.emit("Descente suspendue. Récupérez le cœur mémoriel du secteur 04.")
		"device": message.emit("Utilisez l'ARC-3 pour couper le verrou, ou passez à droite de la barrière.")

func scan(origin: Vector3) -> void:
	if origin.distance_to(relay_position) <= 18.0:
		if state.discover_relay():
			message.emit("ÉCHO : relais dissimulé révélé dans la maintenance. Localisation conservée.")
	scan_timer = 5.0
	for object: Node3D in objects.values():
		if object.visible and object.global_position.distance_to(origin) <= 18:
			var marker: Node3D = object.get_node_or_null("EchoMarker")
			if marker == null:
				marker = _text("◇", Vector3(0, 2.1, 0), 80, Color("59ffff"), 0, object)
				marker.name = "EchoMarker"
				(marker as Label3D).billboard = BaseMaterial3D.BILLBOARD_ENABLED
				(marker as Label3D).no_depth_test = true
			marker.visible = true
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) < 18:
			var marker := enemy.get_node_or_null("EchoMarker") as Label3D
			if marker == null:
				marker = _text("⚠", Vector3(0,2.1,0), 70, Color("ff9855"), 0, enemy)
				marker.name = "EchoMarker"
				marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				marker.no_depth_test = true
			marker.visible = true
	if is_instance_valid(pulse):
		pulse.queue_free()
	pulse = MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.94
	mesh.outer_radius = 1.0
	mesh.rings = 32
	mesh.ring_segments = 6
	pulse.mesh = mesh
	pulse.material_override = materials["cyan"]
	pulse.position = origin + Vector3(0,0.15,0)
	add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector3(18,0.3,18), 0.9)
	tween.tween_callback(pulse.queue_free)
	emit_noise(origin, 24)

func emit_noise(origin: Vector3, radius: float) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.hear_noise(origin, radius)

func _disable_barrier() -> void:
	barrier_disabled = true
	state.add_fact("arc_lock_disabled")
	state.remember("Le verrou ARC a été désactivé.")
	if is_instance_valid(barrier) and not barrier.is_queued_for_deletion():
		barrier.queue_free()
	message.emit("Verrou électrique hors tension.")

func refresh() -> void:
	if state.phase >= 2 and not reactor_gate_open:
		reactor_gate_open = true
		create_tween().tween_property(reactor_gate, "position:y", 4.0, 0.65)
	if state.facts.has("arc_lock_disabled") and is_instance_valid(barrier) and not barrier.is_queued_for_deletion():
		barrier_disabled = true
		barrier.queue_free()
	for id: String in objects:
		var object: StaticBody3D = objects[id]
		var available: bool = not state.collected.has(id)
		if id == "relay":
			available = state.phase >= 1
		if id == "core":
			available = state.phase < 3
		object.visible = available
		object.collision_layer = 1 if available else 0
	if is_instance_valid(hidden_panel):
		hidden_panel.visible = state.phase == 0
	for enemy in enemies:
		if is_instance_valid(enemy) and state.defeated.has(enemy.enemy_id) and enemy.health > 0:
			enemy.queue_free()
	if state.ending != "":
		for light in lights:
			light.light_color = Color("ff6737") if state.ending == "mother" else Color("63e9e0")
		if state.ending == "n7":
			for enemy in enemies:
				if is_instance_valid(enemy):
					enemy.set_physics_process(false)
					if enemy.eye_material != null:
						enemy.eye_material.emission = Color("4cead3")

func sector_at(pos: Vector3) -> String:
	if pos.z > 2: return "ASCENSEUR / REFUGE"
	if pos.z > -14: return "01 / DÉCONTAMINATION"
	if pos.z > -34: return "02 / MAINTENANCE"
	if pos.z > -54: return "03 / ARCHIVES"
	return "04 / CŒUR"

func _process(delta: float) -> void:
	neutral_phase += delta * 1.2
	RobotVisual.animate(objects["n7"].get_node("Visual"), false, neutral_phase, 0.0, "friendly", 0.0, 0.0, delta)
	if scan_timer > 0:
		scan_timer -= delta
		if scan_timer <= 0:
			for object: Node3D in objects.values():
				var marker := object.get_node_or_null("EchoMarker")
				if marker != null: marker.visible = false
			for enemy in enemies:
				if is_instance_valid(enemy):
					var marker := enemy.get_node_or_null("EchoMarker")
					if marker != null: marker.visible = false
	time_to_check -= delta
	if time_to_check > 0: return
	time_to_check = 0.5
	if is_instance_valid(player): art.update_focus(player.global_position)
	if is_instance_valid(player) and player.position.z < -55 and not colossus_triggered:
		colossus_triggered = true
		colossus_sound.play()
		message.emit("Quelque chose bouge sous vos pieds. MÈRE : « Poursuivez. Ce n'est qu'une dilatation thermique. »")
		for light in lights:
			var tween := create_tween()
			tween.tween_property(light, "light_energy", 0.1, 0.15)
			tween.tween_property(light, "light_energy", 2.0, 0.8).set_delay(0.15)

func _build_audio() -> void:
	colossus_sound = AudioStreamPlayer3D.new()
	colossus_sound.position = Vector3(0,-4,-65)
	colossus_sound.max_distance = 55
	colossus_sound.volume_db = -9
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(22050 * 3 * 2)
	for i in 22050 * 3:
		var t: float = float(i) / 22050.0
		var envelope: float = sin(PI * t / 3.0)
		var sample: float = (sin(TAU * (42.0 - t * 5.0) * t) * 0.6 + sin(TAU * 71.0 * t) * 0.2) * envelope
		bytes.encode_s16(i * 2, int(sample * 24000))
	stream.data = bytes
	colossus_sound.stream = stream
	add_child(colossus_sound)

func set_quality(low: bool) -> void:
	RobotVisual.set_quality(low)
	art.set_quality(low)
	get_viewport().scaling_3d_scale = 0.67 if low else 1.0
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	for i in lights.size():
		lights[i].visible = not low or i < 6
		if i < 6: lights[i].light_energy = 2.1 if low else 1.3
	ambience.environment.fog_enabled = not low
