class_name SwitchDoor
extends StaticBody2D
## Tür, die von außen geöffnet und geschlossen wird, z. B. über das Signal eines FloorSwitch.

signal opened
signal closed

@export var is_open: bool = false:
	set(value):
		is_open = value
		if is_node_ready():
			_apply()

@onready var _sprite_open: Sprite2D = $SpriteOpen
@onready var _sprite_closed: Sprite2D = $SpriteClosed
@onready var _blocker: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply()


func set_open(open: bool) -> void:
	if open == is_open:
		return
	is_open = open
	if open:
		opened.emit()
	else:
		closed.emit()


func _apply() -> void:
	_sprite_open.visible = is_open
	_sprite_closed.visible = not is_open
	_blocker.set_deferred("disabled", is_open)
