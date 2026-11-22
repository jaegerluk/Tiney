extends TestCase
## Schleim: Werte skalieren mit der Schwierigkeit, min_tier-Varianten, Schwert tötet, Berührung schadet.

const AREA := "res://world/test_area/test_area.tscn"
const SLIME := preload("res://enemies/slime/slime.tscn")


func run() -> void:
	# Werte je Schwierigkeit
	var base: EnemyStats = load("res://enemies/slime/slime_stats.tres")
	var slime := _spawn(Vector2(500, 500))
	check_eq(slime.max_health, base.max_health, "Bei 4,0: Basis-Leben")
	check_eq(slime.damage, base.damage, "Bei 4,0: Basis-Schaden")
	check(is_equal_approx(slime.move_speed, base.move_speed), "Bei 4,0: Basis-Tempo")
	slime.queue_free()
	Difficulty.value = 8.0
	var hard := _spawn(Vector2(500, 500))
	print("  Schleim bei 8,0: Leben %d, Schaden %d, Tempo %.1f" % [hard.max_health, hard.damage, hard.move_speed])
	check(hard.max_health > base.max_health, "Bei 8,0: mehr Leben")
	check(hard.move_speed > base.move_speed, "Bei 8,0: schneller")
	hard.queue_free()
	Difficulty.value = 1.0
	var easy := _spawn(Vector2(500, 500))
	check(easy.max_health >= 1 and easy.max_health <= base.max_health, "Bei 1,0: höchstens Basis-Leben, mindestens 1")
	easy.queue_free()

	# Raumvarianten über min_tier
	Difficulty.value = 4.0
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	check(game.current_room.has_node("Slime1") and game.current_room.has_node("Slime2"), "Normale Schleime da")
	check(not game.current_room.has_node("SlimeTier6"), "Stufe-6-Schleim fehlt bei 4,0")
	game.queue_free()
	await frames(2)
	Difficulty.value = 6.0
	game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	check(game.current_room.has_node("SlimeTier6"), "Stufe-6-Schleim da bei 6,0")
	game.queue_free()
	await frames(2)
	Difficulty.value = 4.0

	# Kampf: Spieler und Schleim allein
	var player: Player = load("res://player/player.tscn").instantiate()
	player.position = Vector2(100, 100)
	add_child(player)
	var target := _spawn(Vector2(106, 100))
	target.set_physics_process(false)  # stillhalten
	target.drop_table = null
	var deaths := [0]
	target.died.connect(func() -> void: deaths[0] += 1)
	await frames(3)
	player.face(Vector2.RIGHT)
	check_eq(player.health, player.max_health - target.damage, "Berührung kostet Leben")
	check(player.is_invincible(), "Danach unverwundbar")
	await frames(15)  # Rückstoß abklingen lassen
	player.global_position = Vector2(100, 100)
	await frames(2)
	await tap("attack")
	await frames(30)
	check_eq(target.health, target.max_health - 1, "Schwerthieb: 1 Schaden")
	await tap("attack")
	await frames(10)
	check(target.is_dead(), "Zweiter Hieb tötet")
	check_eq(deaths[0], 1, "Signal died genau einmal")
	await frames(40)
	check(not is_instance_valid(target), "Schleim nach Todesanimation entfernt")

	# Verfolgung: Schleim in Reichweite bewegt sich zum Spieler
	var hunter := _spawn(Vector2(150, 100))
	hunter._timer = 0.0
	hunter._hopping = false
	await frames(10)
	check(hunter.global_position.x < 150, "Schleim hüpft auf den Spieler zu")
	hunter.queue_free()
	player.queue_free()


func _spawn(pos: Vector2) -> Slime:
	var s: Slime = SLIME.instantiate()
	s.position = pos
	add_child(s)
	return s
