class_name SaveStatue
extends StaticBody2D
## Speicherstatue in einer Wasserpfütze. Wer die Pfütze betritt, speichert automatisch (ohne Heilen).
## Nach dem Tod erscheint der Spieler am RespawnPoint mit vollem Leben.

signal save_requested(statue: SaveStatue)

## Sekunden, die „Saved“ sichtbar bleibt.
@export var message_time: float = 1.5

@onready var _bubble: Control = $TextBubble
@onready var _respawn: Marker2D = $RespawnPoint


func _ready() -> void:
	_bubble.visible = false
	($Puddle as Area2D).body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			save_requested.emit(self)
			_show_message())


func respawn_position() -> Vector2:
	return _respawn.global_position


func _show_message() -> void:
	_bubble.visible = true
	await get_tree().create_timer(message_time).timeout
	if is_instance_valid(_bubble):
		_bubble.visible = false
