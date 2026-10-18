extends SceneTree
const Player = preload("res://scripts/player.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
func check(value: bool,label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var hashes: Dictionary = {}
	for cue in ["remove","insert","rack_pull","rack_release","cell_unlock","cell_remove","cell_insert","cell_transfer"]:
		hashes[hash(Player.Audio.synthesize(cue).data)] = true
	check(hashes.size() == 8,"ARC cues are distinct from each other and D9")
	for weapon in [0,1]:
		var player := Player.new()
		var state := State.new()
		state.ammo = 4
		state.energy = 10
		player.setup(state)
		root.add_child(player)
		player.set_physics_process(false)
		player.set_active(true)
		player.equip(weapon)
		check(player.reload_weapon(),"audio fixture starts manipulation")
		player._advance_reload(.55 if weapon == 1 else Player.D9.reload_duration*.28+.001)
		check(player._manipulation_audio.playing,"threshold starts manipulation audio")
		player.equip(1-weapon)
		check(not player._manipulation_audio.playing,"manual selection stops old manipulation cue")
		player.free()
	await process_frame
	await create_timer(.2).timeout
	print("ARC AUDIO FAILURES: ",failures)
	quit(1 if failures else 0)
