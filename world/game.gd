class_name Game
extends Node2D
## Hauptszene. Spieler, Kamera und HUD bleiben bestehen; nur der Raum in RoomHolder wird getauscht.
## Verwaltet außerdem den Spielstand der letzten Speicherstatue: Beim Tod wird alles darauf zurückgesetzt.

@export_file("*.tscn") var start_room: String = "res://world/test_area/test_area.tscn"
@export var start_entry: StringName = &"start"
## Dauer von Ab- bzw. Aufblenden in Sekunden.
@export var fade_time: float = 0.2
## So weit rückt der Spieler beim Bildschirmwechsel in den neuen Bildschirm (Pixel).
@export var scroll_nudge: float = 14.0

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
	add_to_group(Effects.GAME_FEEL_GROUP)
	_hud.show_health(_player.health, _player.max_health)
	_player.died.connect(_on_player_died)
	_camera.scroll_started.connect(_on_scroll_started)
	_camera.scroll_finished.connect(_on_scroll_finished)
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
		"max_health": _player.max_health,
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
	_hud.hide_boss()
	_hud.hide_info()
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
	room.dialog_requested.connect(show_dialog)
	room.boss_appeared.connect(_hud.show_boss)
	room.info_shown.connect(_hud.show_info)
	room.info_hidden.connect(_hud.hide_info)
	current_room = room
	GameState.current_dungeon = room.dungeon_id
	_camera.set_bounds(room.camera_bounds())
	_camera.screen_scroll = room.screen_scroll


func _place_player(position_: Vector2, facing: Vector2) -> void:
	_player.land_at(position_, false)
	_player.face(facing)
	_camera.snap_to_target()


## Truheninhalt zeigen: Held hält ihn hoch, Meldung im HUD, Spiel kurz pausiert.
func present_item(icon: Texture2D, message: String) -> void:
	get_tree().paused = true
	_hud.hide_info()
	_player.hold_up(icon)
	if message != "":
		_hud.show_message(message)
	await get_tree().create_timer(1.6 if message != "" else 0.7, true, false, true).timeout
	_hud.hide_message()
	_player.hold_up(null)
	get_tree().paused = false


## Dialog in der Textbox; das Spiel pausiert, bis der Spieler die letzte Seite wegklickt.
func show_dialog(pages: Array, speaker: String = "", portrait: Texture2D = null) -> void:
	get_tree().paused = true
	await _hud.dialog_box.run(pages, speaker, portrait)
	get_tree().paused = false


## Bildschirmwechsel: alles friert ein, der Spieler rückt ein Stück in den neuen Bildschirm.
func _on_scroll_started(direction: Vector2) -> void:
	get_tree().paused = true
	_player.global_position += direction * scroll_nudge


func _on_scroll_finished() -> void:
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
	_player.max_health = _save.max_health
	_player.revive()
	_swap_room(_save.room, false)
	_place_player(_save.position, _save.facing)
	await _fade_to(0.0)
	_player.set_controls_enabled(true)
	_changing_room = false


## Trefferstopp: Spielzeit kurz anhalten (Engine.time_scale), danach weiter.
func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func shake(strength: float, duration: float) -> void:
	_camera.shake(strength, duration)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Debug: lädt den aktuellen Raum neu, der Spieler bleibt, wo er ist.
func reload_room(forget_state: bool = false) -> void:
	if current_room == null:
		return
	var path := current_room.scene_file_path
	var position_ := _player.global_position
	var facing := _player.facing
	if forget_state:
		GameState.clear_room(path)
	_swap_room(path, not forget_state)
	_place_player(position_, facing)
	_player.set_controls_enabled(true)


## Debug: springt ohne Überblendung in einen Raum (Eingang leer = erster Eingang).
func teleport(room_path: String, entry: StringName = &"") -> void:
	_swap_room(room_path, true)
	var target: RoomEntry = current_room.get_entry(entry) if entry != &"" else _first_entry(current_room)
	if target:
		_place_player(target.global_position, target.facing)
	_player.set_controls_enabled(true)


func _first_entry(room: Room) -> RoomEntry:
	var entries := room.get_node_or_null("Entries")
	if entries:
		for child in entries.get_children():
			if child is RoomEntry:
				return child
	return null


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
