extends TestCase
## Bildschirm-Scrollen (ALttP) und Treppen.

const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var camera: RoomCamera = game.get_node("RoomCamera")
	check_eq(camera.global_position, Vector2(128, 112), "Start: Kamera auf Bildschirm oben links")

	# Innerhalb eines Bildschirms bewegt sich die Kamera nicht
	hold("move_down")
	await frames(20)
	hold("move_down", false)
	check_eq(camera.global_position, Vector2(128, 112), "Kamera steht still im Bildschirm")

	# Über die Grenze nach unten laufen
	player.global_position = Vector2(64, 214)
	await frames(2)
	hold("move_down")
	var scrolled := false
	for i in 40:
		await frames(1)
		if camera.is_scrolling():
			scrolled = true
			break
	hold("move_down", false)
	check(scrolled, "Grenze überschritten: Kamera schiebt")
	check(get_tree().paused, "Während des Schiebens ist alles eingefroren")
	for i in 60:
		await frames(1)
		if not camera.is_scrolling():
			break
	await frames(2)
	check_eq(camera.global_position, Vector2(128, 336), "Kamera auf dem Bildschirm unten links")
	check(not get_tree().paused, "Danach geht es weiter")
	check(player.global_position.y > 224 + 10, "Spieler ist in den neuen Bildschirm gerückt")

	# Treppe nach unten (Raum 2 -> Keller) und wieder hoch
	await game.change_room(ROOM2, &"from_test_area")
	player.global_position = Vector2(224, 58)
	await frames(2)
	hold("move_up")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestCellar":
			break
	hold("move_up", false)
	await frames(20)
	check_eq(game.current_room.name, &"TestCellar", "Treppe runter in den Keller")
	check_eq(player.global_position, Vector2(200, 84), "Am Treppeneingang im Keller")
	hold("move_up")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestRoom2":
			break
	hold("move_up", false)
	await frames(20)
	check_eq(game.current_room.name, &"TestRoom2", "Treppe hoch zurück in Raum 2")
	game.queue_free()
