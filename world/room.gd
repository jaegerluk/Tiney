class_name Room
extends Node2D
## Wurzel jeder Raumszene. Wird von Game geladen und wieder entfernt.
## - Ausgänge (RoomExit) melden sich über exit_requested nach oben.
## - Speicherstatuen melden sich über save_requested nach oben.
## - Eingänge (RoomEntry) sind Marker; ihr Knotenname ist die Eingangs-ID.
## - Knoten mit `min_tier` über Difficulty.tier() werden beim Laden entfernt (Raumvarianten).

signal exit_requested(target_room: String, target_entry: StringName)
signal save_requested(statue: SaveStatue)
signal item_presented(icon: Texture2D, message: String)
signal dialog_requested(pages: Array, speaker: String, portrait: Texture2D)
signal boss_appeared(boss: Enemy)

@export var dungeon_id: StringName = &""
## Kamera schiebt bildschirmweise (ALttP). Aus = Kamera folgt dem Spieler frei.
@export var screen_scroll: bool = true
@export var camera_top_left: Marker2D
@export var camera_bottom_right: Marker2D

var _tier_applied: bool = false


func _ready() -> void:
	if not _tier_applied:
		apply_tier(Difficulty.tier())
	for node in _all_children(self):
		_connect_node(node)
	# Zur Laufzeit hinzugefügte Objekte (Drops, Boss-Belohnungen, gerufene Gegner) ebenfalls verbinden.
	child_entered_tree.connect(_connect_node)


## Reicht die Signale eines Objekts an Game weiter (Ausgänge, Statuen, Meldungen, Dialoge, Bosse).
func _connect_node(node: Node) -> void:
	if node is Enemy and screen_scroll:
		(node as Enemy).confine_rect = screen_rect_at((node as Enemy).global_position)
	if node is RoomExit:
		(node as RoomExit).triggered.connect(exit_requested.emit)
	elif node is Pit:
		(node as Pit).fell_through.connect(exit_requested.emit)
	elif node is SaveStatue:
		(node as SaveStatue).save_requested.connect(save_requested.emit)
	for signal_name: StringName in [&"item_presented", &"dialog_requested", &"boss_appeared"]:
		if node.has_signal(signal_name):
			var target := _forwarder(signal_name)
			if not node.is_connected(signal_name, target):
				node.connect(signal_name, target)


func _forwarder(signal_name: StringName) -> Callable:
	match signal_name:
		&"item_presented":
			return item_presented.emit
		&"dialog_requested":
			return dialog_requested.emit
		_:
			return boss_appeared.emit


## Entfernt alle Knoten, deren `min_tier` höher als die Stufe ist. Vor add_child aufrufen.
func apply_tier(tier: int) -> void:
	_tier_applied = true
	for node in _all_children(self):
		if "min_tier" in node and int(node.get("min_tier")) > tier:
			node.get_parent().remove_child(node)
			node.queue_free()


func get_entry(entry_name: StringName) -> RoomEntry:
	for node in _all_children(self):
		if node is RoomEntry and node.name == entry_name:
			return node
	push_error("Raum %s: Eingang '%s' fehlt" % [scene_file_path, entry_name])
	return null


## Der Bildschirm (Viewport-Größe, im Raster der Raumgrenzen), in dem ein Punkt liegt.
func screen_rect_at(point: Vector2) -> Rect2:
	var bounds := camera_bounds()
	var size := get_viewport_rect().size
	var index := ((point - bounds.position) / size).floor()
	return Rect2(bounds.position + index * size, size)


func camera_bounds() -> Rect2:
	if camera_top_left == null or camera_bottom_right == null:
		return Rect2(-100000, -100000, 200000, 200000)
	var top_left := camera_top_left.global_position
	return Rect2(top_left, camera_bottom_right.global_position - top_left)


func _all_children(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_children(child))
	return result
