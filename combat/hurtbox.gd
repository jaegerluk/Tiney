class_name Hurtbox
extends Area2D
## Nimmt Treffer auf. Die Maske bestimmt, wer treffen darf (Spieler: enemy_attack, sonst player_attack).

signal hurt(hitbox: Hitbox)


func _init() -> void:
	monitorable = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


## Meldet erneut alle Hitboxen, die gerade überlappen (z. B. nach Ende der Unverwundbarkeit).
func recheck() -> void:
	for area in get_overlapping_areas():
		if area is Hitbox:
			hurt.emit(area)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		hurt.emit(area)
