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
	handling = Handling.new()
	handling.state = State.new()
	handling.state.ammo = 4
	handling.state.energy = 10
	check(handling.request_reload(true),"destination scenario starts D9 reload")
	handling.advance(.3,true)
	handling.select(1)
	check(handling.request_cell(true),"cell request accepted during manually cancelled switch")
	for tick in 1000: handling.advance(.01,true)
	check(handling.weapon_index == 1 and handling.ready,"cell returns to desired ARC during pending manual switch")
	print("ARC LIFECYCLE FAILURES: ",failures)
	quit(1 if failures else 0)
