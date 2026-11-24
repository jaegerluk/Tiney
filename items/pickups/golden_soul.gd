class_name GoldenSoulPickup
extends Pickup
## Sammelobjekt (Arbeitstitel „Skulltula“, Platzhalter: goldene Seele). Wird hochgehalten und gezählt.


func get_message() -> String:
	return "You found a Golden Soul! (%d)" % GameState.souls


func _apply(_player: Player) -> bool:
	GameState.add_soul()
	return true
