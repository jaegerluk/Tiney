class_name CrystalSwitch
extends StaticBody2D
## Kristallschalter: reagiert auf Schwerttreffer. Kennt keine Tür, sendet `toggled(is_on)`.
## Modi (Farbe zeigt den Modus):
## - TOGGLE (blau/rot): jeder Treffer schaltet um, bleibt über Raumwechsel erhalten.
## - ONCE (grün, danach grau): erster Treffer schaltet dauerhaft an.
## - TIMED (gelb, orange blinkend): Treffer schaltet für `duration` Sekunden an.

signal toggled(is_on: bool)

enum Mode { TOGGLE, ONCE, TIMED }

@export var mode: Mode = Mode.TOGGLE:
	set(value):
		mode = value
		if is_node_ready():
			_update_sprite()
@export var is_on: bool = false
## Nur TIMED: so lange bleibt er an (Sekunden).
@export var duration: float = 5.0
## Mindestabstand zwischen zwei Treffern (Sekunden).
@export var cooldown: float = 0.3

var _cooldown_left: float = 0.0
var _time_left: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	($Hurtbox as Hurtbox).hurt.connect(_on_hurt)
	if mode != Mode.TIMED and owner != null:
		var saved: Variant = GameState.get_value(GameState.flag_id(self))
		if saved != null and saved != is_on:
			is_on = saved
			toggled.emit(is_on)
	_update_sprite()


func time_left() -> float:
	return _time_left


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if mode == Mode.TIMED and is_on:
		_time_left -= delta
		var blink_fast := _time_left < 1.5
		_sprite.frame = 5 if int(_time_left * (10.0 if blink_fast else 4.0)) % 2 == 0 else 4
		if _time_left <= 0.0:
			_set_on(false)


func _on_hurt(_hitbox: Hitbox) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown
	match mode:
		Mode.TOGGLE:
			_set_on(not is_on)
		Mode.ONCE:
			_set_on(true)
		Mode.TIMED:
			_time_left = duration
			_set_on(true)


func _set_on(value: bool) -> void:
	if value == is_on:
		return
	is_on = value
	if mode != Mode.TIMED and owner != null:
		GameState.set_value(GameState.flag_id(self), is_on)
	_update_sprite()
	toggled.emit(is_on)


func _update_sprite() -> void:
	match mode:
		Mode.TOGGLE:
			_sprite.frame = 1 if is_on else 0
		Mode.ONCE:
			_sprite.frame = 3 if is_on else 2
		Mode.TIMED:
			_sprite.frame = 5 if is_on else 4
