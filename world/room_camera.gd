class_name RoomCamera
extends Camera2D
## Kamera mit festen Grenzen. Die Grenzen kommen von zwei Markern in der Raumszene.

@export var top_left: Marker2D
@export var bottom_right: Marker2D


func _ready() -> void:
	if top_left and bottom_right:
		set_bounds(Rect2(top_left.global_position, bottom_right.global_position - top_left.global_position))


func set_bounds(bounds: Rect2) -> void:
	limit_left = roundi(bounds.position.x)
	limit_top = roundi(bounds.position.y)
	limit_right = roundi(bounds.end.x)
	limit_bottom = roundi(bounds.end.y)
