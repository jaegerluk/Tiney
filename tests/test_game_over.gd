extends TestCase
## Game Over: Todesanimation, Bildschirm wartet auf Continue, danach an der Statue mit vollem Leben.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var screen: GameOverScreen = game.get_node("GameOver")
	player.take_damage(999)
	await frames(10)
	check(get_tree().paused, "Tod: Spiel friert ein")
	for i in 150:
		await frames(1)
		if screen.is_waiting():
			break
	check(screen.is_waiting(), "Game-Over-Bildschirm wartet auf Continue")
	check(screen.get_node("Title").visible, "Schriftzug GAME OVER")
	await frames(120)
	check(screen.is_waiting() and get_tree().paused, "Ohne Eingabe geht es nicht weiter")
	await tap("interact")
	for i in 60:
		await frames(1)
		if not get_tree().paused:
			break
	await frames(30)
	check(not get_tree().paused, "Continue: Spiel läuft weiter")
	check_eq(player.health, player.max_health, "Volles Leben")
	check_eq(player.global_position, Vector2(64, 96), "Am letzten Spielstand (Start)")
	check(player.get_node("Sprite2D").scale == Vector2.ONE and player.get_node("Sprite2D").rotation == 0.0, "Held wieder normal")
	check(not screen.get_node("Title").visible, "Schriftzug weg")
	game.queue_free()
