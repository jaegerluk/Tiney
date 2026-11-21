class_name HealthBar
extends ProgressBar
## Einfache Lebensanzeige (Platzhalter für Herzen). Wird über Player.health_changed versorgt.


func show_health(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
