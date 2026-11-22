class_name FloorSwitch
extends Area2D
## Bodenschalter. Kennt keine Tür: Die Elternszene verbindet `toggled` mit dem Ziel, z. B. SwitchDoor.set_open.
## Modi:
## - TOGGLE: Jedes Betreten durch den Spieler schaltet um; ein Schiebeblock schaltet an.
##   Der Zustand bleibt über Raumwechsel erhalten; beim Laden wird `toggled` erneut gesendet.
## - HOLD: An, solange der Spieler oder ein Schiebeblock darauf steht (eigene, orange Szene).

signal toggled(is_on: bool)

enum Mode { TOGGLE, HOLD }

@export var mode: Mode = Mode.TOGGLE
@export var is_on: bool = false

var _pressers: Array[Node2D] = []

@onready var _sprite_off: Sprite2D = $SpriteOff
@onready var _sprite_on: Sprite2D = $SpriteOn


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if mode == Mode.TOGGLE and owner != null:
		var saved: Variant = GameState.get_value(GameState.flag_id(self))
		if saved != null and saved != is_on:
			is_on = saved
			toggled.emit(is_on)
	_update_sprites()


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player or body is PushBlock):
		return
	if mode == Mode.HOLD:
		if not _pressers.has(body):
			_pressers.append(body)
		_set_on(true)
	elif body is Player or not is_on:
		_set_on(not is_on)


func _on_body_exited(body: Node2D) -> void:
	if mode == Mode.HOLD and _pressers.has(body):
		_pressers.erase(body)
		if _pressers.is_empty():
			_set_on(false)


func _set_on(value: bool) -> void:
	if value == is_on:
		return
	is_on = value
	if mode == Mode.TOGGLE and owner != null:
		GameState.set_value(GameState.flag_id(self), is_on)
	_update_sprites()
	toggled.emit(is_on)


func _update_sprites() -> void:
	_sprite_off.visible = not is_on
	_sprite_on.visible = is_on
