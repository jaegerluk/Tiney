class_name RoomEntry
extends Marker2D
## Eingang in einen Raum. Der Knotenname ist die ID, auf die RoomExit.target_entry verweist.

## Blickrichtung des Spielers nach dem Betreten.
@export var facing: Vector2 = Vector2.DOWN
