class_name LockedDoor
extends StaticBody2D
## Schlüsseltür. Läuft der Spieler mit einem Schlüssel des aktuellen Dungeons dagegen, geht sie auf.
## Bleibt dauerhaft offen (Merker in GameState).

signal opened

var _player: Player = null
var _opening: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _blocker: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if GameState.has_flag(GameState.flag_id(self)):
		queue_free()
		return
	var sensor: Area2D = $Sensor
	sensor.body_entered.connect(_on_sensor_body_entered)
	sensor.body_exited.connect(_on_sensor_body_exited)


func _physics_process(_delta: float) -> void:
	if _player == null or _opening:
		return
	var to_door := global_position - _player.global_position
	var toward := Vector2(signf(to_door.x), 0.0) if absf(to_door.x) > absf(to_door.y) else Vector2(0.0, signf(to_door.y))
	if _player.facing == toward and _player.move_input.dot(toward) > 0.5 and GameState.use_key():
		_open()


func _open() -> void:
	_opening = true
	GameState.set_flag(GameState.flag_id(self))
	_blocker.set_deferred("disabled", true)
	opened.emit()
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _on_sensor_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body


func _on_sensor_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
