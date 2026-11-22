class_name SwitchDoor
extends StaticBody2D
## Tür, die von außen geöffnet und geschlossen wird, z. B. über das Signal eines FloorSwitch.
## Mehrere Schalter können dieselbe Tür steuern: Sie ist offen, solange mindestens einer an ist.

signal opened
signal closed

@export var is_open: bool = false:
	set(value):
		is_open = value
		if is_node_ready():
			_apply()

## Wie viele verbundene Schalter gerade „offen“ melden.
var _open_requests: int = 0

@onready var _sprite_open: Sprite2D = $SpriteOpen
@onready var _sprite_closed: Sprite2D = $SpriteClosed
@onready var _blocker: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply()


## Von Schaltern über `toggled` aufgerufen. Jeder Schalter meldet abwechselnd an und aus.
func set_open(open: bool) -> void:
	_open_requests = maxi(_open_requests + (1 if open else -1), 0)
	var should_open := _open_requests > 0
	if should_open == is_open:
		return
	is_open = should_open
	if should_open:
		opened.emit()
	else:
		closed.emit()


func _apply() -> void:
	_sprite_open.visible = is_open
	_sprite_closed.visible = not is_open
	_blocker.set_deferred("disabled", is_open)
