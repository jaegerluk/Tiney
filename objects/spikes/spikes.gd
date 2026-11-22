class_name Spikes
extends Area2D
## Stacheln (ein Tile). Ausgefahren sind sie eine Hitbox auf der Ebene enemy_attack.
## Modus ALWAYS: immer draußen. TIMED: abwechselnd draußen/drin, kurz vorher zittern die Spitzen.
## Schaden = Basiswert × Difficulty (Stat DAMAGE).
## Taktende Stacheln laufen nur, solange sie auf dem Bildschirm sind; sonst sind sie eingefahren,
## und beim Hereinkommen beginnt ihr Takt von vorn.

enum Mode { ALWAYS, TIMED }

@export var mode: Mode = Mode.TIMED
## In LP bei Schwierigkeit 4,0 (10 = ½ Herz).
@export var base_damage: int = 10
@export var knockback: float = 120.0
@export var up_time: float = 1.5
@export var down_time: float = 1.5
## Sekunden Warnung vor dem Ausfahren (in down_time enthalten).
@export var warn_time: float = 0.3
## Versatz im Takt, damit Reihen von Stacheln nacheinander ausfahren.
@export var phase_offset: float = 0.0

var is_up: bool = false
var _time: float = 0.0
var _active: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hitbox: Hitbox = $Hitbox
@onready var _shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	_hitbox.damage = Difficulty.scaled_int(base_damage, Difficulty.Stat.DAMAGE)
	_hitbox.knockback = knockback
	_restart()
	_apply(mode == Mode.ALWAYS, false)


func _physics_process(delta: float) -> void:
	if mode == Mode.ALWAYS:
		return
	if not RoomCamera.is_on_screen(self):
		if _active:
			_active = false
			_apply(false, false)
		return
	if not _active:
		_active = true
		_restart()
	_time = fmod(_time + delta, up_time + down_time)
	var up := _time < up_time
	var warning := not up and _time >= up_time + down_time - warn_time
	_apply(up, warning)


func _restart() -> void:
	_time = fposmod(phase_offset, up_time + down_time)


func _apply(up: bool, warning: bool) -> void:
	if up != is_up:
		is_up = up
		_shape.set_deferred("disabled", not up)
	_sprite.frame = 2 if up else (1 if warning else 0)
