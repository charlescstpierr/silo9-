extends SceneTree
const World = preload("res://scripts/world.gd")
const State = preload("res://scripts/run_state.gd")
const Enemy = preload("res://scripts/enemy.gd")
class TrainingActor extends CharacterBody3D:
	var active: bool = true
	var damage_total: float = 0.0
	func apply_damage(amount: float) -> void:
		damage_total += amount
var failures: int = 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var state := State.new()
	var actor := TrainingActor.new()
	root.add_child(actor)
	actor.position = Vector3(0, 0, 7)
	var world := World.new()
	world.setup(state, actor)
	root.add_child(world)
	await physics_frame
	world.set_quality(true)
	check(is_equal_approx(world.get_viewport().scaling_3d_scale, 0.67), "Low quality reduces internal 3D pixel count")
	check(world.get_viewport().msaa_3d == Viewport.MSAA_DISABLED, "Low quality disables MSAA")
	for light: Light3D in world.find_children("*", "Light3D", true, false):
		check(not light.shadow_enabled, "World has no static exploration shadow in Low")
	for material in world.art.textured_materials:
		check(not material.normal_enabled and material.roughness_texture == null, "Low quality avoids normal and roughness texture sampling")
	world.set_quality(false)
	check(is_equal_approx(world.get_viewport().scaling_3d_scale, 1.0), "High quality restores native 3D resolution")
	check(world.get_viewport().msaa_3d == Viewport.MSAA_DISABLED and world.get_viewport().screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED, "Compatibility high quality avoids costly MSAA and unsupported native screen-space AA")
	for light: Light3D in world.find_children("*", "Light3D", true, false):
		check(not light.shadow_enabled, "Exploration shadow belongs to Player, never a sector spot")
	for material in world.art.textured_materials:
		check(material.normal_enabled == world.art.original_normal[material] and material.roughness_texture == world.art.original_roughness[material], "High quality restores original material detail")
	var gate_query := PhysicsRayQueryParameters3D.create(Vector3(0,1,-52), Vector3(0,1,-56), 1)
	var gate_hit := world.get_world_3d().direct_space_state.intersect_ray(gate_query)
	check(not gate_hit.is_empty(), "Reactor blast door physically blocks access before power")
	world.scan(Vector3(0, 0, 7))
	check(state.phase == 0, "Far scan must not reveal relay")
	world.scan(Vector3(7, 0, -26))
	check(state.phase == 1, "Nearby scan permanently discovers mandatory relay")
	check(world.sector_at(Vector3(0, 0, -20)) == "02 / MAINTENANCE", "Four authored sectors have location labels")
	world.interact(world.objects["core"])
	check(state.phase == 1, "Core cannot be recovered before power repair")
	for i in 3:
		world.interact(world.objects["component_" + str(i)])
	check(state.components == 3, "Loot grants three usable components")
	world.interact(world.objects["relay"])
	check(state.phase == 2 and state.components == 0, "Relay repair consumes components and restores power")
	await create_timer(0.8).timeout
	world.interact(world.objects["evidence"])
	check(state.facts.has("surface_signal"), "Archive exposes canonical evidence")
	world.interact(world.objects["core"])
	check(state.phase == 3, "Powered core is recoverable")
	world.interact(world.objects["component_0"])
	check(state.components == 0, "Already collected loot cannot duplicate")
	for e in world.enemies:
		e.set_physics_process(false)
		e.collision_layer = 0
	await physics_frame
	await physics_frame
	var route: Array[Vector3] = [Vector3(0,0,7),Vector3(0,0,-56),Vector3(3.6,0,-56),Vector3(3.6,0,-61),Vector3(0,0,-61),Vector3(0,0,-69)]
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	for i in route.size() - 1:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, route[i] + Vector3(0,1,0))
		query.motion = route[i + 1] - route[i]
		query.collision_mask = 1
		var result := world.get_world_3d().direct_space_state.cast_motion(query)
		check(result[0] >= 0.999, "Player capsule fits authored route segment " + str(i))
	world.objects["device"].receive_hit(10.0, 2.0)
	await process_frame
	check(not is_instance_valid(world.barrier), "ARC disables actual barrier collision")
	check(state.facts.has("arc_lock_disabled"), "ARC device state persists as canonical fact")
	var original_light: Color = world.lights[0].light_color
	check(state.choose_ending("n7"), "N7 ending can complete mission")
	check(world.lights[0].light_color != original_light, "Ending changes visible world lighting")
	var enemy := Enemy.new()
	root.add_child(enemy)
	enemy.receive_hit(10, 2)
	check(enemy.health == 50 and enemy.stunned >= 2, "Electrical hit applies damage and stun")
	enemy.hear_noise(Vector3(2, 0, 0), 10)
	check(enemy.mode == "investigate", "Enemy investigates audible sound")
	actor.position = Vector3(0, 0, 198)
	enemy.position = Vector3(0, 0, 200)
	enemy.target = actor
	enemy.mode = "chase"
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(4,4,0.5)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0,1,199)
	root.add_child(wall)
	await physics_frame
	await physics_frame
	enemy._sense()
	check(not enemy.sees_target, "Opaque physical wall blocks enemy vision")
	wall.queue_free()
	await physics_frame
	await physics_frame
	enemy.mode = "chase"
	enemy._sense()
	check(enemy.sees_target, "Removing wall restores enemy line of sight")
	enemy.stunned = 0
	enemy.attack_remaining = 0
	enemy._step_brain(0.2)
	check(actor.damage_total > 0, "Visible player takes a real enemy attack")
	enemy.queue_free()
	var investigator := Enemy.new()
	investigator.position = Vector3(3, 0, -16)
	root.add_child(investigator)
	investigator.set_physics_process(false)
	investigator.hear_noise(Vector3(3,0,-12), 10)
	for frame in 420:
		investigator._step_brain(1.0 / 60.0)
		investigator.velocity.y = -1.0
		investigator.move_and_slide()
		await physics_frame
	check(investigator.global_position.z > -13.0, "Nearby cross-sector sound routes sentinel through actual bulkhead opening")
	print("Portal investigation final position: ", investigator.global_position)
	investigator.position = Vector3(3, 0, -16)
	investigator.hear_noise(Vector3(3,0,-18), 10)
	for frame in 60:
		investigator._step_brain(1.0 / 60.0)
		investigator.velocity.y = -1.0
		investigator.move_and_slide()
		await physics_frame
	check(absf(investigator.global_position.x - 3.0) < 0.01 and investigator.global_position.z < -17.0, "Nearby same-sector sound preserves direct route without portal detour")
	investigator.queue_free()
	world.queue_free()
	actor.queue_free()
	await process_frame
	print("WORLD: ", failures, " failures")
	quit(1 if failures else 0)
