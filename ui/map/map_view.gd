class_name MapView
extends Control
## Zeichnet ein Stockwerk einer DungeonMap: Räume als Kästchen (besucht hell, sonst dunkel),
## Durchgänge, Treppen, mit Kompass die Markierungen, dazu den Helden.
## Genutzt von der Vollbild-Karte und der Mini-Karte (andere Zellgröße, kleine Symbole).

const COLOR_VISITED := Color(0.55, 0.62, 0.78)
const COLOR_UNVISITED := Color(0.22, 0.25, 0.36)
const COLOR_BORDER := Color(0.08, 0.08, 0.12)
const COLOR_CURRENT := Color(0.95, 0.95, 1.0)
const COLOR_DOOR := Color(0.85, 0.88, 0.95)
const COLOR_PLAYER := Color(0.3, 0.95, 0.4)
const MARKER_COLORS := {
	DungeonMap.Marker.CHEST: Color(1.0, 0.82, 0.2),
	DungeonMap.Marker.KEY_DOOR: Color(0.92, 0.92, 0.92),
	DungeonMap.Marker.BOSS_DOOR: Color(1.0, 0.5, 0.15),
	DungeonMap.Marker.SAVE: Color(0.35, 0.65, 1.0),
	DungeonMap.Marker.BOSS: Color(0.95, 0.2, 0.2),
	DungeonMap.Marker.STAIRS: Color(0.1, 0.1, 0.14),
}
## Pixel-Symbole (# = Farbe, o = dunkler Rand) für die große Karte.
const GLYPHS := {
	DungeonMap.Marker.CHEST: ["oooo", "o##o", "oooo"],
	DungeonMap.Marker.KEY_DOOR: ["##...", "#####", "##.#."],
	DungeonMap.Marker.BOSS_DOOR: ["##...", "#####", "##.#."],
	DungeonMap.Marker.SAVE: [".#.", "###", "###"],
	DungeonMap.Marker.BOSS: [".###.", "#o#o#", "#####", ".#.#."],
	DungeonMap.Marker.STAIRS: ["###", "...", "###"],
}

var map: DungeonMap = null
var floor_index: int = 0
## Zellgröße in Pixeln (ein Bildschirm = eine Zelle).
var cell_size: Vector2 = Vector2(24, 21)
## Kartenzelle, die links oben in diesem Control liegt.
var origin: Vector2 = Vector2.ZERO
var show_compass: bool = false
## Kleine Darstellung: Symbole als einzelne Punkte.
var compact: bool = false
var current_room: String = ""
## Position des Helden relativ zum aktuellen Raum (Pixel).
var player_pos: Vector2 = Vector2.ZERO
## Aktueller Raum hervorgehoben (blinkt in der großen Karte).
var highlight: bool = true


func _draw() -> void:
	if map == null:
		return
	var rooms := map.rooms_on(floor_index)
	for data in rooms:
		var rect := _room_rect(data)
		var visited := GameState.is_visited(data.path)
		var fill := COLOR_VISITED if visited else COLOR_UNVISITED
		if data.path == current_room and highlight:
			fill = COLOR_CURRENT
		draw_rect(rect, COLOR_BORDER)
		draw_rect(rect.grow(-1), fill)
	for data in rooms:
		_draw_inner_walls(data)
		_draw_doors(data)
	for data in rooms:
		for marker in data.markers:
			if marker.kind == DungeonMap.Marker.STAIRS or (show_compass and DungeonMap.marker_active(marker)):
				_draw_marker(marker.kind, _to_view(data, marker.pos))
	var current := map.room(current_room)
	if not current.is_empty() and current.floor == floor_index:
		var p := _to_view(current, player_pos).round()
		if not compact:
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), COLOR_BORDER)
		draw_rect(Rect2(p - Vector2.ONE, Vector2(2, 2)), COLOR_PLAYER)


func _room_rect(data: Dictionary) -> Rect2:
	var top_left := (Vector2(data.cell) - origin) * cell_size
	return Rect2(top_left.round(), (Vector2(data.size) * cell_size).round())


func _to_view(data: Dictionary, local_pos: Vector2) -> Vector2:
	return _room_rect(data).position + local_pos / DungeonMap.SCREEN * cell_size


## Innenwände großer Räume als dunkle Linie; Lücken bleiben offen (Durchgänge).
func _draw_inner_walls(data: Dictionary) -> void:
	var thickness := 1.0 if compact else 2.0
	for segment in data.walls:
		var a := _to_view(data, segment[0]).round()
		var b := _to_view(data, segment[1]).round()
		if is_equal_approx(a.x, b.x):
			draw_rect(Rect2(a.x - thickness / 2.0, a.y, thickness, b.y - a.y), COLOR_BORDER)
		else:
			draw_rect(Rect2(a.x, a.y - thickness / 2.0, b.x - a.x, thickness), COLOR_BORDER)


## Durchgänge an Wänden: eine helle Lücke im Rand.
func _draw_doors(data: Dictionary) -> void:
	var rect := _room_rect(data)
	var half := 1.0 if compact else 2.0
	for exit in data.exits:
		var side: Vector2i = exit.side
		if side == Vector2i.ZERO:
			continue
		var target := map.room(exit.target)
		if not target.is_empty() and target.floor != data.floor:
			continue
		var p := _to_view(data, exit.pos).round()
		match side:
			Vector2i.LEFT:
				draw_rect(Rect2(rect.position.x - 1, p.y - half, 3, half * 2), COLOR_DOOR)
			Vector2i.RIGHT:
				draw_rect(Rect2(rect.end.x - 2, p.y - half, 3, half * 2), COLOR_DOOR)
			Vector2i.UP:
				draw_rect(Rect2(p.x - half, rect.position.y - 1, half * 2, 3), COLOR_DOOR)
			Vector2i.DOWN:
				draw_rect(Rect2(p.x - half, rect.end.y - 2, half * 2, 3), COLOR_DOOR)


func _draw_marker(kind: int, at: Vector2) -> void:
	var color: Color = MARKER_COLORS[kind]
	if compact:
		draw_rect(Rect2(at.round() - Vector2.ONE, Vector2(2, 2)), color)
		return
	var rows: Array = GLYPHS[kind]
	var size := Vector2(rows[0].length(), rows.size())
	var top_left := (at - size / 2.0).round()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var c := row[x]
			if c == "#":
				draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), color)
			elif c == "o":
				draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), COLOR_BORDER)
