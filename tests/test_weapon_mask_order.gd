extends SceneTree

const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
const Rig = preload("res://scripts/fps_rig.gd")
const Ready = preload("res://tests/weapon_ready.gd")

class ObservedRig extends Rig:
	var watching := false
	var observations := 0
	var unsafe_restorations := 0

	func restore_reload_parts() -> void:
		if watching:
			observations += 1
			for gun in _weapons:
				for mesh: MeshInstance3D in gun.find_children("*", "MeshInstance3D", true, false):
					for corner in 8:
						var point := to_local(mesh.to_global(mesh.mesh.get_aabb().get_endpoint(corner)))
						if point.z < -.05 and point.y >= point.z:
							unsafe_restorations += 1
		super.restore_reload_parts()

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func run() -> void:
	var player := Player.new()
	player.setup(State.new())
	root.add_child(player)
	player.set_physics_process(false)
	player.set_active(true)
	player.rig.free()
	var rig := ObservedRig.new()
	player.camera.add_child(rig)
	player.rig = rig
	for weapon in [0,1]:
		player.equip(weapon)
		check(Ready.wait_for(player, weapon), "mask fixture reaches requested READY")
		player.state.ammo = 4
		player.state.energy = 10
		check(player.reload_weapon(), "mask fixture begins real manipulation")
		player._advance_reload(.9 if weapon == 0 else 1.1)
		player._update_view(.01)
		player.equip(1-weapon)
		player.equip(weapon)
		rig.watching = true
		player._advance_reload(10)
		rig.watching = false
		check(is_equal_approx(rig.skeleton.position.y, -1.15), "same-index hidden call returns with assembly still lowered")
		var mouth := rig.muzzle.transform
		rig.update_visual(0, rig._hidden_frame)
		check(rig.muzzle.transform.is_equal_approx(mouth), "hidden zero recomposition does not double lower muzzle")
		player._update_view(0)
		check(player.reload_cycle.ready and rig.skeleton.position.y == 0, "final view raises after hidden contract")
	check(rig.observations == 2 and rig.unsafe_restorations == 0, "both same-index restorations begin with actual mesh corners below FOV90, hence60/76")
	for stream in [player._audio, player._manipulation_audio, player._scan_audio]:
		stream.stop()
		stream.stream = null
	await create_timer(.2).timeout
	player.free()
	await create_timer(.3).timeout
	print("WEAPON MASK ORDER FAILURES: ", failures)
	quit(1 if failures else 0)
