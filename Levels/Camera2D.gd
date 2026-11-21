extends Camera2D

@onready var topleft = $Node/Marker_top_left
@onready var bottomright = $Node/Marker_bottom_right

func _ready():
	limit_top = topleft.position.y
	limit_left = topleft.position.x
	limit_bottom = bottomright.position.y
	limit_right = bottomright.position.x
