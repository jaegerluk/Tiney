extends TestCase
## Goldene Seelen (Sammelobjekt): Krug im Startraum enthält eine, Aufheben zählt, hält hoch, Menü zeigt den Zähler, Tod setzt zurück.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var room := game.current_room
	var pot: Breakable = room.get_node("SoulPot")
	pot.break_apart()
	await frames(2)
	var soul: GoldenSoulPickup = null
	for d in get_tree().get_nodes_in_group(DropTable.DROP_GROUP):
		if d is GoldenSoulPickup:
			soul = d
	check(soul != null, "Krug enthält eine goldene Seele")
	if soul == null:
		return
	player.global_position = soul.global_position
	await frames(3)
	check_eq(GameState.souls, 1, "Seele gezählt")
	check(get_tree().paused, "Seele wird hochgehalten (Pause)")
	var hud := game.get_node("HUD")
	check_eq(hud.get_node("%MessageLabel").text, "You found a Golden Soul! (1)", "Meldung mit Zahl")
	for i in 200:
		await frames(1)
		if not get_tree().paused:
			break
	check(not get_tree().paused, "Pause endet")
	var ui := game.find_children("*", "InventoryUI", true, false)
	check(ui.size() == 1, "Inventar-Menü gefunden")
	if ui.size() == 1:
		check_eq((ui[0].get_node("%SoulCount") as Label).text, "Golden Souls: 1", "Menü zeigt Zähler")

	# Spielstand: snapshot/restore
	var snap := GameState.snapshot()
	GameState.add_soul()
	check_eq(GameState.souls, 2, "Zweite Seele")
	GameState.restore(snap)
	check_eq(GameState.souls, 1, "Restore setzt Zähler zurück")
