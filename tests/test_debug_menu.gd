extends TestCase
## Debug-Menü: F1 öffnet/pausiert, Sachen geben, Unverwundbar, Schwierigkeit, Teleport, Raum zurücksetzen.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var menu: DebugMenu = game.get_node("DebugMenu")

	await tap("debug_menu")
	await frames(2)
	check(menu.is_open() and get_tree().paused, "F1 öffnet das Menü und pausiert")
	await tap("debug_menu")
	await frames(2)
	check(not menu.is_open() and not get_tree().paused, "F1 schließt wieder")

	menu.give("rupees")
	menu.give("key")
	menu.give("big_key")
	menu.give("heart")
	check_eq(GameState.rupees, 100, "+100 Rubine")
	check_eq(GameState.keys(), 1, "+1 Schlüssel")
	check_eq(GameState.big_keys(), 1, "+1 großer Schlüssel")
	check_eq(player.max_health, 80, "+1 Herz")

	menu.set_god_mode(true)
	player.take_damage(50)
	check_eq(player.health, player.max_health, "Unverwundbar: kein Schaden")
	menu.set_god_mode(false)

	menu.set_difficulty(6.0)
	await frames(2)
	check(game.current_room.has_node("SlimeTier6"), "Schwierigkeit 6: Variante erscheint nach Neuladen")
	menu.set_difficulty(4.0)
	await frames(2)
	check(not game.current_room.has_node("SlimeTier6"), "Zurück auf 4")

	var rooms := menu.room_paths()
	check(rooms.has("res://world/test_area/test_shop.tscn") and not rooms.has("res://world/game.tscn"), "Raumliste ohne game.tscn")
	menu.teleport_to("res://world/test_area/test_shop.tscn")
	await frames(3)
	check_eq(game.current_room.name, &"TestShop", "Teleport in den Shop")
	game.teleport("res://world/test_area/test_area.tscn", &"start")
	await frames(3)

	# Krug zerstören, Raum zurücksetzen -> wieder da
	(game.current_room.get_node("Pot1") as Breakable).break_apart()
	await frames(20)
	check(not game.current_room.has_node("Pot1"), "Krug zerstört")
	menu.reset_room()
	await frames(3)
	check(game.current_room.has_node("Pot1"), "Raum zurücksetzen: Krug wieder da")

	menu.defeat_enemies()
	await frames(60)
	var alive := game.current_room.find_children("*", "Node", true, false).filter(func(n: Node) -> bool: return n is Enemy and not (n as Enemy).is_dead())
	check_eq(alive.size(), 0, "Alle Gegner besiegt")
	game.queue_free()
