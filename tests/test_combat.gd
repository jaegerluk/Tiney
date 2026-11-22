extends TestCase
## Hitbox/Hurtbox: Spieler nimmt Schaden mit Rückstoß und Unverwundbarkeit, Schwert trifft Hurtboxen.


func run() -> void:
	var player: Player = load("res://player/player.tscn").instantiate()
	player.position = Vector2(100, 100)
	add_child(player)
	await frames(2)

	# Gegnerische Hitbox direkt rechts neben dem Spieler
	var enemy_hit := _make_area(Hitbox.new(), 16, 0, Vector2(108, 100))
	enemy_hit.damage = 20
	await frames(3)
	check_eq(player.health, 40, "Treffer kostet 1 Herz (20 LP)")
	check(player.is_invincible(), "Danach unverwundbar")
	await frames(10)
	check(player.global_position.x < 98, "Rückstoß nach links (weg von der Hitbox)")

	# Hitbox auf den Spieler setzen: während der Unverwundbarkeit kein Schaden
	enemy_hit.global_position = player.global_position
	await frames(20)
	check_eq(player.health, 40, "Kein Schaden während Unverwundbarkeit")
	# Nach Ablauf zählt die Überlappung erneut
	enemy_hit.global_position = player.global_position
	await frames(60)
	check_eq(player.health, 20, "Nach Unverwundbarkeit erneut getroffen")
	enemy_hit.queue_free()

	# Tod
	var deaths := [0]
	player.died.connect(func() -> void: deaths[0] += 1)
	player.take_damage(50)
	check_eq(deaths[0], 1, "died bei 0 Leben")
	player.revive()
	check_eq(player.health, player.max_health, "revive füllt Leben auf")

	# Schwert trifft eine Hurtbox vor dem Spieler
	await frames(80)
	player.face(Vector2.RIGHT)
	var target := _make_area(Hurtbox.new(), 0, 8, player.global_position + Vector2(14, 0))
	var hits: Array[Hitbox] = []
	target.hurt.connect(func(h: Hitbox) -> void: hits.append(h))
	await frames(2)
	check_eq(hits.size(), 0, "Ohne Angriff kein Treffer")
	await tap("attack")
	await frames(5)
	check_eq(hits.size(), 1, "Schwert trifft einmal pro Schlag")
	check(hits.size() > 0 and hits[0].knockback_direction(target.global_position).x > 0, "Rückstoß vom Spieler weg")
	await frames(30)
	await tap("attack")
	await frames(5)
	check_eq(hits.size(), 2, "Zweiter Schlag trifft erneut")
	player.queue_free()
	target.queue_free()


func _make_area(area: Area2D, layer: int, mask: int, pos: Vector2) -> Area2D:
	area.collision_layer = layer
	area.collision_mask = mask
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 10)
	shape.shape = rect
	area.add_child(shape)
	area.global_position = pos
	add_child(area)
	return area
