extends RefCounted

const Player = preload("res://scripts/player.gd")

static func wait_for(player: Player, weapon: int) -> bool:
	for tick in 100:
		if player.reload_cycle.ready and player.weapon_index == weapon and player.rig.weapon_index == weapon:
			return true
		player._advance_reload(.01)
		player._update_view(.01)
	return false
