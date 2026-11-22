class_name OrbPickup
extends Pickup
## Magische Kugel. Belohnung eines Dungeon-Bosses. Die ID ist standardmäßig der aktuelle Dungeon.

@export var orb_id: StringName = &""


func get_message() -> String:
	return "Du hast eine magische Kugel gefunden! (%d von 3)" % (GameState.orbs.size())


func _apply(_player: Player) -> bool:
	GameState.add_orb(orb_id if orb_id != &"" else GameState.current_dungeon)
	return true
