class_name HeartPickup
extends Pickup
## Herz. Heilt und wird immer aufgenommen, auch bei vollem Leben.

## In LP (20 = 1 Herz).
@export var heal_amount: int = 20


func _apply(player: Player) -> bool:
	player.heal(heal_amount)
	return true
