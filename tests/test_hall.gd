extends TestCase
## Große Halle (3×2 Bildschirme) über dem Startraum: Kamera läuft mit statt zu schieben,
## Truhe mit Herzcontainer, Speicherstatue, Gegner.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var camera: RoomCamera = game.get_node("RoomCamera")
	player.god_mode = true

	# Vom rechten Teil des Startraums nach oben
	player.global_position = Vector2(384, 40)
	await frames(2)
	hold("move_up")
	for i in 90:
		await frames(1)
		if game.current_room.name == &"TestHall":
			break
	hold("move_up", false)
	await frames(30)
	check_eq(game.current_room.name, &"TestHall", "Nordöffnung führt in die Halle")
	var hall := game.current_room
	check(not hall.screen_scroll, "Halle: Kamera läuft mit")
	check(hall.has_node("SaveStatue"), "Speicherstatue in der Halle")
	check(hall.find_children("*", "Enemy", true, false).size() >= 6, "Mehrere Gegner")

	# Kamera folgt ohne Schieben und ohne Pause
	var before := camera.get_screen_center_position()
	player.global_position = Vector2(400, 300)
	await frames(10)
	check(not get_tree().paused and not camera.is_scrolling(), "Kein Bildschirm-Scroll")
	check(camera.get_screen_center_position().distance_to(before) > 100.0, "Kamera ist mitgegangen")
	check(camera.get_screen_center_position().distance_to(player.global_position) < 40.0, "Held ungefähr in der Bildmitte")

	# Truhe mit Herzcontainer
	var chest: Chest = hall.get_node("HeartChest")
	var max_before := player.max_health
	player.global_position = chest.global_position + Vector2(0, 14)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)
	check_eq(player.max_health, max_before + Player.HP_PER_HEART, "Herzcontainer aus der Truhe")
	for i in 200:
		await frames(1)
		if not get_tree().paused:
			break

	# Zurück nach unten
	await game.change_room("res://world/test_area/test_area.tscn", &"from_hall")
	check_eq(player.global_position, Vector2(384, 28), "Zurück am Eingang im Startraum")
