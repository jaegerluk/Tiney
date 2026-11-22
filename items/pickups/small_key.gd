class_name KeyPickup
extends Pickup
## Kleiner Schlüssel. Gilt für den Dungeon des aktuellen Raums. Standardmäßig dauerhaft.


func _init() -> void:
	persistent = true


func _apply(_player: Player) -> bool:
	GameState.add_key()
	return true
