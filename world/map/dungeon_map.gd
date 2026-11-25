class_name DungeonMap
extends RefCounted
## Kartendaten eines Dungeons, automatisch aus den Raumszenen gelesen.
## Ein Dungeon = alle Raumszenen in einem Ordner (z. B. world/dungeon_1/). Von Hand pro Raum
## nur Room.map_position und Room.map_floor; Größe, Durchgänge, Treppen, Truhen, Türen,
## Statuen und Boss liest die Karte selbst. Ändert sich ein Raum, stimmt die Karte beim nächsten Start.

const SCREEN := Vector2(256, 224)
## So nah (Pixel) muss ein Ausgang am Raumrand liegen, um als Durchgang an dieser Wand zu gelten.
const EDGE_MARGIN := 16.0

enum Marker { CHEST, KEY_DOOR, BOSS_DOOR, SAVE, BOSS, STAIRS }

static var _cache: Dictionary[String, DungeonMap] = {}

var folder: String = ""
var dungeon_id: StringName = &""
## Je Raum: {path, dungeon, cell: Vector2i, floor: int, size: Vector2i, entries: Array[StringName],
## exits: Array[{pos, side: Vector2i, target, entry}], markers: Array[{kind, pos, id}]}
## pos ist relativ zur linken oberen Ecke des Raums (Kameragrenze).
var rooms: Array[Dictionary] = []


## Karte des Dungeons, zu dem eine Raumszene gehört (zwischengespeichert pro Ordner).
static func for_room(room_path: String) -> DungeonMap:
	var dir := room_path.get_base_dir()
	if not _cache.has(dir):
		_cache[dir] = DungeonMap.new(dir)
	return _cache[dir]


static func clear_cache() -> void:
	_cache.clear()


## Ist eine Kompass-Markierung noch aktuell? (Truhe zu, Tür verschlossen, Boss lebt.)
static func marker_active(marker: Dictionary) -> bool:
	match marker.kind:
		Marker.CHEST:
			return not GameState.get_value(marker.id, false)
		Marker.KEY_DOOR, Marker.BOSS_DOOR, Marker.BOSS:
			return not GameState.has_flag(marker.id)
	return true


func _init(dir: String) -> void:
	folder = dir
	for file in DirAccess.get_files_at(dir):
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tscn"):
			continue
		var data := _read_room(dir.path_join(file))
		if not data.is_empty():
			rooms.append(data)
			if dungeon_id == &"":
				dungeon_id = data.dungeon


func room(path: String) -> Dictionary:
	for data in rooms:
		if data.path == path:
			return data
	return {}


func floors() -> Array[int]:
	var result: Array[int] = []
	for data in rooms:
		if not result.has(data.floor):
			result.append(data.floor)
	result.sort()
	return result


func rooms_on(floor_: int) -> Array[Dictionary]:
	return rooms.filter(func(d: Dictionary) -> bool: return d.floor == floor_)


## Umriss aller Räume (aller Stockwerke) in Bildschirmen.
func bounds() -> Rect2i:
	var rect := Rect2i()
	var first := true
	for data in rooms:
		var r := Rect2i(data.cell, data.size)
		rect = r if first else rect.merge(r)
		first = false
	return rect


## Bildschirm-Zelle (Kartenkoordinate) eines Punkts im Raum.
func cell_at(room_path: String, local_pos: Vector2) -> Vector2i:
	var data := room(room_path)
	if data.is_empty():
		return Vector2i.ZERO
	var inside := Vector2i((local_pos / SCREEN).floor())
	inside = inside.clamp(Vector2i.ZERO, data.size - Vector2i.ONE)
	return data.cell + inside


static func floor_name(floor_: int) -> String:
	return "%dF" % (floor_ + 1) if floor_ >= 0 else "B%d" % -floor_


func _read_room(path: String) -> Dictionary:
	var scene := load(path) as PackedScene
	if scene == null:
		return {}
	var root := scene.instantiate()
	if not root is Room:
		root.free()
		return {}
	var room_node := root as Room
	var top_left := Vector2.ZERO
	var size := Vector2i.ONE
	if room_node.camera_top_left and room_node.camera_bottom_right:
		top_left = _local_pos(room_node.camera_top_left, root)
		var extent := _local_pos(room_node.camera_bottom_right, root) - top_left
		size = Vector2i((extent / SCREEN).round()).max(Vector2i.ONE)
	var data := {
		"path": path,
		"dungeon": room_node.dungeon_id,
		"cell": room_node.map_position,
		"floor": room_node.map_floor,
		"size": size,
		"entries": [],
		"exits": [],
		"markers": [],
	}
	var pixel_size := Vector2(size) * SCREEN
	for node in root.find_children("*", "", true, false):
		var pos := _local_pos(node, root) - top_left if node is Node2D else Vector2.ZERO
		if node is RoomEntry:
			data.entries.append(StringName(node.name))
		elif node is RoomExit:
			var exit := node as RoomExit
			var side := _side(pos, pixel_size)
			if node is Stairs:
				side = Vector2i.ZERO
				data.markers.append({"kind": Marker.STAIRS, "pos": pos, "id": ""})
			data.exits.append({"pos": pos, "side": side, "target": exit.target_room, "entry": exit.target_entry})
		elif node is Pit and (node as Pit).target_room != "":
			data.exits.append({"pos": pos, "side": Vector2i.ZERO, "target": (node as Pit).target_room, "entry": (node as Pit).target_entry})
		elif node is Chest:
			data.markers.append({"kind": Marker.CHEST, "pos": pos, "id": GameState.flag_id(node)})
		elif node is LockedDoor:
			var kind := Marker.BOSS_DOOR if (node as LockedDoor).big_key else Marker.KEY_DOOR
			data.markers.append({"kind": kind, "pos": pos, "id": GameState.flag_id(node)})
		elif node is SaveStatue:
			data.markers.append({"kind": Marker.SAVE, "pos": pos, "id": ""})
		elif node is Enemy and node.has_signal(&"boss_appeared"):
			data.markers.append({"kind": Marker.BOSS, "pos": pos, "id": GameState.flag_id(node)})
	root.free()
	return data


## Wand, an der ein Ausgang liegt (oder ZERO, wenn er mitten im Raum ist).
static func _side(pos: Vector2, pixel_size: Vector2) -> Vector2i:
	if pos.x < EDGE_MARGIN:
		return Vector2i.LEFT
	if pos.x > pixel_size.x - EDGE_MARGIN:
		return Vector2i.RIGHT
	if pos.y < EDGE_MARGIN:
		return Vector2i.UP
	if pos.y > pixel_size.y - EDGE_MARGIN:
		return Vector2i.DOWN
	return Vector2i.ZERO


## Position relativ zur Raumwurzel (ohne SceneTree, Knoten sind nur instanziiert).
static func _local_pos(node: Node, root: Node) -> Vector2:
	var xform := Transform2D.IDENTITY
	var current := node
	while current != null and current != root:
		if current is Node2D:
			xform = (current as Node2D).transform * xform
		current = current.get_parent()
	return xform.origin
