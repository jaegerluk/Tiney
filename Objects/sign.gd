extends StaticBody2D

@onready var player = null
@onready var is_visible = false
@onready var label = $CenterContainer/Panel/Label

func _ready():
	label.visible = false

func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		player = body
		is_visible = true

			
			
func _process(delta):
	if is_visible:
		if player.dir == "up":
			label.visible = true
		else:
			label.visible = false
	else:
		label.visible = false
		


func _on_area_2d_body_exited(body):
	if body.has_method("player"):
		player = null
		is_visible = false
