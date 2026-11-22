class_name Slime
extends Enemy
## Schleim: wartet kurz, hüpft dann. Ist der Spieler in Reichweite, hüpft er auf ihn zu.

## Ab dieser Entfernung (Pixel) verfolgt der Schleim den Spieler.
@export var chase_range: float = 64.0
@export var hop_time: float = 0.4
@export var rest_time_min: float = 0.5
@export var rest_time_max: float = 1.1

var _hopping: bool = false
var _timer: float = 0.0
var _direction: Vector2 = Vector2.ZERO

@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	super()
	_timer = randf_range(rest_time_min, rest_time_max)
	_anim.play("idle")


func _ai_velocity(delta: float) -> Vector2:
	_timer -= delta
	if _timer <= 0.0:
		if _hopping:
			_hopping = false
			_timer = randf_range(rest_time_min, rest_time_max)
			_anim.play("idle")
		else:
			_hopping = true
			_timer = hop_time
			_direction = _choose_direction()
			_anim.play("hop")
	if _direction.x != 0.0:
		_sprite.flip_h = _direction.x < 0.0
	return _direction * move_speed if _hopping else Vector2.ZERO


func _choose_direction() -> Vector2:
	var player := find_player()
	if player and global_position.distance_to(player.global_position) <= chase_range:
		return global_position.direction_to(player.global_position)
	if randf() < 0.3:
		return Vector2.ZERO
	return Vector2.from_angle(randf() * TAU)


func _play_death() -> void:
	_anim.play("death")
	await _anim.animation_finished
	queue_free()
