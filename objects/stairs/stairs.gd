@tool
class_name Stairs
extends RoomExit
## Treppe: ein Ausgang mit eigenem Sprite. Betritt man die Mitte, geht es in den Zielraum.

@export var going_up: bool = false:
	set(value):
		going_up = value
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.frame = 1 if going_up else 0


func _ready() -> void:
	going_up = going_up
	if Engine.is_editor_hint():
		return
	super()
