extends TestCase
## Fledermaus: flattert umher, wechselt Richtung, rastet, stirbt mit einem Hieb, ½ Herz Schaden.


func run() -> void:
	seed(7)
	var bat: Bat = load("res://enemies/bat/bat.tscn").instantiate()
	bat.position = Vector2(300, 300)
	add_child(bat)
	await frames(2)
	check_eq(bat.max_health, 1, "Ein Hieb reicht")
	check_eq(bat.damage, 10, "½ Herz Schaden")
	var positions: Array[Vector2] = []
	var rested := false
	for i in 360:
		await frames(1)
		if i % 20 == 0:
			positions.append(bat.global_position)
		if bat.state == Bat.State.REST and not rested:
			rested = true
			check_eq(bat.get_node("Hitbox/CollisionShape2D").position.y, Bat.REST_ZONE_Y, "Sitzend: Trefferzone am Boden (beim Bild)")
	check(bat.global_position.distance_to(Vector2(300, 300)) > 5.0 or rested, "Bewegt sich")
	var dirs := 0
	for i in range(2, positions.size()):
		var a := (positions[i - 1] - positions[i - 2]).normalized()
		var b := (positions[i] - positions[i - 1]).normalized()
		if a != Vector2.ZERO and b != Vector2.ZERO and a.dot(b) < 0.9:
			dirs += 1
	check(dirs >= 2, "Wechselt die Richtung (%d Wechsel)" % dirs)
	check(rested, "Setzt sich zwischendurch")
	var hit := Hitbox.new()
	hit.damage = 1
	bat.drop_table = null
	bat._on_hurt(hit)
	hit.free()
	check(bat.is_dead(), "Ein Hieb tötet")
	await frames(30)
