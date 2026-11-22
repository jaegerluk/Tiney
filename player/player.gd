class_name Player
extends CharacterBody2D
## Der Held: Bewegung in 8 Richtungen, Blickrichtung in 4 Richtungen, Schwertangriff mit Hitbox.

signal health_changed(current: int, maximum: int)
signal died

## Pixel pro Sekunde.
@export var move_speed: float = 90.0
## In halben Herzen: 6 = 3 Herzen.
@export var max_health: int = 6
@export var inventory: Inventory
## Abstand der Schwert-Hitbox vom Mittelpunkt in Blickrichtung.
@export var sword_reach: float = 12.0

var health: int
## Immer eine der vier Grundrichtungen.
var facing: Vector2 = Vector2.DOWN

var _attacking: bool = false
var _controls_enabled: bool = true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _anim_tree.get("parameters/playback")
@onready var _sword_hitbox: Area2D = $SwordHitbox
@onready var _sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	health = max_health
	_anim_tree.animation_finished.connect(_on_animation_finished)
	_sword_shape.disabled = true
	_set_facing(facing)


func _physics_process(_delta: float) -> void:
	if not _controls_enabled:
		velocity = Vector2.ZERO
		_playback.travel("idle")
	elif _attacking:
		velocity = Vector2.ZERO
	else:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input * move_speed
		if input != Vector2.ZERO:
			_set_facing(_facing_from(input))
		if Input.is_action_just_pressed("attack"):
			_start_attack()
		else:
			_playback.travel("walk" if input != Vector2.ZERO else "idle")
	move_and_slide()


## Nimmt einen Gegenstand ins Inventar auf. Gibt false zurück, wenn kein Platz frei ist.
func collect(item: Item) -> bool:
	return inventory != null and inventory.insert(item)


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func is_attacking() -> bool:
	return _attacking


## Sperrt die Steuerung, z. B. während eines Raumwechsels.
func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled


## Dreht den Spieler in eine der vier Grundrichtungen.
func face(direction: Vector2) -> void:
	_set_facing(direction)


## Bei Diagonalen bleibt die Blickrichtung erhalten, wenn sie Teil der Diagonale ist (wie in ALttP).
func _facing_from(input: Vector2) -> Vector2:
	var horizontal := Vector2(signf(input.x), 0.0)
	var vertical := Vector2(0.0, signf(input.y))
	var diagonal := absf(input.x) > 0.1 and absf(input.y) > 0.1
	if diagonal and (facing == horizontal or facing == vertical):
		return facing
	return horizontal if absf(input.x) >= absf(input.y) else vertical


func _set_facing(direction: Vector2) -> void:
	facing = direction
	_sprite.flip_h = direction.x < 0.0
	for state in ["idle", "walk", "attack"]:
		_anim_tree.set("parameters/%s/blend_position" % state, direction)
	_sword_hitbox.position = direction * sword_reach
	_sword_hitbox.rotation = direction.angle()


func _start_attack() -> void:
	_attacking = true
	_sword_shape.set_deferred("disabled", false)
	_playback.travel("attack")


func _on_animation_finished(anim_name: StringName) -> void:
	if String(anim_name).begins_with("attack"):
		_attacking = false
		_sword_shape.set_deferred("disabled", true)
