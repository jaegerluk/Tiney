extends TestCase
## Fallen: Stacheln (dauerhaft, taktend), Klingenfallen (lauernd, pendelnd), bröckelnde Platten.


func run() -> void:
	var player: Player = load("res://player/player.tscn").instantiate()
	player.position = Vector2(100, 100)
	add_child(player)
	player.set_controls_enabled(false)

	# Dauerhafte Stacheln unter dem Spieler
	var always: Spikes = load("res://objects/spikes/spikes.tscn").instantiate()
	always.mode = Spikes.Mode.ALWAYS
	always.position = Vector2(100, 102)
	add_child(always)
	await frames(4)
	check_eq(player.health, player.max_health - 10, "Dauerhafte Stacheln: ½ Herz")
	always.queue_free()
	player.revive()
	await frames(5)

	# Taktende Stacheln: erst unten, dann hoch
	var timed: Spikes = load("res://objects/spikes/spikes.tscn").instantiate()
	timed.mode = Spikes.Mode.TIMED
	timed.phase_offset = 1.6  # startet in der Ruhephase
	timed.position = Vector2(200, 150)
	add_child(timed)
	await frames(2)
	check(not timed.is_up, "Taktend: zuerst eingefahren")
	player.global_position = Vector2(200, 148)
	await frames(30)
	check_eq(player.health, player.max_health, "Eingefahren: kein Schaden")
	await frames(70)
	check(timed.get_node("Sprite2D").frame == 1 or timed.is_up, "Warnung vor dem Ausfahren")
	await frames(30)
	check(timed.is_up, "Danach ausgefahren")
	check(player.health < player.max_health, "Ausgefahren unter dem Spieler: Schaden")

	# Schaden skaliert mit der Schwierigkeit
	Difficulty.value = 8.0
	var hard: Spikes = load("res://objects/spikes/spikes.tscn").instantiate()
	add_child(hard)
	check(hard.get_node("Hitbox").damage > 10, "Bei 8,0 mehr Schaden (%d)" % hard.get_node("Hitbox").damage)
	Difficulty.value = 4.0
	hard.queue_free()
	timed.queue_free()
	player.queue_free()
	await frames(2)

	# Lauernde Klingenfalle: Wand rechts bei x=300
	var wall := _wall(Vector2(240, 120), Vector2(16, 64))
	var sentry: BladeTrap = load("res://objects/blade_trap/blade_trap.tscn").instantiate()
	sentry.position = Vector2(40, 120)
	add_child(sentry)
	var p2: Player = load("res://player/player.tscn").instantiate()
	p2.position = Vector2(160, 200)
	add_child(p2)
	p2.set_controls_enabled(false)
	await frames(10)
	check_eq(sentry.state, BladeTrap.State.IDLE, "Spieler nicht in der Reihe: Falle lauert")
	p2.global_position = Vector2(160, 122)
	await frames(2)
	check_eq(sentry.state, BladeTrap.State.ATTACK, "Spieler in der Reihe: Falle schießt los")
	await frames(40)
	check(p2.health < p2.max_health, "Falle trifft den Spieler")
	p2.global_position = Vector2(160, 200)
	for i in 120:
		await frames(1)
		if sentry.state == BladeTrap.State.RETURN:
			break
	check_eq(sentry.state, BladeTrap.State.RETURN, "An der Wand abgeprallt, kehrt zurück")
	check(sentry.position.x < 240, "Nicht durch die Wand")
	for i in 400:
		await frames(1)
		if sentry.state == BladeTrap.State.IDLE:
			break
	check_eq(sentry.position, Vector2(40, 120), "Zurück an der Ruheposition")

	# Wand zwischen Falle und Spieler: keine Reaktion
	var blocker := _wall(Vector2(100, 120), Vector2(16, 16))
	p2.global_position = Vector2(160, 120)
	await frames(10)
	check_eq(sentry.state, BladeTrap.State.IDLE, "Wand dazwischen: Falle bleibt ruhig")

	blocker.queue_free()
	# Falle außerhalb des Bildschirms reagiert nicht
	var off: BladeTrap = load("res://objects/blade_trap/blade_trap.tscn").instantiate()
	off.position = Vector2(400, 60)
	add_child(off)
	p2.global_position = Vector2(200, 60)
	await frames(10)
	check_eq(off.state, BladeTrap.State.IDLE, "Falle außerhalb des Bildschirms bleibt ruhig")
	off.queue_free()
	var outside: Spikes = load("res://objects/spikes/spikes.tscn").instantiate()
	outside.position = Vector2(600, 600)
	add_child(outside)
	await frames(200)
	check(not outside.is_up, "Taktende Stacheln außerhalb des Bildschirms bleiben eingefahren")
	outside.queue_free()

	# Pendelnde Falle
	var patrol: BladeTrap = load("res://objects/blade_trap/blade_trap.tscn").instantiate()
	patrol.mode = BladeTrap.Mode.PATROL
	patrol.patrol_offset = Vector2(64, 0)
	patrol.position = Vector2(500, 600)
	add_child(patrol)
	await frames(2)
	check_eq(patrol.get_node("Sprite2D").frame, 1, "Pendelnd: bronze")
	var max_x := 500.0
	for i in 150:
		await frames(1)
		max_x = maxf(max_x, patrol.position.x)
	check(max_x > 560.0 and patrol.position.x < max_x, "Pendelt hin und zurück")
	for n in [wall, sentry, patrol]:
		n.queue_free()

	# Bröckelnde Platten: Reihe von 3, Spieler läuft von links darüber
	p2.revive()
	var tiles: Array[CrumbleFloor] = []
	for i in 3:
		var tile: CrumbleFloor = load("res://objects/crumble_floor/crumble_floor.tscn").instantiate()
		tile.position = Vector2(700 + i * 16, 800)
		add_child(tile)
		tiles.append(tile)
	var regrow: CrumbleFloor = load("res://objects/crumble_floor/crumble_floor.tscn").instantiate()
	regrow.regrow_time = 1.0
	regrow.position = Vector2(900, 800)
	add_child(regrow)
	p2.global_position = Vector2(670, 800)
	p2.set_controls_enabled(true)
	await frames(3)
	hold("move_right")
	await frames(30)
	hold("move_right", false)
	check(tiles[0]._triggered, "Betreten löst das Bröckeln aus")
	check(not tiles[0].is_broken, "Noch nicht sofort weg")
	await frames(40)
	check(tiles[0].is_broken, "Nach 0,5 s ist die Platte ein Loch")
	for i in 120:
		await frames(1)
		if p2.is_falling():
			break
	check(p2.is_falling() or p2.health < p2.max_health, "Spieler fällt durch")
	await frames(60)
	check(p2.global_position.x < 700 - 8, "Wieder abgesetzt vor den Platten (x=%d)" % p2.global_position.x)
	check(tiles[0].is_broken, "Platte bleibt ein Loch")
	# Nachwachsende Platte
	regrow._crumble()
	await frames(40)
	check(regrow.is_broken, "Nachwachsende Platte zerfällt")
	await frames(70)
	check(not regrow.is_broken, "Nach regrow_time wieder ganz")
	for n in tiles:
		n.queue_free()
	regrow.queue_free()
	p2.queue_free()
	await frames(2)


func _wall(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = pos
	add_child(body)
	return body
