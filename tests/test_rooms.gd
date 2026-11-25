extends TestCase
## Raumwechsel: Game lädt den Startraum, Ausgänge wechseln hin und zurück.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var camera: RoomCamera = game.get_node("RoomCamera")
	check_eq(game.current_room.name, &"TestArea", "Startraum geladen")
	check_eq(player.global_position, Vector2(64, 96), "Spieler am Eingang 'start'")
	check_eq(GameState.current_dungeon, &"test", "Dungeon aus dem Raum übernommen")
	check_eq([camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom], [0, 0, 512, 448], "Kamera-Grenzen Raum 1")

	# Zum Ausgang unten links laufen
	player.global_position = Vector2(112, 410)
	hold("move_down")
	await frames(30)
	hold("move_down", false)
	check(not player._controls_enabled, "Steuerung während des Wechsels gesperrt")
	await frames(40)
	check_eq(game.current_room.name, &"TestRoom2", "Raum 2 geladen")
	check_eq(player.global_position, Vector2(112, 32), "Spieler am Eingang 'from_test_area'")
	check_eq(player.facing, Vector2.DOWN, "Blickrichtung vom Eingang")
	check_eq([camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom], [0, 0, 256, 224], "Kamera-Grenzen Raum 2")
	check(player._controls_enabled, "Steuerung danach wieder frei")
	check_eq(game.get_node("RoomHolder").get_child_count(), 1, "Nur ein Raum geladen")

	# Zurück nach oben
	hold("move_up")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestArea":
			break
	hold("move_up", false)
	await frames(20)
	check_eq(game.current_room.name, &"TestArea", "Zurück im Testbereich")
	check_eq(player.global_position, Vector2(112, 416), "Spieler am Eingang 'from_room_2'")

	# Tod: zurück an den Start mit vollem Leben
	await game.change_room("res://world/test_area/test_room_2.tscn", &"from_test_area")
	player.take_damage(99)
	await continue_after_death(game)
	check_eq(game.current_room.name, &"TestArea", "Nach dem Tod im Startraum")
	check_eq(player.global_position, Vector2(64, 96), "Nach dem Tod am Start")
	check_eq(player.health, player.max_health, "Nach dem Tod volles Leben")
	game.queue_free()
