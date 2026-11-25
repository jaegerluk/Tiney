class_name DungeonItemPickup
extends Pickup
## Karte oder Kompass des aktuellen Dungeons. Meist Inhalt einer Truhe.

enum Kind { MAP, COMPASS }

@export var kind: Kind = Kind.MAP


func get_message() -> String:
	return "You found the Dungeon Map!" if kind == Kind.MAP else "You found the Compass!"


func _apply(_player: Player) -> bool:
	if kind == Kind.MAP:
		GameState.give_map()
	else:
		GameState.give_compass()
	return true
