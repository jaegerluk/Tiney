class_name Bat
extends Enemy
## Fledermaus: flattert in zufällige Richtungen, wechselt oft den Kurs und setzt sich ab und zu kurz hin.
## Verfolgt den Spieler nicht gezielt. Fliegt über Löcher und Stacheln, stößt an Wände.

enum State { FLY, REST }

## Flugphase und Rast (Sekunden, Zufall zwischen min und max).
@export var fly_time_min: float = 1.5
@export var fly_time_max: float = 3.0
@export var rest_time_min: float = 0.8
@export var rest_time_max: float = 1.6
## So oft wechselt sie im Flug die Richtung (Sekunden).
@export var turn_time_min: float = 0.3
@export var turn_time_max: float = 0.7
@export var flap_time: float = 0.1

var state: State = State.FLY
var _timer: float = 0.0
var _turn_timer: float = 0.0
var _flap: float = 0.0
var _direction: Vector2 = Vector2.RIGHT
var _bob: float = 0.0

## Höhe der Treffer- und Schlagzone: im Flug auf Flügelhöhe, sitzend am Boden.
const FLY_ZONE_Y := -5.0
const REST_ZONE_Y := 1.0


func _ready() -> void:
	super()
	if _dead:
		return
	_start_flying()


func _ai_velocity(delta: float) -> Vector2:
	_timer -= delta
	match state:
		State.REST:
			_sprite.frame = 2
			_sprite.offset.y = 0.0
			if _timer <= 0.0:
				_start_flying()
			return Vector2.ZERO
		_:
			_turn_timer -= delta
			if _turn_timer <= 0.0 or get_slide_collision_count() > 0:
				_new_direction()
			_flap += delta
			if _flap >= flap_time:
				_flap = 0.0
				_sprite.frame = 1 - _sprite.frame if _sprite.frame < 2 else 0
			_bob += delta * 8.0
			_sprite.offset.y = -6.0 + sin(_bob) * 1.5
			if _timer <= 0.0:
				state = State.REST
				_timer = randf_range(rest_time_min, rest_time_max)
				_set_zone_y(REST_ZONE_Y)
			return _direction * move_speed


func _start_flying() -> void:
	state = State.FLY
	_set_zone_y(FLY_ZONE_Y)
	_timer = randf_range(fly_time_min, fly_time_max)
	_sprite.frame = 0
	_new_direction()


func _set_zone_y(y: float) -> void:
	($Hitbox/CollisionShape2D as CollisionShape2D).position.y = y
	($Hurtbox/CollisionShape2D as CollisionShape2D).position.y = y


func _new_direction() -> void:
	_turn_timer = randf_range(turn_time_min, turn_time_max)
	_direction = Vector2.from_angle(randf() * TAU)
