extends TestCase
## Karte und Kompass: Truhen im Startraum, Taste "map", Stockwerke, besuchte Räume, Kompass-Markierungen, Mini-Karte.

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var hud: HUD = game.get_node("HUD")
	var screen: MapScreen = hud.map_screen
	var mini: MiniMap = hud.get_node("%MiniMap")

	# Ohne Karte: Taste tut nichts, keine Mini-Karte
	await tap("map")
	await frames(2)
	check(not screen.is_open() and not get_tree().paused, "Ohne Karte keine Karte")
	check(not mini.visible, "Ohne Karte keine Mini-Karte")
	check(GameState.is_visited(AREA), "Startraum gilt als besucht")

	# Karte aus der Truhe
	var map_chest: Chest = game.current_room.get_node("MapChest")
	player.global_position = map_chest.global_position + Vector2(0, 14)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)
	check(GameState.has_map(), "Karte bekommen")
	check_eq(hud.get_node("%MessageLabel").text, "You found the Dungeon Map!", "Karten-Meldung")
	await _wait_unpaused()
	await frames(2)
	check(mini.visible, "Mini-Karte sichtbar")

	# Karte öffnen und schließen
	await tap("map")
	await frames(2)
	check(screen.is_open() and get_tree().paused, "Karte offen, Spiel pausiert")
	var view: MapView = screen.get_node("%MapView")
	check_eq(view.floor_index, 0, "Stockwerk des aktuellen Raums")
	check(not view.show_compass, "Ohne Kompass keine Markierungen")
	await tap("move_down")
	check_eq(view.floor_index, -1, "Runter: Keller")
	await tap("move_down")
	check_eq(view.floor_index, -1, "Tiefer geht es nicht")
	await tap("move_up")
	check_eq(view.floor_index, 0, "Wieder hoch")
	check(view.size.x <= screen.size.x and view.size.y <= screen.size.y, "Karte passt auf den Bildschirm")
	await tap("map")
	await frames(2)
	check(not screen.is_open() and not get_tree().paused, "Karte zu")

	# Kompass aus der zweiten Truhe
	var compass_chest: Chest = game.current_room.get_node("CompassChest")
	player.global_position = compass_chest.global_position + Vector2(0, 14)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)
	check(GameState.has_compass(), "Kompass bekommen")
	await _wait_unpaused()

	# Kompass-Markierungen: geöffnete Truhen verschwinden, die anderen bleiben aktiv
	var map := DungeonMap.for_room(AREA)
	var area := map.room(AREA)
	var chest_markers := (area.markers as Array).filter(func(m: Dictionary) -> bool: return m.kind == DungeonMap.Marker.CHEST)
	check_eq(chest_markers.size(), 3, "Drei Truhen im Startraum")
	var active := chest_markers.filter(func(m: Dictionary) -> bool: return DungeonMap.marker_active(m))
	check_eq(active.size(), 1, "Nur die ungeöffnete Truhe bleibt markiert")
	var room2 := map.room(ROOM2)
	var doors := (room2.markers as Array).filter(func(m: Dictionary) -> bool: return m.kind == DungeonMap.Marker.KEY_DOOR)
	check_eq(doors.size(), 1, "Schlüsseltür in Raum 2")
	check(DungeonMap.marker_active(doors[0]), "Verschlossene Tür ist markiert")

	# Besuchte Räume
	check(not GameState.is_visited(ROOM2), "Raum 2 noch nicht besucht")
	await game.change_room(ROOM2, &"from_test_area")
	check(GameState.is_visited(ROOM2), "Raum 2 besucht")
	var door: LockedDoor = game.current_room.get_node("LockedDoor")
	GameState.mark_gone(door)
	check(not DungeonMap.marker_active(doors[0]), "Geöffnete Tür nicht mehr markiert")

	# Mini-Karte folgt dem Helden
	await frames(2)
	var mini_view: MapView = mini.get_node("%MiniMapView")
	check_eq(mini_view.current_room, ROOM2, "Mini-Karte kennt den Raum")
	check_eq(mini_view.origin, Vector2(-2, 1), "Mini-Karte zentriert auf Raum 2 (Zelle 0,2)")
	check(mini_view.show_compass, "Mini-Karte mit Kompass")

	# Karte im Keller: Stockwerk B1
	await game.change_room("res://world/test_area/test_cellar.tscn", &"from_stairs")
	await tap("map")
	await frames(2)
	check_eq(view.floor_index, -1, "Im Keller zeigt die Karte B1")
	await tap("menu")
	await frames(2)
	check(not screen.is_open(), "Menü-Taste schließt die Karte")
	check(not (hud.get_node("InventoryUI") as Control).visible, "…ohne das Inventar zu öffnen")


func _wait_unpaused() -> void:
	for i in 200:
		await frames(1)
		if not get_tree().paused:
			return
