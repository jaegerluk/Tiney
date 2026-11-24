extends TestCase
## Speicherstatue: Interaktion speichert; Tod setzt alles auf diesen Stand zurück, volles Leben an der Statue.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var room := game.current_room
	var statue: SaveStatue = room.get_node("SaveStatue")

	# Vor dem Speichern: ein Rubin
	await _step_on(game, player, "Rupee1")
	check_eq(GameState.rupees, 1, "Ein Rubin vor dem Speichern")

	# Neben der Pfütze: kein Speichern; in die Pfütze laufen: Speichern
	player.global_position = statue.respawn_position()
	await frames(3)
	check(not statue.get_node("TextBubble").visible, "Vor der Pfütze wird nicht gespeichert")
	player.take_damage(1)
	hold("move_up")
	for i in 30:
		await frames(1)
		if statue.get_node("TextBubble").visible:
			break
	hold("move_up", false)
	check(statue.get_node("TextBubble").visible, "Pfütze betreten: Meldung „Gespeichert“")
	check_eq(player.health, player.max_health - 1, "Statue heilt nicht")

	# Danach: Rubin, Schlüssel, Krug, Schleim, Apfel
	await _step_on(game, player, "Rupee3")
	await _step_on(game, player, "SmallKey")
	await _step_on(game, player, "Apple1")
	(room.get_node("Pot1") as Breakable).break_apart()
	var slime: Enemy = room.get_node("Slime1")
	slime.drop_table = null
	var hit := Hitbox.new()
	hit.damage = 99
	slime._on_hurt(hit)
	hit.free()
	await frames(30)
	check_eq(GameState.rupees, 21, "Rubin nach dem Speichern eingesammelt")
	check_eq(GameState.keys(), 1, "Schlüssel nach dem Speichern")
	var apples_before: int = player.inventory.slots[0].amount
	var respawn := statue.respawn_position()

	# Tod
	player.take_damage(99)
	await continue_after_death(game)
	room = game.current_room
	check_eq(GameState.rupees, 1, "Rubine auf Stand der Statue")
	check_eq(GameState.keys(), 0, "Schlüssel auf Stand der Statue")
	check(room.has_node("Rupee3") and room.has_node("SmallKey"), "Eingesammeltes liegt wieder da")
	check(room.has_node("Pot1"), "Krug wieder ganz")
	check(room.has_node("Slime1"), "Schleim wieder da")
	check(not room.has_node("Rupee1"), "Vor dem Speichern Eingesammeltes bleibt weg")
	check_eq(player.inventory.slots[0].amount, apples_before - 1, "Inventar auf Stand der Statue")
	check_eq(player.global_position, respawn, "Spieler an der Statue")
	check_eq(player.health, player.max_health, "Volles Leben nach dem Tod")
	check_eq(game.get_node("HUD/%RupeeLabel").text, "001", "HUD zeigt zurückgesetzte Rubine")
	game.queue_free()


func _step_on(game: Game, player: Player, node_name: String) -> void:
	var target: Node2D = game.current_room.get_node(node_name)
	player.global_position = target.global_position - Vector2(0, 4)
	await frames(3)
	player.global_position = Vector2(64, 96)
	await frames(2)
