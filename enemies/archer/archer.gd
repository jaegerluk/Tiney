class_name Archer
extends Enemy
## Skelett-Schütze: hält Abstand, stellt sich in Zeile oder Spalte des Spielers und schießt geradeaus
## (4 Richtungen). Zielt vorher kurz, damit man ausweichen kann. Schießt nur auf dem Bildschirm.

enum State { MOVE, AIM }

@export var arrow_scene: PackedScene
## Wunschabstand zum Spieler (Pixel): näher -> zurückweichen, weiter -> herankommen.
@export var min_distance: float = 64.0
@export var max_distance: float = 96.0
## So genau muss er in Linie stehen (Pixel), um zu schießen.
@export var align_tolerance: float = 4.0
@export var aim_time: float = 0.4
@export var fire_interval: float = 2.0
## Pfeilschaden in LP bei 4,0 (10 = ½ Herz) und Pfeiltempo.
@export var arrow_damage: int = 10
@export var arrow_speed: float = 120.0
@export var step_time: float = 0.25

var state: State = State.MOVE
var _cooldown: float = 1.0
var _aim_left: float = 0.0
var _shot_direction: Vector2 = Vector2.ZERO
var _step: float = 0.0


func _ai_velocity(delta: float) -> Vector2:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var player := find_player()
	if player == null or not RoomCamera.is_on_screen(self):
		_sprite.frame = 0
		return Vector2.ZERO
	var offset := player.global_position - global_position
	if state == State.AIM:
		_sprite.frame = 2
		_aim_left -= delta
		if _aim_left <= 0.0:
			_fire()
			state = State.MOVE
		return Vector2.ZERO
	# Achse wählen: In der Richtung mit dem kleineren Abstand ausrichten, in der anderen Abstand halten.
	var horizontal_line := absf(offset.y) <= absf(offset.x)
	var along := offset.x if horizontal_line else offset.y
	var across := offset.y if horizontal_line else offset.x
	var desired := Vector2.ZERO
	var distance := absf(along)
	var along_dir := signf(along)
	if distance < min_distance:
		desired += (Vector2(-along_dir, 0) if horizontal_line else Vector2(0, -along_dir))
	elif distance > max_distance:
		desired += (Vector2(along_dir, 0) if horizontal_line else Vector2(0, along_dir))
	if absf(across) > align_tolerance:
		desired += (Vector2(0, signf(across)) if horizontal_line else Vector2(signf(across), 0))
	elif _cooldown <= 0.0 and distance <= max_distance + 16.0:
		state = State.AIM
		_aim_left = aim_time
		_shot_direction = Vector2(along_dir, 0) if horizontal_line else Vector2(0, along_dir)
		_sprite.flip_h = _shot_direction.x < 0.0
		return Vector2.ZERO
	if desired != Vector2.ZERO:
		_step += delta
		if _step >= step_time:
			_step = 0.0
			_sprite.frame = 1 - _sprite.frame if _sprite.frame < 2 else 0
		if offset.x != 0.0:
			_sprite.flip_h = offset.x < 0.0
	else:
		_sprite.frame = 0
	return desired.normalized() * move_speed


func _fire() -> void:
	_cooldown = fire_interval
	if arrow_scene == null:
		return
	var arrow: Projectile = arrow_scene.instantiate()
	arrow.team = Projectile.Team.ENEMY
	arrow.base_damage = arrow_damage
	arrow.speed = arrow_speed
	arrow.direction = _shot_direction
	arrow.position = position + _shot_direction * 10.0 + Vector2(0, -6)
	get_parent().add_child(arrow)
