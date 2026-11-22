class_name Game
extends Node2D
## Hauptszene. Spieler, Kamera und HUD bleiben bestehen; nur der Raum in RoomHolder wird getauscht.
## Verwaltet außerdem den Spielstand der letzten Speicherstatue: Beim Tod wird alles darauf zurückgesetzt.

@export_file("*.tscn") var start_room: String = "res://world/test_area/test_area.tscn"
@export var start_entry: StringName = &"start"
## Dauer von Ab- bzw. Aufblenden in Sekunden.
@export var fade_time: float = 0.2

var current_room: Room = null
var _changing_room: bool = false
## Letzter Spielstand: {state, inventory, room, position, facing}. Nur im Speicher.
var _save: Dictionary = {}

@onready var _room_holder: Node2D = $RoomHolder
@onready var _player: Player = $Player
@onready var _camera: RoomCamera = $RoomCamera
@onready var _fade: ColorRect = $Fade/ColorRect
@onready var _hud: HUD = $HUD


func _ready() -> void:
	_hud.show_health(_player.health, _player.max_health)
	_player.died.connect(_on_player_died)
	_load_room(start_room, start_entry)
	save_game(_player.global_position, _player.facing)


## Wechselt mit Überblendung in einen anderen Raum.
func change_room(room_path: String, entry: StringName) -> void:
	if _changing_room:
		return
	_changing_room = true
	_player.set_controls_enabled(false)
	await _fade_to(1.0)
	_load_room(room_path, entry)
	await _fade_to(0.0)
	_player.set_controls_enabled(true)
	_changing_room = false


## Merkt sich den aktuellen Stand. Nach dem Tod geht es hierher zurück (mit vollem Leben).
func save_game(respawn_position: Vector2, facing: Vector2) -> void:
	GameState.store_drops(current_room.scene_file_path, _collect_drops(current_room))
	_save = {
		"state": GameState.snapshot(),
		"inventory": _player.inventory.snapshot() if _player.inventory else [],
		"room": current_room.scene_file_path,
		"position": respawn_position,
		"facing": facing,
	}


func _load_room(room_path: String, entry: StringName) -> void:
	_swap_room(room_path, true)
	var room_entry := current_room.get_entry(entry)
	if room_entry:
		_place_player(room_entry.global_position, room_entry.facing)


## Tauscht den Raum. Mit keep_drops werden die liegen gelassenen Drops des alten Raums gesichert.
func _swap_room(room_path: String, keep_drops: bool) -> void:
	if current_room:
		if keep_drops:
			GameState.store_drops(current_room.scene_file_path, _collect_drops(current_room))
		_room_holder.remove_child(current_room)
		current_room.queue_free()
	var room: Room = (load(room_path) as PackedScene).instantiate()
	room.apply_tier(Difficulty.tier())
	_room_holder.add_child(room)
	for drop in GameState.get_drops(room_path):
		DropTable.spawn_scene(load(drop.scene), room, drop.position)
	room.exit_requested.connect(change_room)
	room.save_requested.connect(_on_save_requested)
	room.item_presented.connect(present_item)
	current_room = room
	GameState.current_dungeon = room.dungeon_id
	_camera.set_bounds(room.camera_bounds())


func _place_player(position_: Vector2, facing: Vector2) -> void:
	_player.global_position = position_
	_player.face(facing)
	_camera.global_position = position_
	_camera.reset_smoothing()


## Truheninhalt zeigen: Held hält ihn hoch, Meldung im HUD, Spiel kurz pausiert.
func present_item(icon: Texture2D, message: String) -> void:
	get_tree().paused = true
	_player.hold_up(icon)
	if message != "":
		_hud.show_message(message)
	await get_tree().create_timer(1.6 if message != "" else 0.7, true, false, true).timeout
	_hud.hide_message()
	_player.hold_up(null)
	get_tree().paused = false


func _on_save_requested(statue: SaveStatue) -> void:
	save_game(statue.respawn_position(), Vector2.UP)


## Tod: alles auf den letzten Spielstand, volles Leben, an die Statue.
func _on_player_died() -> void:
	while _changing_room:
		await get_tree().process_frame
	_changing_room = true
	_player.set_controls_enabled(false)
	await _fade_to(1.0)
	GameState.restore(_save.state)
	if _player.inventory:
		_player.inventory.restore(_save.inventory)
	_player.revive()
	_swap_room(_save.room, false)
	_place_player(_save.position, _save.facing)
	await _fade_to(0.0)
	_player.set_controls_enabled(true)
	_changing_room = false


## Liegen gelassene Drops eines Raums als speicherbare Liste.
func _collect_drops(room: Room) -> Array:
	var drops: Array = []
	for node in get_tree().get_nodes_in_group(DropTable.DROP_GROUP):
		if room.is_ancestor_of(node) and not node.is_queued_for_deletion():
			drops.append({"scene": node.scene_file_path, "position": (node as Node2D).position})
	return drops


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished
