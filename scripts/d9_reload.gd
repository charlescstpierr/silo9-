class_name D9Reload
extends RefCounted

enum Motion { READY, RELOAD, LOWER_ABORT, HIDDEN, RAISE }
enum Gesture { SUPPORT, REACH, EXTRACT, STOW, FETCH, INSERT, RACK_REACH, RACK_PULL, RACK_RELEASE, RETURN }
const REMOVE := 1
const INSERT := 2
const RACK_PULL := 4
const RACK_RELEASE := 8
const COMMIT := 16
const HIDDEN := 32
const LOWER_SECONDS := .16
const RAISE_SECONDS := .14

class View extends RefCounted:
	var motion: Motion = Motion.READY
	var gesture: Gesture = Gesture.SUPPORT
	var fraction := 0.0
	var empty := false
	var lower := 0.0

var view := View.new()
var ready: bool:
	get: return view.motion == Motion.READY
var cue_age := 0.0
var _time := 0.0
var _partial := 0.0
var _rack := 0.0

func begin(empty: bool, partial_seconds: float, empty_seconds: float) -> void:
	_time = 0.0
	_partial = partial_seconds
	_rack = empty_seconds-partial_seconds if empty else 0.0
	view.empty = empty
	view.motion = Motion.RELOAD
	view.gesture = Gesture.REACH
	view.fraction = 0.0
	view.lower = 0.0

func cancel() -> void:
	if view.motion == Motion.RELOAD or view.motion == Motion.READY:
		view.motion = Motion.LOWER_ABORT
		_time = 0.0

func advance(delta: float, active: bool) -> int:
	var events := 0
	var before := _time
	if view.motion == Motion.HIDDEN:
		_time = 0.0
	_time += delta
	match view.motion:
		Motion.RELOAD:
			var remove_at := _partial*.28
			var insert_at := _partial*.77
			var pull_at := insert_at+_rack*.7
			var release_at := insert_at+_rack
			if before < remove_at and _time >= remove_at:
				events |= REMOVE
				cue_age = _time-remove_at
			if before < insert_at and _time >= insert_at:
				events |= INSERT
				cue_age = _time-insert_at
			if view.empty and before < pull_at and _time >= pull_at:
				events |= RACK_PULL
				cue_age = _time-pull_at
			if view.empty and before < release_at and _time >= release_at:
				events |= RACK_RELEASE
				cue_age = _time-release_at
			if _time >= _partial+_rack:
				view.motion = Motion.READY
				view.gesture = Gesture.SUPPORT
				view.fraction = 0.0
				events |= COMMIT
			else:
				_update_gesture()
		Motion.LOWER_ABORT:
			view.lower = smoothstep(0,1,_time/LOWER_SECONDS)
			if _time >= LOWER_SECONDS:
				_time -= LOWER_SECONDS
				view.motion = Motion.HIDDEN
				view.lower = 1.0
				events |= HIDDEN
		Motion.HIDDEN:
			if not active:
				_time = 0.0
	if view.motion == Motion.HIDDEN and active:
		view.motion = Motion.RAISE
		view.gesture = Gesture.SUPPORT
		view.fraction = 0.0
	if view.motion == Motion.RAISE:
		view.lower = 1.0-smoothstep(0,1,_time/RAISE_SECONDS)
		if _time >= RAISE_SECONDS:
			view.motion = Motion.READY
			view.lower = 0.0
	return events

func _update_gesture() -> void:
	var end_insert := _partial*.77
	if _time < _partial*.13:
		_gesture(Gesture.REACH,0.0,_partial*.13)
	elif _time < _partial*.28:
		_gesture(Gesture.EXTRACT,_partial*.13,_partial*.28)
	elif _time < _partial*.44:
		_gesture(Gesture.STOW,_partial*.28,_partial*.44)
	elif _time < _partial*.63:
		_gesture(Gesture.FETCH,_partial*.44,_partial*.63)
	elif _time < end_insert:
		_gesture(Gesture.INSERT,_partial*.63,end_insert)
	elif view.empty and _time < end_insert+_rack*.4:
		_gesture(Gesture.RACK_REACH,end_insert,end_insert+_rack*.4)
	elif view.empty and _time < end_insert+_rack*.7:
		_gesture(Gesture.RACK_PULL,end_insert+_rack*.4,end_insert+_rack*.7)
	elif view.empty and _time < end_insert+_rack:
		_gesture(Gesture.RACK_RELEASE,end_insert+_rack*.7,end_insert+_rack)
	else:
		_gesture(Gesture.RETURN,end_insert+_rack,_partial+_rack)

func _gesture(value: Gesture, start: float, end: float) -> void:
	view.gesture = value
	view.fraction = (_time-start)/(end-start)
