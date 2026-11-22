extends TestCase
## Zombie: wartet, bis der Spieler nah ist, verfolgt dann stur; zäh, 1 Herz Schaden.


func run() -> void:
	var player: Player = load("res://player/player.tscn").instantiate()
	player.position = Vector2(300, 100)
	add_child(player)
	var zombie: Zombie = load("res://enemies/zombie/zombie.tscn").instantiate()
	zombie.position = Vector2(100, 100)
	add_child(zombie)
	await frames(20)
	check(not zombie.is_chasing(), "Spieler weit weg: Zombie wartet")
	check_eq(zombie.global_position, Vector2(100, 100), "Steht still")
	check_eq(zombie.max_health, 4, "4 Leben bei 4,0")
	check_eq(zombie.damage, 20, "1 Herz Schaden bei 4,0")

	player.global_position = Vector2(180, 100)
	await frames(30)
	check(zombie.is_chasing(), "In Reichweite: Zombie bemerkt den Spieler")
	check(zombie.global_position.x > 105, "Schlurft auf den Spieler zu")
	var speed := (zombie.global_position.x - 100.0) / 0.5
	check(speed < 40.0, "Langsam (%.0f px/s)" % speed)

	player.global_position = Vector2(400, 100)
	await frames(30)
	check(zombie.is_chasing(), "Folgt stur, auch wenn der Spieler weggeht")

	# Vier Schwerthiebe
	zombie.set_physics_process(false)
	var hit := Hitbox.new()
	hit.damage = 1
	for i in 3:
		zombie._on_hurt(hit)
	check(not zombie.is_dead(), "Drei Hiebe reichen nicht")
	zombie._on_hurt(hit)
	check(zombie.is_dead(), "Vierter Hieb tötet")
	hit.free()
	player.queue_free()
	await frames(30)
