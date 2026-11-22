@tool
class_name Pit
extends Area2D
## Loch. Sind die Füße des Spielers darüber, fällt er.
## Mit Zielraum: Er landet dort (ein Stockwerk tiefer), ohne Schaden.
## Ohne Ziel: Schaden und zurück an die letzte sichere Stelle vor dem Loch.

signal fell_through(target_room: String, target_entry: StringName)

## Größe in Pixeln (Vielfache von 16 empfohlen).
@export var size: Vector2 = Vector2(16, 16):
	set(value):
		size = value
		_update_shape()
		queue_redraw()
@export_file("*.tscn") var target_room: String = ""
@export var target_entry: StringName = &""
## Schaden ohne Zielraum, in LP (10 = ½ Herz).
@export var fall_damage: int = 10
## So weit müssen die Füße im Loch sein (Pixel vom Rand), damit man fällt.
@export var edge_margin: float = 3.0
## So weit (Pixel) wird man nach dem Sturz zusätzlich vom Loch weg abgesetzt.
@export var respawn_push: float = 6.0

var _player: Player = null


func _ready() -> void:
	_update_shape()
	if Engine.is_editor_hint():
		return
	collision_layer = 32
	collision_mask = 2
	monitorable = false
	body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			_player = body
			_player.hazard_entered())
	body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_player.hazard_exited()
			_player = null)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _player == null or not _player.can_fall():
		return
	var feet := to_local(_player.feet_position())
	var inner := Rect2(-size / 2.0, size).grow(-edge_margin)
	if inner.has_point(feet):
		_fall(_player)


func _fall(player: Player) -> void:
	await player.fall()
	if not player.is_falling():
		return  # Inzwischen anderweitig abgesetzt (z. B. Tod während des Sturzes).
	if target_room != "":
		fell_through.emit(target_room, target_entry)
	else:
		# Etwas weiter weg vom Loch absetzen, damit man nicht sofort wieder hineinläuft.
		var away := (player.last_safe_position - global_position).normalized()
		player.recover_from_fall(player.last_safe_position + away * respawn_push)
		player.take_damage(fall_damage)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, Color(0.02, 0.02, 0.04))
	draw_rect(Rect2(rect.position, Vector2(size.x, 2)), Color(0.12, 0.12, 0.16))


func _update_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		shape_node.shape = rect
	rect.size = size
