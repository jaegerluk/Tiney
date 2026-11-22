class_name SaveStatue
extends StaticBody2D
## Speicherstatue. Davor stehen, nach oben schauen, "interact": Der Spielstand wird gemerkt (ohne Heilen).
## Nach dem Tod erscheint der Spieler am RespawnPoint mit vollem Leben.

signal save_requested(statue: SaveStatue)

## Sekunden, die „Gespeichert“ sichtbar bleibt.
@export var message_time: float = 1.5

@onready var _bubble: Control = $TextBubble
@onready var _respawn: Marker2D = $RespawnPoint


func _ready() -> void:
	_bubble.visible = false
	($InteractZone as InteractZone).interacted.connect(func(_player: Player) -> void:
		save_requested.emit(self)
		_show_message())


func respawn_position() -> Vector2:
	return _respawn.global_position


func _show_message() -> void:
	_bubble.visible = true
	await get_tree().create_timer(message_time).timeout
	if is_instance_valid(_bubble):
		_bubble.visible = false
