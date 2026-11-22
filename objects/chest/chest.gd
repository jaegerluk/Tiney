class_name Chest
extends StaticBody2D
## Truhe mit festem Inhalt (eine Pickup-Szene). Öffnen: daneben stehen, zur Truhe schauen, "interact".
## Bleibt offen (Zustand in GameState). Den Inhalt zeigt Game: Der Held hält ihn hoch, dazu eine Meldung.

signal item_presented(icon: Texture2D, message: String)

## Pickup-Szene, z. B. res://items/pickups/big_key.tscn. Leer = leere Truhe.
@export var content: PackedScene

var is_open: bool = false
var _player: Player = null

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if owner != null and GameState.get_value(GameState.flag_id(self), false):
		is_open = true
	_sprite.frame = 1 if is_open else 0
	var sensor: Area2D = $Sensor
	sensor.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			_player = body)
	sensor.body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_player = null)


func _unhandled_input(event: InputEvent) -> void:
	if is_open or _player == null or not event.is_action_pressed("interact"):
		return
	if _player.facing != _direction_from_player():
		return
	get_viewport().set_input_as_handled()
	open(_player)


func open(player: Player) -> void:
	if is_open:
		return
	is_open = true
	_sprite.frame = 1
	if owner != null:
		GameState.set_value(GameState.flag_id(self), true)
	if content == null:
		item_presented.emit(null, "Die Truhe ist leer.")
		return
	var pickup: Pickup = content.instantiate()
	pickup._apply(player)
	item_presented.emit(pickup.get_icon(), pickup.get_message())
	pickup.free()


## Grundrichtung vom Spieler zur Truhe.
func _direction_from_player() -> Vector2:
	var to_chest := global_position - _player.global_position
	if absf(to_chest.x) > absf(to_chest.y):
		return Vector2(signf(to_chest.x), 0.0)
	return Vector2(0.0, signf(to_chest.y))
