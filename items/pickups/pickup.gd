class_name Pickup
extends Area2D
## Basis für alles, was der Spieler durch Berühren aufnimmt. Unterklassen überschreiben _apply().

signal collected

## Dauerhaft: Einmal aufgenommen, erscheint es beim erneuten Betreten des Raums nicht wieder.
@export var persistent: bool = false


func _ready() -> void:
	if persistent and GameState.has_flag(GameState.flag_id(self)):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


## Wirkung auf den Spieler. false = nicht aufgenommen (z. B. Inventar voll, Leben schon voll).
func _apply(_player: Player) -> bool:
	return false


func _on_body_entered(body: Node2D) -> void:
	if body is Player and _apply(body as Player):
		if persistent:
			GameState.set_flag(GameState.flag_id(self))
		collected.emit()
		queue_free()
