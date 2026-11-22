extends TestCase
## Kuh: blockiert den Spieler, macht keinen Schaden, Schwerthieb stößt sie weg.


func run() -> void:
	var player: Player = load("res://player/player.tscn").instantiate()
	player.position = Vector2(100, 100)
	add_child(player)
	var cow: Cow = load("res://npcs/cow/cow.tscn").instantiate()
	cow.position = Vector2(140, 100)
	add_child(cow)
	cow._timer = 999.0  # steht still
	await frames(2)

	hold("move_right")
	await frames(60)
	hold("move_right", false)
	check(player.global_position.x < 130, "Kuh blockiert den Weg (Spieler bei x=%d)" % player.global_position.x)
	check_eq(player.health, player.max_health, "Kuh macht keinen Schaden")
	check(cow.global_position.x > 138, "Spieler schiebt die Kuh nicht weg")

	var before := cow.global_position
	player.face(Vector2.RIGHT)
	await tap("attack")
	await frames(15)
	check(cow.global_position.x > before.x + 2, "Schwerthieb stößt die Kuh zurück")
	check(is_instance_valid(cow), "Kuh überlebt")
	cow.queue_free()
	player.queue_free()
