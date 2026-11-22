extends TestCase
## In Räumen mit bildschirmweisem Scrollen bleiben Gegner in ihrem Bildschirm.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var zombie: Zombie = game.current_room.get_node("Zombie1")
	check_eq(zombie.confine_rect, Rect2(256, 0, 256, 224), "Zombie gehört zum Bildschirm oben rechts")
	# Spieler unten rechts in der Nähe: Zombie verfolgt, bleibt aber oben
	player.set_controls_enabled(false)
	player.global_position = Vector2(440, 200)
	await frames(10)
	player.global_position = Vector2(440, 300)
	await frames(400)
	check(zombie.is_chasing(), "Zombie verfolgt den Spieler")
	check(zombie.global_position.y <= 224 - 8 + 0.01, "Zombie bleibt im eigenen Bildschirm (y=%d)" % zombie.global_position.y)
	# Raum ohne bildschirmweises Scrollen: keine Grenze
	var room := game.current_room
	room.screen_scroll = false
	var free_zombie: Zombie = load("res://enemies/zombie/zombie.tscn").instantiate()
	free_zombie.position = Vector2(300, 100)
	room.add_child(free_zombie)
	await frames(2)
	check(not free_zombie.confine_rect.has_area(), "Ohne Bildschirm-Scrollen keine Grenze")
	game.queue_free()
