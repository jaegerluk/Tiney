class_name Item
extends Resource
## Ein Gegenstand, der ins Inventar aufgenommen werden kann.
## Benutzbare Items werden im Menü ausgewählt und mit "use_item" eingesetzt.

@export var name: String = ""
@export var texture: Texture2D
## Heilung beim Benutzen in LP (20 = 1 Herz). 0 = keine Heilwirkung.
@export var heal_amount: int = 0
## Wird beim Benutzen verbraucht.
@export var consumable: bool = true


func is_usable() -> bool:
	return heal_amount > 0


## Wirkung auf den Spieler. false = nichts passiert (z. B. Leben schon voll), dann wird nichts verbraucht.
func use(player: Player) -> bool:
	if heal_amount > 0:
		if player.health >= player.max_health:
			return false
		player.heal(heal_amount)
		return true
	return false
