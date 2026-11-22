class_name Zombie
extends Enemy
## Zombie: steht, bis er den Spieler wahrnimmt, und schlurft ihm dann stur hinterher.

## Ab dieser Entfernung (Pixel) bemerkt er den Spieler. Danach folgt er immer.
@export var sense_range: float = 96.0
## Sekunden pro Lauf-Frame.
@export var step_time: float = 0.25

var _noticed: bool = false
var _step: float = 0.0


func _ai_velocity(delta: float) -> Vector2:
	var player := find_player()
	if player == null:
		return Vector2.ZERO
	if not _noticed and global_position.distance_to(player.global_position) <= sense_range:
		_noticed = true
	if not _noticed:
		return Vector2.ZERO
	var direction := global_position.direction_to(player.global_position)
	_step += delta
	if _step >= step_time:
		_step = 0.0
		_sprite.frame = 1 - _sprite.frame
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0
	return direction * move_speed


func is_chasing() -> bool:
	return _noticed
