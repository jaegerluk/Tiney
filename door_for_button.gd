extends StaticBody2D

class_name door_for_button

var open = false
@onready var sprite_open = $Sprite2D/open
@onready var sprite_closed = $Sprite2D/closed
@onready var collision = $collision_blockade
@export var button : button = null

func _ready():
	button.interacted.connect(open_close)

func open_close():
	if open:
		sprite_closed.visible = true
		sprite_open.visible = false
		open = false
		collision.disabled = false
	else:
		sprite_closed.visible = false
		sprite_open.visible = true
		open = true
		collision.disabled = true

func _on_area_2d_body_entered(body):
	pass # Replace with function body.


func _on_area_2d_body_exited(body):
	pass # Replace with function body.
