extends StaticBody2D

class_name button

signal interacted
@onready var sprite_open = $Sprite2D/open
@onready var sprite_pressed = $Sprite2D/pressed
var button_pressed = false
@export var door : door_for_button = null



func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		if button_pressed: #von gedrückt auf open
			interacted.emit()
			sprite_open.visible = true
			sprite_pressed.visible = false
			print("player entered button")
			button_pressed = false
		else: # von open auf gedrückt
			interacted.emit()
			sprite_open.visible = false
			sprite_pressed.visible = true
			print("player entered button")
			button_pressed = true
		


func _on_area_2d_body_exited(body):
	pass # Replace with function body.
