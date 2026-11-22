class_name Breakable
extends StaticBody2D
## Etwas, das ein Schwerthieb zerstört (Krug, Grasbüschel). Kann etwas fallen lassen.
## Erscheint beim erneuten Betreten des Raums wieder.

signal broken

@export var drop_table: DropTable
## Raumvariante: erscheint erst ab dieser Schwierigkeitsstufe.
@export var min_tier: int = 0

var _broken: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	($Hurtbox as Hurtbox).hurt.connect(_on_hurt)


func break_apart() -> void:
	if _broken:
		return
	_broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	broken.emit()
	if drop_table:
		drop_table.spawn(get_parent(), position)
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "scale", Vector2(1.4, 1.4), 0.15)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _on_hurt(_hitbox: Hitbox) -> void:
	break_apart()
