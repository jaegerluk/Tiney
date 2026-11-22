extends TestCase
## Löcher: Rand ist sicher, darüber fällt man; ohne Ziel ½ Herz und zurück an sicheren Boden,
## mit Ziel ein Stockwerk tiefer ohne Schaden.

const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var pit: Pit = game.current_room.get_node("Pit")

	# Von links ins Loch laufen
	player.global_position = pit.global_position + Vector2(-30, 0)
	await frames(3)
	var safe_before := player.global_position
	hold("move_right")
	for i in 60:
		await frames(1)
		if player.is_falling():
			break
	hold("move_right", false)
	check(player.is_falling(), "Spieler fällt ins Loch")
	check(player.last_safe_position.x < pit.global_position.x - 16, "Sichere Stelle liegt vor dem Loch")
	await frames(40)
	check(not player.is_falling(), "Wieder aufgetaucht")
	check_eq(player.health, player.max_health - 10, "½ Herz Schaden")
	check(player.global_position.x < pit.global_position.x - 16 and player.global_position.x >= safe_before.x, "Zurück an sicherem Boden vor dem Loch")
	hold("move_left")
	await frames(10)
	hold("move_left", false)
	check(player.global_position.x < player.last_safe_position.x + 1.0, "Steuerung funktioniert wieder")

	# Loch mit Ziel: ein Stockwerk tiefer
	await game.change_room(ROOM2, &"from_test_area")
	var pit2: Pit = game.current_room.get_node("PitToCellar")
	var health_before := player.health
	player.global_position = pit2.global_position + Vector2(0, -4)
	for i in 120:
		await frames(1)
		if game.current_room.name == &"TestCellar":
			break
	await frames(30)
	check_eq(game.current_room.name, &"TestCellar", "Ein Stockwerk tiefer im Keller")
	check_eq(player.health, health_before, "Kein Schaden beim Sturz in den Keller")
	check(player.get_node("Sprite2D").visible and player.get_node("Sprite2D").scale == Vector2.ONE, "Spieler sichtbar und normal groß")
	check(player._controls_enabled, "Steuerung wieder frei")
	game.queue_free()
