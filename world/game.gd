class_name Game
extends Node2D
## Hauptszene. Spieler, Kamera und HUD bleiben bestehen; nur der Raum in RoomHolder wird getauscht.

@export_file("*.tscn") var start_room: String = "res://world/test_area/test_area.tscn"
@export var start_entry: StringName = &"start"
## Dauer von Ab- bzw. Aufblenden in Sekunden.
@export var fade_time: float = 0.2

var current_room: Room = null
var _changing_room: bool = false

@onready var _room_holder: Node2D = $RoomHolder
@onready var _player: Player = $Player
@onready var _camera: RoomCamera = $RoomCamera
@onready var _fade: ColorRect = $Fade/ColorRect
@onready var _hud: HUD = $HUD


func _ready() -> void:
	_hud.show_health(_player.health, _player.max_health)
	_load_room(start_room, start_entry)


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


func _load_room(room_path: String, entry: StringName) -> void:
	if current_room:
		_room_holder.remove_child(current_room)
		current_room.queue_free()
	var room: Room = (load(room_path) as PackedScene).instantiate()
	room.apply_tier(Difficulty.tier())
	_room_holder.add_child(room)
	room.exit_requested.connect(change_room)
	current_room = room
	GameState.current_dungeon = room.dungeon_id

	var room_entry := room.get_entry(entry)
	if room_entry:
		_player.global_position = room_entry.global_position
		_player.face(room_entry.facing)
	_camera.set_bounds(room.camera_bounds())
	_camera.global_position = _player.global_position
	_camera.reset_smoothing()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished
