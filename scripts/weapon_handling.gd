class_name WeaponHandling
extends RefCounted

enum Motion { READY, RELOAD, LOWER_ABORT, HIDDEN, RAISE, CELL }
enum Gesture { SUPPORT, REACH, EXTRACT, STOW, FETCH, INSERT, RACK_REACH, RACK_PULL, RACK_RELEASE, RETURN, CELL_REACH, UNLOCK, CELL_GRIP, CELL_EXTRACT, CELL_STOW, CELL_FETCH, CELL_INSERT, LATCH_REACH, LOCK, CELL_RETURN }
const REMOVE := 1
const INSERT := 2
const RACK_PULL := 4
const RACK_RELEASE := 8
const COMMIT := 16
const HIDDEN := 32
const CELL_UNLOCK := 64
const CELL_REMOVE := 128
const CELL_INSERT := 256
const CELL_TRANSFER := 512
const CELL_DONE := 1024
const CELL_REFUSED := 2048
const CELL_CUES := [[.18, CELL_UNLOCK], [.36, CELL_REMOVE], [.72, CELL_INSERT], [.88, CELL_TRANSFER]]
const CELL_THRESHOLDS := [0.0, .10, .18, .25, .36, .47, .59, .72, .79, .88, 1.0]
const CELL_GESTURES := [Gesture.CELL_REACH, Gesture.UNLOCK, Gesture.CELL_GRIP, Gesture.CELL_EXTRACT, Gesture.CELL_STOW, Gesture.CELL_FETCH, Gesture.CELL_INSERT, Gesture.LATCH_REACH, Gesture.LOCK, Gesture.CELL_RETURN]
const D9 = preload("res://data/weapons/d9.tres")
const ARC = preload("res://data/weapons/arc3.tres")
const State = preload("res://scripts/run_state.gd")
enum Cell { NONE, WAITING, ACTIVE, RETURNING }
const LOWER_SECONDS := .16
const RAISE_SECONDS := .14

class View extends RefCounted:
	var motion: Motion = Motion.READY
	var gesture: Gesture = Gesture.SUPPORT
	var fraction := 0.0
	var empty := false
	var lower := 0.0
	var transferred := false

var state: State
var weapon_index := 0
var refusal := ""
var _destination := 0
var _cell: Cell = Cell.NONE
var _cell_return := -1
var view := View.new()
var ready: bool:
	get: return view.motion == Motion.READY
var cue_age := 0.0
var _time := 0.0
var _partial := 0.0
var _rack := 0.0
var _abort_from := 0.0

func request_reload(active: bool) -> bool:
	if weapon_index == 1:
		return request_cell(active)
	if not active or state.health <= 0 or not ready or _cell != Cell.NONE or state.ammo >= D9.capacity or state.reserve <= 0:
		return false
	begin(state.ammo == 0, D9.reload_duration, D9.reload_empty_duration)
	return true

func request_cell(active: bool) -> bool:
	refusal = _cell_refusal(active)
	if refusal.is_empty() and (_cell != Cell.NONE or view.motion in [Motion.RELOAD, Motion.CELL]):
		refusal = "Manipulation déjà en cours."
	if not refusal.is_empty():
		return false
	_cell = Cell.WAITING
	_cell_return = _destination
	_start_cell(active)
	return true

func _cell_refusal(active: bool) -> String:
	if not active or state.health <= 0:
		return "Cellule indisponible maintenant."
	if state.energy >= state.max_energy():
		return "Batterie déjà pleine."
	if state.cells <= 0:
		return "Aucune cellule en réserve."
	return ""

func select(index: int) -> void:
	_cell = Cell.NONE
	_cell_return = -1
	_destination = index
	if ready:
		weapon_index = index
	elif view.motion == Motion.CELL or (view.motion == Motion.RELOAD and index != weapon_index):
		_lower()

func _start_cell(active: bool) -> int:
	if not ready or _cell != Cell.WAITING:
		return 0
	if weapon_index != 1:
		_destination = 1
		_lower()
		return 0
	refusal = _cell_refusal(active)
	if not refusal.is_empty():
		_finish_cell()
		return CELL_REFUSED
	_cell = Cell.ACTIVE
	view.motion = Motion.CELL
	view.gesture = Gesture.CELL_REACH
	view.fraction = 0.0
	view.transferred = false
	_time = 0.0
	return 0

func _finish_cell() -> void:
	_cell = Cell.NONE if _cell_return == weapon_index else Cell.RETURNING
	_destination = _cell_return
	_cell_return = -1
	if _destination != weapon_index:
		_lower()

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
	_cell = Cell.NONE
	_cell_return = -1
	if not ready:
		_lower()

func _lower() -> void:
	if view.motion in [Motion.RELOAD,Motion.CELL,Motion.READY,Motion.RAISE]:
		_abort_from = view.lower
		view.motion = Motion.LOWER_ABORT
		_time = 0.0

func advance(delta: float, active: bool) -> int:
	var events := 0
	if state != null and (not active or state.health <= 0):
		active = false
		cancel()
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
				if state != null:
					state.reload_rounds(D9.capacity)
			else:
				_update_gesture()
		Motion.CELL:
			var duration: float = ARC.reload_duration
			for threshold: Array in CELL_CUES:
				var at: float = duration * threshold[0]
				if before < at and _time >= at:
					events |= threshold[1]
					cue_age = _time-at
					if threshold[1] == CELL_TRANSFER:
						view.transferred = state.use_cell()
			if _time >= duration:
				view.motion = Motion.READY
				view.gesture = Gesture.SUPPORT
				view.fraction = 0.0
				events |= CELL_DONE
				_finish_cell()
			else:
				_update_cell_gesture(duration)
		Motion.LOWER_ABORT:
			view.lower = lerpf(_abort_from,1.0,smoothstep(0,1,_time/LOWER_SECONDS))
			if _time >= LOWER_SECONDS:
				_time -= LOWER_SECONDS
				view.motion = Motion.HIDDEN
				view.lower = 1.0
				events |= HIDDEN
				weapon_index = _destination
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
	if ready and _destination != weapon_index:
		_lower()
	if ready and _cell == Cell.RETURNING:
		_cell = Cell.NONE
	events |= _start_cell(active)
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

func _update_cell_gesture(duration: float) -> void:
	for index in CELL_GESTURES.size():
		if _time < duration*CELL_THRESHOLDS[index+1]:
			_gesture(CELL_GESTURES[index],duration*CELL_THRESHOLDS[index],duration*CELL_THRESHOLDS[index+1])
			return
