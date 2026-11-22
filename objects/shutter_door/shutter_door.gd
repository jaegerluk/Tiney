class_name ShutterDoor
extends StaticBody2D
## Gittertür. Wird von einem RoomLock geschlossen und geöffnet.

@export var is_open: bool = true:
	set(value):
		is_open = value
		if is_node_ready():
			_apply()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _blocker: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply()


## true, wenn der Spieler gerade im Türbereich steht (dann noch nicht schließen).
func is_blocked() -> bool:
	for body in ($Clearance as Area2D).get_overlapping_bodies():
		if body is Player:
			return true
	return false


func _apply() -> void:
	_sprite.frame = 1 if is_open else 0
	_blocker.set_deferred("disabled", is_open)
