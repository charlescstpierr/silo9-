extends SceneTree

const Reload = preload("res://scripts/weapon_handling.gd")
var failures := 0

func check(value: bool, label: String) -> void:
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func _initialize() -> void:
	var cycle := Reload.new()
	cycle.begin(true,2.6,3.25)
	var events := cycle.advance(2.6,true)
	check(not cycle.ready and not events & Reload.COMMIT,"empty reload stays blocked at partial duration")
	check(events & Reload.REMOVE and events & Reload.INSERT,"large step retains remove and insert events")
	check(events & Reload.RACK_PULL and not events & Reload.RACK_RELEASE,"rack pull precedes rack release")
	events = cycle.advance(.65,true)
	check(cycle.ready and events & Reload.RACK_RELEASE and events & Reload.COMMIT,"empty sequence releases slide before readiness")
	check(cycle.advance(50,true) == 0,"no event can repeat after completion")
	cycle.begin(false,2.6,3.25)
	events = cycle.advance(50,true)
	check(events == Reload.REMOVE|Reload.INSERT|Reload.COMMIT,"partial reload skips both rack cues")
	cycle.begin(true,2.6,3.25)
	cycle.advance(1.0,true)
	var held_gesture := cycle.view.gesture
	var held_fraction := cycle.view.fraction
	cycle.cancel()
	cycle.cancel()
	events = cycle.advance(.08,true)
	check(cycle.view.gesture == held_gesture and cycle.view.fraction == held_fraction,"cancel freezes sampled manipulation")
	check(cycle.view.lower > .0 and cycle.view.lower < 1.0 and events == 0,"cancel lowers continuously before hidden")
	events = cycle.advance(.30,true)
	check(events & Reload.HIDDEN and not events & Reload.COMMIT,"long cancellation emits hidden without commit")
	check(cycle.ready and cycle.view.lower == 0.0,"large delta traverses hidden and full raise without lost time")
	cycle.begin(true,2.6,3.25)
	cycle.advance(.8,true)
	cycle.cancel()
	events = cycle.advance(10,false)
	check(cycle.view.motion == Reload.Motion.HIDDEN and cycle.view.lower == 1.0,"inactive controller stays hidden without commit")
	check(events == Reload.HIDDEN and cycle.advance(10,false) == 0,"hidden event occurs once while inactive")
	cycle.advance(.15,true)
	check(cycle.ready,"reactivation accounts for elapsed raise time")
	cycle.begin(false,2.6,3.25)
	cycle.advance(.6,true)
	cycle.cancel()
	cycle.advance(.23,true)
	var lower_before := cycle.view.lower
	cycle.cancel()
	check(cycle.view.lower == lower_before,"deactivation during raise cannot jump the visible height")
	cycle.advance(1,false)
	check(cycle.view.motion == Reload.Motion.HIDDEN and not cycle.ready,"deactivation during raise waits hidden")
	print("D9 TIMELINE FAILURES: ", failures)
	quit(1 if failures else 0)
