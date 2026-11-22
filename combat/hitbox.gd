class_name Hitbox
extends Area2D
## Teilt Schaden aus. Liegt auf der Ebene player_attack oder enemy_attack; Hurtboxen erkennen sie.

## Beim Spieler in LP (1 Herz = 20), bei Gegnern in Treffern (Schwert = 1).
@export var damage: int = 1
## Startgeschwindigkeit des Rückstoßes in Pixeln pro Sekunde.
@export var knockback: float = 150.0


func _init() -> void:
	monitoring = false


## Richtung, in die ein getroffener Körper an `target_position` gestoßen wird.
func knockback_direction(target_position: Vector2) -> Vector2:
	var direction := target_position - global_position
	return direction.normalized() if direction.length() > 0.01 else Vector2.DOWN
