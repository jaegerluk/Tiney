class_name PushBlock
extends AnimatableBody2D
## Schiebeblock: Läuft der Spieler eine Weile dagegen, rutscht er ein Tile weiter, wenn dort Platz ist.
## Die Position bleibt über Raumwechsel erhalten (der Tod setzt sie über die Statue zurück).
## Drückt Bodenschalter (FloorSwitch).

signal moved(new_position: Vector2)

@export var tile_size: float = 16.0
## Sekunden, die man dagegen laufen muss.
@export var push_time: float = 0.3
@export var slide_time: float = 0.25
## Ebenen, die den Weg versperren: world, enemies, npcs.
@export_flags_2d_physics var blocking_mask: int = 1 | 4 | 64

var _player: Player = null
var _push_timer: float = 0.0
var _moving: bool = false


func _ready() -> void:
	if owner != null:
		var saved: Variant = GameState.get_value(GameState.flag_id(self))
		if saved is Vector2:
			position = saved
	var sensor: Area2D = $Sensor
	sensor.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			_player = body)
	sensor.body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_player = null)


func is_moving() -> bool:
	return _moving


func _physics_process(delta: float) -> void:
	if _moving or _player == null:
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


func _push_direction() -> Vector2:
	var to_block := global_position - _player.global_position
	var toward := Vector2(signf(to_block.x), 0.0) if absf(to_block.x) > absf(to_block.y) else Vector2(0.0, signf(to_block.y))
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


func _is_free(target: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile_size - 2.0, tile_size - 2.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, target)
	query.collision_mask = blocking_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
