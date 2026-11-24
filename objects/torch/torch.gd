class_name Torch
extends StaticBody2D
## Fackel (Feuerschale). Brennend erhellt sie dunkle Räume. Anzünden über set_lit(true), z. B. per Signal
## eines Schalters (später durch ein Feuer-Item). burn_time > 0: geht nach dieser Zeit wieder aus
## (flackert vorher). Dauerhaft angezündete Fackeln bleiben über Raumwechsel an.

signal toggled(is_lit: bool)

@export var lit: bool = false
## Sekunden, bis sie wieder ausgeht. 0 = brennt dauerhaft.
@export var burn_time: float = 0.0
@export var flicker_time: float = 0.12

var _burn_left: float = 0.0
var _flicker: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _light: PointLight2D = $PointLight2D


func _ready() -> void:
	if owner != null and burn_time <= 0.0 and GameState.get_value(GameState.flag_id(self), false):
		lit = true
	_apply()
	if lit:
		toggled.emit(true)


func is_lit() -> bool:
	return lit


## Für Schalter-Signale: an = anzünden, aus = nichts (eine Fackel geht nicht mit dem Schalter aus).
func ignite(on: bool = true) -> void:
	if on:
		set_lit(true)


func set_lit(value: bool) -> void:
	if value:
		_burn_left = burn_time
	if value == lit:
		return
	lit = value
	if lit and burn_time <= 0.0 and owner != null:
		GameState.set_value(GameState.flag_id(self), true)
	_apply()
	toggled.emit(lit)


func _process(delta: float) -> void:
	if not lit:
		return
	_flicker += delta
	if _flicker >= flicker_time:
		_flicker = 0.0
		_sprite.frame = 3 - _sprite.frame
	_light.energy = 0.9 + randf() * 0.15
	if burn_time > 0.0:
		_burn_left -= delta
		if _burn_left < 2.0:
			_light.energy *= 0.4 + 0.6 * float(int(_burn_left * 8.0) % 2)
		if _burn_left <= 0.0:
			set_lit(false)


func _apply() -> void:
	_sprite.frame = 1 if lit else 0
	_light.enabled = lit
