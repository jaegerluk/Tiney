class_name Enemy
extends CharacterBody2D
## Basis für alle Gegner. Werte kommen aus `stats` und werden beim Spawn mit Difficulty skaliert.
## Unterklassen überschreiben _ai_velocity() und optional _play_death() / _on_died().
## Szene braucht: Sprite2D, Hurtbox (Maske player_attack), Hitbox (Ebene enemy_attack).

signal died
signal health_changed(current: int, maximum: int)

## Name für die Boss-Lebensleiste.
@export var display_name: String = ""

@export var stats: EnemyStats
@export var drop_table: DropTable
## Raumvariante: erscheint erst ab dieser Schwierigkeitsstufe.
@export var min_tier: int = 0

## Bereich, den der Gegner nicht verlassen darf (leer = keine Grenze).
## Room setzt ihn in Räumen mit bildschirmweisem Scrollen auf den Start-Bildschirm.
var confine_rect: Rect2 = Rect2()
## Abstand zum Rand des Bereichs in Pixeln.
var confine_margin: float = 8.0
var max_health: int
var health: int
var damage: int
var move_speed: float

var _dead: bool = false
var _knockback_left: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	if GameState.is_gone(self):
		_dead = true
		queue_free()
		return
	add_to_group("enemies")
	max_health = Difficulty.scaled_int(stats.max_health, Difficulty.Stat.HEALTH)
	health = max_health
	damage = Difficulty.scaled_int(stats.damage, Difficulty.Stat.DAMAGE)
	move_speed = Difficulty.scaled(stats.move_speed, Difficulty.Stat.SPEED)
	_hitbox.damage = damage
	_hurtbox.hurt.connect(_on_hurt)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback_velocity
	else:
		velocity = _ai_velocity(delta)
	move_and_slide()
	if confine_rect.has_area():
		var inner := confine_rect.grow(-confine_margin)
		global_position = global_position.clamp(inner.position, inner.end)


func is_dead() -> bool:
	return _dead


## Gewünschte Geschwindigkeit dieses Frames. In Unterklassen überschreiben.
func _ai_velocity(_delta: float) -> Vector2:
	return Vector2.ZERO


## Todesanimation; muss am Ende queue_free() aufrufen.
func _play_death() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "scale", Vector2(1.4, 0.6), 0.12)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


## Hook nach dem Tod (vor Drop und Todesanimation).
func _on_died() -> void:
	pass


func find_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _on_hurt(hitbox: Hitbox) -> void:
	if _dead:
		return
	health = maxi(health - hitbox.damage, 0)
	health_changed.emit(health, max_health)
	_flash()
	Effects.hit_stop(get_tree(), 0.05)
	_knockback_velocity = hitbox.knockback_direction(global_position) * hitbox.knockback * (1.0 - stats.knockback_resistance)
	_knockback_left = 0.15
	if health <= 0:
		_die()


func _flash() -> void:
	_sprite.modulate = Color(4, 4, 4)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	_dead = true
	GameState.mark_gone(self)
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)
	died.emit()
	Effects.burst(get_parent(), position, Color(0.85, 0.85, 0.9, 0.9), 10, 30.0, 0.45, 3.0)
	_on_died()
	if drop_table:
		drop_table.spawn(get_parent(), position)
	_play_death()
