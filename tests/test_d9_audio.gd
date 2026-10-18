extends SceneTree
const Audio = preload("res://scripts/player_audio.gd")
func _initialize() -> void:
	var hashes: Array[int] = []
	for cue in ["remove","insert","rack_pull","rack_release"]:
		var sound := Audio.synthesize(cue)
		hashes.append(hash(sound.data))
	var unique: Dictionary = {}
	for value in hashes: unique[value] = true
	print("D9 AUDIO distinct cues: ",unique.size())
	quit(0 if unique.size() == 4 else 1)
