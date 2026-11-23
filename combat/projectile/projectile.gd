class_name Projectile
extends CharacterBody2D
## Geschoss (Pfeil, später Wurfgegenstände und Spieler-Waffen).
## Fliegt geradeaus, trifft über seine Hitbox und verschwindet dabei. An Wänden bleibt es kurz stecken.
## Team ENEMY trifft den Spieler (Ebene enemy_attack), Team PLAYER trifft Gegner (player_attack).
## Gegnerische Geschosse kann ein Schwert mit `deflects_projectiles` zerstören.

signal stuck
signal destroyed

enum Team { ENEMY, PLAYER }

@export var team: Team = Team.ENEMY
@export var speed: float = 120.0
## In LP bei Schwierigkeit 4,0 (bei Team PLAYER: Treffer).
@export var base_damage: int = 10
@export var knockback: float = 100.0
## So lange steckt es in der Wand (Sekunden).
@export var stick_time: float = 1.0
## Sicherheitsgrenze: danach verschwindet es auf jeden Fall.
@export var max_lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var is_stuck: bool = false
var _life: float = 0.0

@onready var _hitbox: Hitbox = $Hitbox
@onready var _hurtbox: Hurtbox = $Hurtbox


## Richtung und Startposition setzen, dann in den Baum hängen.
func launch(from: Vector2, dir: Vector2) -> void:
	global_position = from
	direction = dir.normalized()
	rotation = direction.angle()


func _ready() -> void:
	rotation = direction.angle()
	_hitbox.damage = Difficulty.scaled_int(base_damage, Difficulty.Stat.DAMAGE) if team == Team.ENEMY else base_damage
	_hitbox.knockback = knockback
	_hitbox.collision_layer = 16 if team == Team.ENEMY else 8
	_hitbox.landed.connect(func(_hurtbox: Hurtbox) -> void: _destroy())
	_hurtbox.collision_mask = 8 if team == Team.ENEMY else 0
	_hurtbox.hurt.connect(_on_hurt)


func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= max_lifetime:
		queue_free()
		return
	if is_stuck:
		return
	if move_and_collide(direction * speed * delta):
		_stick()


func _stick() -> void:
	is_stuck = true
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	stuck.emit()
	await get_tree().create_timer(stick_time, false).timeout
	queue_free()


func _destroy() -> void:
	if is_queued_for_deletion():
		return
	destroyed.emit()
	Effects.burst(get_parent(), position, Color(0.9, 0.85, 0.7), 5, 40.0, 0.25, 1.0)
	queue_free()


func _on_hurt(hitbox: Hitbox) -> void:
	if hitbox.deflects_projectiles and not is_stuck:
		_destroy()
