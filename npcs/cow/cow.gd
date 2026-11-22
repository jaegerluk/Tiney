class_name Cow
extends CharacterBody2D
## Kuh: steht herum, läuft ab und zu in eine zufällige Richtung. Blockiert den Weg, macht keinen Schaden.
## Ein Schwerthieb stößt sie nur kurz zurück.

## Pixel pro Sekunde.
@export var move_speed: float = 20.0
## Ungefähre Dauer in Sekunden (±30 % Zufall).
@export var idle_time: float = 5.0
@export var walk_time: float = 2.0
@export var knockback_time: float = 0.2

var _walking: bool = false
var _timer: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _knockback_left: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	($Hurtbox as Hurtbox).hurt.connect(_on_hurt)
	_timer = _vary(idle_time)
	_anim.play("idle")


func _physics_process(delta: float) -> void:
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback_velocity
	else:
		_timer -= delta
		if _timer <= 0.0:
			_walking = not _walking
			if _walking:
				_direction = Vector2(randi_range(-1, 1), randi_range(-1, 1)).normalized()
				_timer = _vary(walk_time)
				_anim.play("walk" if _direction != Vector2.ZERO else "idle")
			else:
				_timer = _vary(idle_time)
				_anim.play("idle")
		velocity = _direction * move_speed if _walking else Vector2.ZERO
		if velocity.x != 0.0:
			_sprite.flip_h = velocity.x < 0.0
	move_and_slide()


func _on_hurt(hitbox: Hitbox) -> void:
	_knockback_velocity = hitbox.knockback_direction(global_position) * hitbox.knockback
	_knockback_left = knockback_time


func _vary(seconds: float) -> float:
	return seconds * randf_range(0.7, 1.3)
