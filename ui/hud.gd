class_name HUD
extends CanvasLayer
## Bildschirmanzeige: Leben, Inventar-Menü. Wird von Game mit dem Spieler verbunden.

@onready var _health_bar: HealthBar = $HealthBar


func show_health(current: int, maximum: int) -> void:
	_health_bar.show_health(current, maximum)
