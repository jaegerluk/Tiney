class_name PushBlock
extends AnimatableBody2D
## Schiebeblock: Läuft der Spieler eine Weile dagegen, rutscht er ein Tile weiter, wenn dort Platz ist.
## Die Position bleibt über Raumwechsel erhalten (der Tod setzt sie über die Statue zurück).
## Drückt Bodenschalter (FloorSwitch).
## Ziehen (wenn pullable): davor Interaktion halten, dann wegziehen; Block und Held rücken ein Tile,
## wenn hinter dem Helden Platz ist. Nur schiebbare Blöcke sind dunkler.

signal moved(new_position: Vector2)

@export var tile_size: float = 16.0
## Sekunden, die man dagegen laufen muss.
@export var push_time: float = 0.3
@export var slide_time: float = 0.25
## Ebenen, die den Weg versperren: world, enemies, npcs.
@export_flags_2d_physics var blocking_mask: int = 1 | 4 | 64
## Kann gezogen werden. Aus = nur schiebbar (dunkler dargestellt).
@export var pullable: bool = true
## Farbe für nur schiebbare Blöcke.
@export var push_only_tint: Color = Color(0.6, 0.55, 0.7)

var _player: Player = null
var _push_timer: float = 0.0
var _moving: bool = false
var _grabbed: bool = false


func _ready() -> void:
	if owner != null:
		var saved: Variant = GameState.get_value(GameState.flag_id(self))
		if saved is Vector2:
			position = saved
	if not pullable:
		($Sprite2D as Sprite2D).modulate = push_only_tint
	var sensor: Area2D = $Sensor
	sensor.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			_player = body)
	sensor.body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_release()
			_player = null)


func is_moving() -> bool:
	return _moving


func _physics_process(delta: float) -> void:
	if _moving or _player == null:
		_push_timer = 0.0
		return
	if _update_grab():
		var away := -_toward_block()
		if _player.move_input.dot(away) > 0.5:
			_push_timer += delta
			if _push_timer >= push_time:
				_push_timer = 0.0
				_try_pull(away)
		else:
			_push_timer = 0.0
		return
	var direction := _push_direction()
	if direction == Vector2.ZERO:
		_push_timer = 0.0
		return
	_push_timer += delta
	if _push_timer >= push_time:
		_push_timer = 0.0
		_try_move(direction)


## Grundrichtung vom Spieler zum Block.
func _toward_block() -> Vector2:
	var to_block := global_position - _player.global_position
	return Vector2(signf(to_block.x), 0.0) if absf(to_block.x) > absf(to_block.y) else Vector2(0.0, signf(to_block.y))


## Packt bzw. löst den Griff. Gibt true zurück, solange der Block gehalten wird.
func _update_grab() -> bool:
	var wants := pullable and _player.is_grab_held() and _player.facing == _toward_block()
	if wants and not _grabbed:
		_grabbed = true
		_player.start_grab(self)
	elif not wants and _grabbed:
		_release()
	return _grabbed


func _release() -> void:
	if _grabbed and _player:
		_player.end_grab(self)
	_grabbed = false


func is_grabbed() -> bool:
	return _grabbed


func _push_direction() -> Vector2:
	var toward := _toward_block()
	if _player.facing == toward and _player.move_input.dot(toward) > 0.5:
		return toward
	return Vector2.ZERO


func _try_move(direction: Vector2) -> void:
	if not _is_free(global_position + direction * tile_size):
		return
	_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", position + direction * tile_size, slide_time)
	await tween.finished
	_moving = false
	if owner != null:
		GameState.set_value(GameState.flag_id(self), position)
	moved.emit(position)


## Ziehen: Block und Held rücken gemeinsam ein Tile in Richtung `direction` (vom Block weg).
func _try_pull(direction: Vector2) -> void:
	var player_target := _player.global_position + direction * tile_size
	if not _is_free(player_target + Vector2(0, 4), Vector2(10, 6), [_player.get_rid()]):
		return
	if not _is_free(global_position + direction * tile_size, Vector2.ZERO, [_player.get_rid()]):
		return
	_moving = true
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", position + direction * tile_size, slide_time)
	tween.tween_property(_player, "global_position", player_target, slide_time)
	await tween.finished
	_moving = false
	if owner != null:
		GameState.set_value(GameState.flag_id(self), position)
	moved.emit(position)


func _is_free(target: Vector2, size: Vector2 = Vector2.ZERO, extra_exclude: Array[RID] = []) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = size if size != Vector2.ZERO else Vector2(tile_size - 2.0, tile_size - 2.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, target)
	query.collision_mask = blocking_mask
	var exclude: Array[RID] = [get_rid()]
	exclude.append_array(extra_exclude)
	query.exclude = exclude
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
