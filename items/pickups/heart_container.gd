class_name HeartContainerPickup
extends Pickup
## Herzcontainer: ein Herz mehr Maximum, Leben ganz aufgefüllt.


func get_message() -> String:
	return "A Heart Container! Your life energy grows."


func _apply(player: Player) -> bool:
	player.add_max_health(Player.HP_PER_HEART)
	return true
