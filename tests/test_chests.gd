extends TestCase
## Truhen (von jeder Seite, Hochhalten, bleiben offen), großer Schlüssel, Bosstür (verbraucht ihn).

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var hud: HUD = game.get_node("HUD")
	var chest: Chest = game.current_room.get_node("Chest")

	# Von rechts, aber weggeschaut: nichts
	player.global_position = chest.global_position + Vector2(16, 0)
	player.face(Vector2.RIGHT)
	await frames(3)
	await tap("interact")
	check(not chest.is_open, "Weggeschaut: Truhe bleibt zu")

	# Von rechts, zur Truhe geschaut: öffnen
	player.face(Vector2.LEFT)
	await tap("interact")
	await frames(2)
	check(chest.is_open, "Von der Seite geöffnet")
	check(get_tree().paused, "Spiel pausiert beim Hochhalten")
	check(player.get_node("HeldItem").visible, "Held hält den Inhalt hoch")
	check_eq(GameState.rupees, 20, "Roter Rubin aus der Truhe")
	await frames(60)
	check(not get_tree().paused, "Danach geht es weiter")
	check(not player.get_node("HeldItem").visible, "Item wieder weg")
	await tap("interact")
	await frames(2)
	check_eq(GameState.rupees, 20, "Offene Truhe gibt nichts mehr")

	# Bleibt offen nach Raumwechsel
	await game.change_room(ROOM2, &"from_test_area")
	await game.change_room(AREA, &"from_room_2")
	await frames(2)
	check((game.current_room.get_node("Chest") as Chest).is_open, "Truhe bleibt offen")

	# Raum 2: Truhe mit großem Schlüssel (von unten)
	await game.change_room(ROOM2, &"from_test_area")
	var room := game.current_room
	var big_chest: Chest = room.get_node("BigKeyChest")
	player.global_position = big_chest.global_position + Vector2(0, 10)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)
	check(hud.get_node("%MessageBox").visible, "Meldung sichtbar")
	check_eq(hud.get_node("%MessageLabel").text, "You got the Big Key!", "Meldungstext")
	check_eq(GameState.big_keys(), 1, "Großer Schlüssel erhalten")
	check(hud.get_node("%BigKeyIcon").visible, "HUD zeigt den großen Schlüssel")
	await frames(110)
	check(not hud.get_node("%MessageBox").visible, "Meldung verschwindet")

	# Kleiner Schlüssel öffnet die Bosstür nicht
	GameState.add_key()
	GameState.add_big_key(&"anderer_dungeon")
	var big := GameState.big_keys()
	GameState._big_keys[&"test"] = 0
	player.global_position = Vector2(128, 176)
	hold("move_down")
	await frames(20)
	hold("move_down", false)
	check(room.has_node("BossDoor"), "Ohne großen Schlüssel bleibt die Bosstür zu")
	check_eq(GameState.keys(), 1, "Kleiner Schlüssel nicht verbraucht")

	# Mit großem Schlüssel: auf, verbraucht, weiter in den Bossraum
	GameState.add_big_key()
	hold("move_down")
	for i in 90:
		await frames(1)
		if game.current_room.name == &"TestBossRoom":
			break
	hold("move_down", false)
	check_eq(GameState.big_keys(), 0, "Großer Schlüssel verbraucht")
	check(not hud.get_node("%BigKeyIcon").visible, "HUD-Symbol weg")
	check_eq(game.current_room.name, &"TestBossRoom", "Durch die Bosstür in den Bossraum")
	await frames(20)
	await game.change_room(ROOM2, &"from_boss_room")
	await frames(2)
	check(not game.current_room.has_node("BossDoor"), "Bosstür bleibt offen")
	check((game.current_room.get_node("BigKeyChest") as Chest).is_open, "Schlüsseltruhe bleibt offen")
	check(big >= 1, "Schlüssel anderer Dungeons zählen getrennt")
	game.queue_free()
