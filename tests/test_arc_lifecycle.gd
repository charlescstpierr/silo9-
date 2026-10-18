extends SceneTree
const Handling = preload("res://scripts/weapon_handling.gd")
const State = preload("res://scripts/run_state.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value: failures += 1
func _initialize() -> void:
	var handling := Handling.new()
	var state := State.new()
	state.energy = 0
	state.cells = 3
	handling.state = state
	check(handling.request_cell(true),"B from D9 accepted")
	for tick in 600:
		var events := handling.advance(.01,true)
		if events & Handling.CELL_DONE: break
	check(handling.view.motion == Handling.Motion.LOWER_ABORT and state.cells == 2,"cell completion begins automatic return")
	check(not handling.request_cell(true),"automatic return is busy, not a cancelled exit")
	for tick in 600: handling.advance(.01,true)
	check(handling.weapon_index == 0 and handling.ready and state.cells == 2,"automatic return cannot queue another cell")
	check(handling.request_cell(true),"new READY request accepted")
	handling.cancel()
	check(handling.request_cell(true),"explicitly cancelled exit accepts one intention")
	check(not handling.request_cell(true),"cancelled exit intention remains bounded")
	print("ARC LIFECYCLE FAILURES: ",failures)
	quit(1 if failures else 0)
