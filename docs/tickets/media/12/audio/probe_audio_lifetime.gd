extends SceneTree
const State = preload("res://scripts/run_state.gd")
const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
var references: Array[Dictionary] = []
var rows: Array[Dictionary] = []
var mode: String = "drained"
func _initialize() -> void:
	if not OS.get_cmdline_user_args().is_empty(): mode = OS.get_cmdline_user_args()[0]
	call_deferred("run")
func retain_weak_audio(world: Node) -> void:
	for sound: AudioStreamPlayer3D in world.find_children("*", "AudioStreamPlayer3D", true, false):
		if sound.stream != null:
			references.append({"kind":"stream", "reference":weakref(sound.stream)})
		if sound.has_stream_playback():
			references.append({"kind":"playback", "reference":weakref(sound.get_stream_playback())})
func sample(cycle: int, delay: float) -> void:
	var live: Dictionary = {"stream":0,"playback":0}
	for record: Dictionary in references:
		if record.reference.get_ref() != null: live[record.kind] += 1
	var row: Dictionary = {"cycle":cycle,"delay":delay,"audio_alive":live,"objects_less_probe_weakrefs":Performance.get_monitor(Performance.OBJECT_COUNT)-references.size(),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)}
	rows.append(row)
	print("AUDIO_LIFETIME ",JSON.stringify(row))
func cycle(index: int) -> void:
	var state := State.new()
	var player := Player.new()
	player.setup(state)
	root.add_child(player)
	player.position = Vector3(0,0,7)
	player.active = true
	player.set_physics_process(false)
	var world := World.new()
	world.setup(state,player)
	root.add_child(world)
	for enemy: CharacterBody3D in world.enemies: enemy.set_physics_process(false)
	await physics_frame
	await physics_frame
	world.set_circuit(&"maintenance",false)
	world.set_circuit(&"archives",false)
	world.set_circuit(&"maintenance",true)
	retain_weak_audio(world)
	world.queue_free()
	player.queue_free()
	state = null
	await process_frame
	if mode == "drained": await process_frame
	sample(index,0)
	if mode == "drained":
		await create_timer(0.25).timeout
		await process_frame
		sample(index,0.25)
		await create_timer(0.5).timeout
		await process_frame
		sample(index,0.75)
func run() -> void:
	await process_frame
	sample(-1,0)
	for index: int in (8 if mode == "drained" else 1): await cycle(index)
	if mode == "drained":
		await create_timer(1.0).timeout
		await process_frame
		sample(8,1)
	print("AUDIO_MODE=",mode," COMPLETE")
	quit()
