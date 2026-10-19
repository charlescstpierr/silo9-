extends SceneTree
func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var source: String = arguments[0]
	var destination: String = arguments[1]
	var state: RefCounted = load("res://scripts/run_state.gd").new()
	var result: int = state.load_game(source)
	if result != OK:
		printerr("load failed: ", result)
		quit(1)
		return
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
	var output := FileAccess.open(destination, FileAccess.WRITE)
	output.store_string(JSON.stringify({"saved": saved, "restored": state._snapshot().duplicate(true)}, "\t", true, true))
	output.close()
	quit(0)
