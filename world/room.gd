class_name Room
extends Node2D
## Wurzel jeder Raumszene. Wird von Game geladen und wieder entfernt.
## - Ausgänge (RoomExit) melden sich über exit_requested nach oben.
## - Speicherstatuen melden sich über save_requested nach oben.
## - Eingänge (RoomEntry) sind Marker; ihr Knotenname ist die Eingangs-ID.
## - Knoten mit `min_tier` über Difficulty.tier() werden beim Laden entfernt (Raumvarianten).

signal exit_requested(target_room: String, target_entry: StringName)
signal save_requested(statue: SaveStatue)

@export var dungeon_id: StringName = &""
@export var camera_top_left: Marker2D
@export var camera_bottom_right: Marker2D

var _tier_applied: bool = false


func _ready() -> void:
	if not _tier_applied:
		apply_tier(Difficulty.tier())
	for node in _all_children(self):
		if node is RoomExit:
			(node as RoomExit).triggered.connect(exit_requested.emit)
		elif node is SaveStatue:
			(node as SaveStatue).save_requested.connect(save_requested.emit)


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
