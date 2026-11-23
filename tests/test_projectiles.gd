extends TestCase
## Geschosse und Skelett-Schütze: Pfeil trifft und verschwindet, steckt in Wänden, Abwehr nur mit
## passendem Schwert, Schütze hält Abstand, zielt und schießt in Linie.

const ARROW := preload("res://combat/projectile/arrow.tscn")


func run() -> void:
	var player: Player = load("res://player/player.tscn").instantiate()
	player.position = Vector2(150, 100)
	add_child(player)
	player.set_controls_enabled(false)
	await frames(2)

	# Pfeil trifft den Spieler
	var arrow := _shoot(Vector2(60, 100), Vector2.RIGHT)
	await frames(60)
	check_eq(player.health, player.max_health - 10, "Pfeil: ½ Herz")
	check(not is_instance_valid(arrow), "Pfeil verschwindet beim Treffer")

	# Pfeil steckt in der Wand
	var wall := _wall(Vector2(200, 30))
	var stuck_arrow := _shoot(Vector2(60, 30), Vector2.RIGHT)
	await frames(80)
	check(is_instance_valid(stuck_arrow) and stuck_arrow.is_stuck, "Pfeil steckt in der Wand")
	await frames(70)
	check(not is_instance_valid(stuck_arrow), "Nach ~1 s verschwindet er")

	# Startschwert wehrt nicht ab
	await frames(70)
	player.revive()
	player.set_controls_enabled(true)
	player.face(Vector2.LEFT)
	var a1 := _shoot(Vector2(80, 100), Vector2.RIGHT)
	await frames(24)
	await tap("attack")
	await frames(30)
	check(player.health < player.max_health, "Startschwert: Pfeil trifft trotzdem")
	check(not is_instance_valid(a1), "Pfeil weg (hat getroffen)")

	# Besseres Schwert wehrt ab
	await frames(70)
	player.revive()
	(player.get_node("SwordHitbox") as Hitbox).deflects_projectiles = true
	var a2 := _shoot(Vector2(80, 100), Vector2.RIGHT)
	await frames(24)
	await tap("attack")
	await frames(30)
	check_eq(player.health, player.max_health, "Abwehr-Schwert: kein Schaden")
	check(not is_instance_valid(a2), "Pfeil zerstört")
	(player.get_node("SwordHitbox") as Hitbox).deflects_projectiles = false

	# Schütze: weicht zurück, wenn man zu nah ist
	player.set_controls_enabled(false)
	await frames(70)
	player.revive()
	var archer: Archer = load("res://enemies/archer/archer.tscn").instantiate()
	archer.position = Vector2(150, 160)
	add_child(archer)
	player.global_position = Vector2(150, 130)
	await frames(30)
	check(archer.global_position.y > 165.0, "Zu nah: Schütze weicht zurück")
	check_eq(archer.max_health, 2, "2 Hiebe")

	# Schütze in Linie: zielt, dann schießt
	archer.global_position = Vector2(60, 200)
	player.global_position = Vector2(150, 196)
	archer._cooldown = 0.0
	var aimed := false
	var fired := false
	for i in 120:
		await frames(1)
		if archer.state == Archer.State.AIM:
			aimed = true
		if get_children().any(func(n: Node) -> bool: return n is Projectile):
			fired = true
			break
	check(aimed, "Schütze zielt vor dem Schuss")
	check(fired, "Schütze schießt in Linie")
	await frames(60)
	check(player.health < player.max_health, "Pfeil des Schützen trifft")
	archer.queue_free()
	wall.queue_free()
	player.queue_free()
	await frames(5)


func _shoot(from: Vector2, dir: Vector2) -> Projectile:
	var arrow: Projectile = ARROW.instantiate()
	arrow.direction = dir
	arrow.position = from
	add_child(arrow)
	return arrow


func _wall(pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	shape.shape = rect
	body.add_child(shape)
	body.position = pos
	add_child(body)
	return body
