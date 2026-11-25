class_name MiniMap
extends Control
## Kleine Karte im HUD (unten rechts): aktueller Bildschirm und Umgebung.
## Nur sichtbar mit der Karte des aktuellen Dungeons; mit Kompass auch die Markierungen.

## Angezeigte Bildschirme (Breite × Höhe), der aktuelle in der Mitte.
const CELLS := Vector2i(5, 3)

var room_path: String = ""
var player_pos: Vector2 = Vector2.ZERO

@onready var _view: MapView = %MiniMapView


func has_map() -> bool:
	return room_path != "" and GameState.current_dungeon != &"" and GameState.has_map()


func refresh() -> void:
	var map := DungeonMap.for_room(room_path)
	var current := map.room(room_path)
	if current.is_empty():
		return
	_view.map = map
	_view.compact = true
	_view.highlight = false
	_view.cell_size = _view.size / Vector2(CELLS)
	_view.current_room = room_path
	_view.player_pos = player_pos
	_view.floor_index = current.floor
	_view.show_compass = GameState.has_compass()
	var center := map.cell_at(room_path, player_pos)
	_view.origin = Vector2(center - CELLS / 2)
	_view.queue_redraw()
