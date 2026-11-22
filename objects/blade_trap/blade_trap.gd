class_name BladeTrap
extends CharacterBody2D
## Klingenfalle, unzerstörbar. Körper auf Ebene 8 (Fallen): stößt an Wände und andere Fallen,
## blockiert den Spieler aber nicht. Schaden über die Hitbox (enemy_attack), skaliert mit Difficulty.
## SENTRY (stahlblau): lauert; steht der Spieler in Zeile/Spalte mit freier Sicht und ist die Falle
##   auf dem Bildschirm, schießt sie los,
##   prallt ab und kehrt langsam zur Ruheposition zurück.
## PATROL (bronze): pendelt ständig zwischen Start und Start + patrol_offset.

enum Mode { SENTRY, PATROL }
enum State { IDLE, ATTACK, RETURN }

@export var mode: Mode = Mode.SENTRY:
	set(value):
		mode = value
		if is_node_ready():
			_sprite.frame = mode
@export var attack_speed: float = 180.0
@export var return_speed: float = 60.0
@export var patrol_speed: float = 70.0
@export var patrol_offset: Vector2 = Vector2(128, 0)
## Halbe Breite des Streifens, in dem der Spieler bemerkt wird (Pixel).
@export var detect_band: float = 8.0
## In LP bei Schwierigkeit 4,0 (20 = 1 Herz).
@export var base_damage: int = 20

var state: State = State.IDLE
var _home: Vector2
var _direction: Vector2 = Vector2.ZERO
var _patrol_forward: bool = true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	_home = position
	_sprite.frame = mode
	_hitbox.damage = Difficulty.scaled_int(base_damage, Difficulty.Stat.DAMAGE)


func _physics_process(delta: float) -> void:
	if mode == Mode.PATROL:
		_patrol(delta)
		return
	match state:
		State.IDLE:
			_look_for_player()
		State.ATTACK:
			_sprite.rotation += delta * 20.0
			if move_and_collide(_direction * attack_speed * delta):
				state = State.RETURN
		State.RETURN:
			position = position.move_toward(_home, return_speed * delta)
			if position.is_equal_approx(_home):
				state = State.IDLE
				_sprite.rotation = 0.0


func _patrol(delta: float) -> void:
	var target := _home + patrol_offset if _patrol_forward else _home
	var step := (target - position).limit_length(patrol_speed * delta)
	_sprite.rotation += delta * 8.0
	if move_and_collide(step) or position.distance_to(target) < 0.5:
		_patrol_forward = not _patrol_forward


func _look_for_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or not RoomCamera.is_on_screen(self):
		return
	var offset := player.global_position - global_position
	var direction := Vector2.ZERO
	if absf(offset.y) <= detect_band and absf(offset.x) > detect_band:
		direction = Vector2(signf(offset.x), 0.0)
	elif absf(offset.x) <= detect_band and absf(offset.y) > detect_band:
		direction = Vector2(0.0, signf(offset.y))
	if direction == Vector2.ZERO or not _line_clear(player.global_position):
		return
	_direction = direction
	state = State.ATTACK


func _line_clear(target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target, 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
