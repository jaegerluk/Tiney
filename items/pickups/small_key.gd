class_name KeyPickup
extends Pickup
## Kleiner Schlüssel. Gilt für den Dungeon des aktuellen Raums.


func _apply(_player: Player) -> bool:
	GameState.add_key()
	return true
