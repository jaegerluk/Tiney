class_name HeartPickup
extends Pickup
## Herz. Heilt, wird aber nur bei fehlendem Leben aufgenommen.

## In halben Herzen.
@export var heal_amount: int = 2


func _apply(player: Player) -> bool:
	if player.health >= player.max_health:
		return false
	player.heal(heal_amount)
	return true
