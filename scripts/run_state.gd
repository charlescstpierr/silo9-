class_name SiloState
extends RefCounted

signal changed

enum Phase { ARRIVAL, RELAY_FOUND, POWER_RESTORED, CORE_RECOVERED, COMPLETE }
const FACT_IDS: Array[String] = ["relay_location", "power_restored", "core_recovered", "surface_signal", "n7_autonomy", "mother_directive", "ending_mother", "ending_n7", "arc_lock_disabled"]
const SAVE_LIMIT: int = 65536
var health: float = 100.0
var energy: float = 100.0
var ammo: int = 12
var reserve: int = 48
var components: int = 0
var medkits: int = 2
var cells: int = 2
var upgraded: bool = false
var phase: int = Phase.ARRIVAL
var ending: String = ""
var collected: Array[String] = []
var defeated: Array[String] = []
var facts: Array[String] = []
var memory: Array[String] = []
var player_position: Vector3 = Vector3(0, 0, 7)
var player_yaw: float = 0.0
var elapsed: float = 0.0
var relations: Dictionary[String, int] = {"mother": 0, "n7": 0}

func change_trust(character: String, delta: int) -> bool:
	if not relations.has(character) or delta not in [-1, 1]:
		return false
	relations[character] = clampi(relations[character] + delta, -5, 5)
	remember("Relation avec %s : %s." % [character, "confiance renforcée" if delta == 1 else "méfiance accrue"])
	changed.emit()
	return true

func spend_energy(amount: float) -> bool:
	if not is_finite(amount) or amount < 0.0 or amount > energy:
		return false
	energy -= amount
	changed.emit()
	return true

func damage(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	changed.emit()

func heal() -> bool:
	if medkits <= 0 or health >= 100.0 or health <= 0.0:
		return false
	medkits -= 1
	health = minf(100.0, health + 45.0)
	changed.emit()
	return true

func use_cell() -> bool:
	if cells <= 0 or energy >= max_energy():
		return false
	cells -= 1
	energy = minf(max_energy(), energy + 60.0)
	changed.emit()
	return true

func collect(id: String, kind: String, amount: int = 1) -> bool:
	if not _valid_id(id) or collected.has(id) or collected.size() >= 256 or amount <= 0 or amount > 100:
		return false
	match kind:
		"components":
			if components + amount > 999: return false
			components += amount
		"ammo":
			if reserve + amount > 999: return false
			reserve += amount
		"medkit", "medkits":
			if medkits + amount > 99: return false
			medkits += amount
		"cell", "cells":
			if cells + amount > 99: return false
			cells += amount
		_:
			return false
	collected.append(id)
	changed.emit()
	return true

func discover_relay() -> bool:
	if phase != Phase.ARRIVAL:
		return false
	phase = Phase.RELAY_FOUND
	add_fact("relay_location")
	remember("SCAN ÉCHO a révélé l'accès au relais.")
	changed.emit()
	return true

func repair_relay() -> bool:
	if phase != Phase.RELAY_FOUND or components < 3:
		return false
	components -= 3
	phase = Phase.POWER_RESTORED
	add_fact("power_restored")
	remember("Le joueur a réparé le relais.")
	changed.emit()
	return true

func recover_core() -> bool:
	if phase != Phase.POWER_RESTORED:
		return false
	phase = Phase.CORE_RECOVERED
	add_fact("core_recovered")
	remember("Le joueur transporte le noyau de contrôle.")
	changed.emit()
	return true

func choose_ending(choice: String) -> bool:
	if phase != Phase.CORE_RECOVERED or choice not in ["mother", "n7"]:
		return false
	ending = choice
	phase = Phase.COMPLETE
	add_fact("ending_" + choice)
	remember("Le noyau a été confié à " + ("MÈRE." if choice == "mother" else "N-7."))
	changed.emit()
	return true

func upgrade() -> bool:
	if upgraded or components < 3:
		return false
	components -= 3
	upgraded = true
	remember("La batterie de l'ascenseur a été améliorée.")
	changed.emit()
	return true

func recharge() -> void:
	energy = max_energy()
	changed.emit()

func max_energy() -> float:
	return 150.0 if upgraded else 100.0

func fire_round() -> bool:
	if ammo <= 0:
		return false
	ammo -= 1
	changed.emit()
	return true

func reload_rounds(capacity: int = 12) -> int:
	if capacity <= 0 or capacity > 12:
		return 0
	var loaded: int = mini(maxi(capacity - ammo, 0), reserve)
	ammo += loaded
	reserve -= loaded
	if loaded > 0:
		changed.emit()
	return loaded

func mark_defeated(id: String) -> void:
	if _valid_id(id) and not defeated.has(id) and defeated.size() < 128:
		defeated.append(id)
		changed.emit()

func remember(event: String) -> void:
	var bounded: String = event.strip_edges().left(240)
	if bounded.is_empty() or (not memory.is_empty() and memory.back() == bounded):
		return
	memory.append(bounded)
	if memory.size() > 32:
		memory.pop_front()
	changed.emit()

func add_fact(id: String) -> void:
	if FACT_IDS.has(id) and not facts.has(id):
		facts.append(id)
		changed.emit()

func objective() -> String:
	match phase:
		Phase.ARRIVAL: return "Explorer la maintenance. SCAN ÉCHO révèle l'accès au relais."
		Phase.RELAY_FOUND: return "Récupérer 3 composants et réparer le relais."
		Phase.POWER_RESTORED: return "Rejoindre le cœur et récupérer le noyau de contrôle."
		Phase.CORE_RECOVERED: return "Revenir à l'ascenseur. Choisir à qui confier le noyau."
		_: return "Mission terminée — " + ("protection de MÈRE." if ending == "mother" else "autonomie de N-7.")

func save_game(path: String = "user://silo9-save.json") -> Error:
	var data: Dictionary = _snapshot()
	if not _valid_snapshot(data):
		return ERR_INVALID_DATA
	var temp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var result: Error = file.get_error()
	file.close()
	if result != OK:
		return result
	return DirAccess.rename_absolute(temp, path)

func load_game(path: String = "user://silo9-save.json") -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	if file.get_length() > SAVE_LIMIT:
		file.close()
		return ERR_FILE_CORRUPT
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return ERR_FILE_CORRUPT
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not _valid_snapshot(parsed):
		return ERR_FILE_CORRUPT
	var data: Dictionary = parsed
	health = float(data.health)
	energy = float(data.energy)
	ammo = int(data.ammo)
	reserve = int(data.reserve)
	components = int(data.components)
	medkits = int(data.medkits)
	cells = int(data.cells)
	upgraded = data.upgraded
	phase = int(data.phase)
	ending = data.ending
	collected.assign(data.collected)
	defeated.assign(data.defeated)
	facts.assign(data.facts)
	memory.assign(data.memory)
	player_position = Vector3(float(data.player_position[0]), float(data.player_position[1]), float(data.player_position[2]))
	player_yaw = float(data.player_yaw)
	elapsed = float(data.elapsed)
	relations.assign(data.relations)
	changed.emit()
	return OK

func _snapshot() -> Dictionary:
	return {"schema": 2, "relations": relations, "health": health, "energy": energy, "ammo": ammo, "reserve": reserve, "components": components, "medkits": medkits, "cells": cells, "upgraded": upgraded, "phase": phase, "ending": ending, "collected": collected, "defeated": defeated, "facts": facts, "memory": memory, "player_position": [player_position.x, player_position.y, player_position.z], "player_yaw": player_yaw, "elapsed": elapsed}

func _valid_snapshot(data: Dictionary) -> bool:
	var required: Array = _snapshot().keys()
	if data.size() != required.size(): return false
	for key: String in required:
		if not data.has(key): return false
	if not _number(data.schema, 2, 2) or not data.upgraded is bool or not data.ending is String: return false
	if not data.relations is Dictionary or data.relations.size() != 2: return false
	for character: String in ["mother", "n7"]:
		if not _number(data.relations.get(character), -5, 5) or float(data.relations[character]) != floorf(float(data.relations[character])): return false
	for key: String in ["ammo", "reserve", "components", "medkits", "cells", "phase"]:
		if not _number(data[key], 0, 999) or float(data[key]) != floorf(float(data[key])): return false
	if data.ammo > 12 or data.medkits > 99 or data.cells > 99 or data.phase > 4: return false
	if not _number(data.health, 0, 100) or not _number(data.energy, 0, 150 if data.upgraded else 100): return false
	if not _number(data.elapsed, 0, 31536000) or not _number(data.player_yaw, -100000, 100000): return false
	if not data.player_position is Array or data.player_position.size() != 3: return false
	for coord: Variant in data.player_position:
		if not _number(coord, -10000, 10000): return false
	if not _strings(data.collected, 256, 80, true) or not _strings(data.defeated, 128, 80, true): return false
	if not _strings(data.facts, FACT_IDS.size(), 80, true) or not _strings(data.memory, 32, 240, false): return false
	for fact: String in data.facts:
		if not FACT_IDS.has(fact): return false
	var progression: Array[String] = ["relay_location", "power_restored", "core_recovered"]
	for i: int in range(progression.size()):
		if data.facts.has(progression[i]) != (data.phase >= i + 1): return false
	if data.phase == Phase.COMPLETE:
		if data.ending not in ["mother", "n7"] or not data.facts.has("ending_" + data.ending): return false
	elif data.ending != "": return false
	for choice: String in ["mother", "n7"]:
		if data.facts.has("ending_" + choice) != (data.ending == choice): return false
	return true

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

static func _valid_id(value: String) -> bool:
	return not value.is_empty() and value.length() <= 80

static func _strings(value: Variant, maximum: int, length_limit: int, unique: bool) -> bool:
	if not value is Array or value.size() > maximum: return false
	var seen: Dictionary = {}
	for item: Variant in value:
		if not item is String or item.is_empty() or item.length() > length_limit: return false
		if unique and seen.has(item): return false
		seen[item] = true
	return true
