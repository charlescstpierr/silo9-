extends SceneTree

const Visual = preload("res://scripts/robot_visual.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for crawler in [false, true]:
		var robot := Node3D.new()
		var eyes := StandardMaterial3D.new()
		Visual.build(robot, crawler, eyes)
		var legs := robot.get_node("RobotLegs")
		check(legs.get_child_count() == (6 if crawler else 2), "Each robot retains its leg count")
		var leg := legs.get_child(0) as Node3D
		var knee := leg.get_node_or_null("Knee") as Node3D
		check(knee != null, "Robot has an independently articulated knee")
		if knee != null:
			Visual.animate_legs(legs, crawler, 0.0, 2.0)
			var initial := knee.transform
			Visual.animate_legs(legs, crawler, PI / 2, 2.0)
			check(not knee.transform.is_equal_approx(initial), "Knee bends during a stride")
			check(knee.get_node_or_null("Foot") != null, "Foot has its own leveling pivot")
			var foot := knee.get_node("Foot") as Node3D
			var tilt: float = leg.rotation.z + knee.rotation.z + foot.rotation.z if crawler else leg.rotation.x + knee.rotation.x + foot.rotation.x
			check(absf(tilt) < 0.001, "Foot counter-rotates the hip and knee")
			Visual.animate_legs(legs, crawler, PI / 2, 0.0)
			check(knee.rotation.length() < 0.001, "Stopped robot returns to supported rest stance")
		var body := robot.get_node_or_null("RobotBody") as Node3D
		if body != null:
			Visual.animate(robot, crawler, 0.0, 0.0, "patrol", 0.0, 0.0, 0.1)
			var resting := body.transform
			Visual.animate(robot, crawler, 0.0, 0.0, "patrol", 0.09, 0.0, 0.1)
			check(not body.transform.is_equal_approx(resting), "Impact displaces the robot body")
			check(robot.transform == Transform3D.IDENTITY, "Visual impact cannot displace gameplay root")
			Visual.animate(robot, crawler, PI / 2, 0.0, "friendly", 0.0, 0.0, 0.1)
			check(absf(body.rotation.y) > 0.01, "Neutral robot looks around while standing")
		robot.free()
	Visual.set_quality(true)
	for material in Visual.materials + Visual.crawler_materials:
		check(not material.normal_enabled and material.roughness_texture == null, "Low quality avoids robot detail-map sampling")
	Visual.set_quality(false)
	for material in Visual.materials + Visual.crawler_materials:
		check(material.normal_enabled and material.roughness_texture != null, "Normal quality restores robot detail maps")
	print("ROBOT VISUAL FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
