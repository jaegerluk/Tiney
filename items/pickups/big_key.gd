class_name BigKeyPickup
extends Pickup
## Großer Schlüssel. Gilt für den Dungeon des aktuellen Raums und wird an der Bosstür verbraucht.


func get_message() -> String:
	return "You got the Big Key!"


func _apply(_player: Player) -> bool:
	GameState.add_big_key()
	return true
