class_name MapScreen
extends Control
## Vollbild-Karte. Die Aktion "map" öffnet und schließt sie (Spiel pausiert), "menu" schließt auch.
## Nur mit der Karte des aktuellen Dungeons. Hoch/runter wechselt das Stockwerk.

## Mögliche Zellgrößen (ein Bildschirm), die größte passende wird genommen.
const CELL_SIZES: Array[Vector2] = [Vector2(32, 28), Vector2(24, 21), Vector2(16, 14), Vector2(8, 7)]
## Platz links für die Stockwerksliste.
const FLOOR_COLUMN := 32.0

## Blinktakt des aktuellen Raums (Sekunden).
@export var blink_time: float = 0.3

var room_path: String = ""
var player_pos: Vector2 = Vector2.ZERO

var _floors: Array[int] = []
var _blink: float = 0.0

@onready var _view: MapView = %MapView
@onready var _floor_list: Label = %FloorList


func _ready() -> void:
	visible = false


func can_open() -> bool:
	return room_path != "" and GameState.current_dungeon != &"" and GameState.has_map()


func is_open() -> bool:
	return visible


func open() -> void:
	var map := DungeonMap.for_room(room_path)
	_view.map = map
	_view.current_room = room_path
	_view.player_pos = player_pos
	_view.show_compass = GameState.has_compass()
	_view.highlight = true
	_floors = map.floors()
	var current := map.room(room_path)
	_view.floor_index = current.floor if not current.is_empty() else (_floors[0] if _floors.size() > 0 else 0)
	_layout(map)
	_update_floor_list()
	_blink = 0.0
	visible = true
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false


## Stockwerk wechseln (+1 = höher). Bleibt innerhalb der vorhandenen Stockwerke.
func change_floor(step: int) -> void:
	var index := _floors.find(_view.floor_index) + step
	if index < 0 or index >= _floors.size():
		return
	_view.floor_index = _floors[index]
	_update_floor_list()
	_view.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if visible:
			close()
		elif not get_tree().paused and can_open():
			open()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("menu"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up"):
		change_floor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		change_floor(-1)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	if _blink >= blink_time:
		_blink = 0.0
		_view.highlight = not _view.highlight
		_view.queue_redraw()


func _layout(map: DungeonMap) -> void:
	var bounds := map.bounds()
	var area := size - Vector2(FLOOR_COLUMN + 8.0, 16.0)
	var cell := CELL_SIZES[-1]
	for candidate in CELL_SIZES:
		var needed := Vector2(bounds.size) * candidate
		if needed.x <= area.x and needed.y <= area.y:
			cell = candidate
			break
	_view.cell_size = cell
	_view.origin = Vector2(bounds.position)
	_view.size = Vector2(bounds.size) * cell
	_view.position = (Vector2(FLOOR_COLUMN, 8.0) + (area - _view.size) / 2.0).round()
	_view.queue_redraw()


func _update_floor_list() -> void:
	var lines: PackedStringArray = []
	for i in range(_floors.size() - 1, -1, -1):
		var f := _floors[i]
		lines.append(("> " if f == _view.floor_index else "  ") + DungeonMap.floor_name(f))
	_floor_list.text = "\n".join(lines)
