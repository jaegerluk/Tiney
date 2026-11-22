class_name SaveStatue
extends StaticBody2D
## Speicherstatue. Davor stehen, nach oben schauen, "interact": Der Spielstand wird gemerkt (ohne Heilen).
## Nach dem Tod erscheint der Spieler am RespawnPoint mit vollem Leben.

signal save_requested(statue: SaveStatue)

## Sekunden, die „Gespeichert“ sichtbar bleibt.
@export var message_time: float = 1.5

var _player: Player = null

@onready var _bubble: Control = $TextBubble
@onready var _respawn: Marker2D = $RespawnPoint


func _ready() -> void:
	_bubble.visible = false
	var area: Area2D = $UseArea
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			_player = body)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_player = null)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not event.is_action_pressed("interact") or _player.facing != Vector2.UP:
		return
	get_viewport().set_input_as_handled()
	save_requested.emit(self)
	_show_message()


func respawn_position() -> Vector2:
	return _respawn.global_position


func _show_message() -> void:
	_bubble.visible = true
	await get_tree().create_timer(message_time).timeout
	if is_instance_valid(_bubble):
		_bubble.visible = false
