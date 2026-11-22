class_name HeartContainerPickup
extends Pickup
## Herzcontainer: ein Herz mehr Maximum, Leben ganz aufgefüllt.


func get_message() -> String:
	return "Ein Herzcontainer! Deine Lebensenergie steigt."


func _apply(player: Player) -> bool:
	player.add_max_health(Player.HP_PER_HEART)
	return true
