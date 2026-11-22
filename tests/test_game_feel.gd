extends TestCase
## Spielgefühl: Trefferstopp, Bildschirmwackeln, Partikel.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var camera: RoomCamera = game.get_node("RoomCamera")

	# Trefferstopp beim Schwerttreffer
	var slime: Enemy = game.current_room.get_node("Slime1")
	var hit := Hitbox.new()
	hit.damage = 1
	slime._on_hurt(hit)
	check_eq(Engine.time_scale, 0.0, "Treffer: Spielzeit steht kurz")
	await frames(10)
	check_eq(Engine.time_scale, 1.0, "Danach läuft sie weiter")

	# Spieler getroffen: Wackeln
	player._on_hurt(hit)
	await frames(2)
	var shook := false
	for i in 5:
		await frames(1)
		if camera.offset != Vector2.ZERO:
			shook = true
	check(shook, "Spieler getroffen: Bildschirm wackelt")
	await frames(20)
	check_eq(camera.offset, Vector2.ZERO, "Wackeln klingt ab")

	# Partikel beim Zerbrechen
	var pot: Breakable = game.current_room.get_node("Pot1")
	pot.break_apart()
	await frames(2)
	var bursts := game.current_room.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D)
	check(bursts.size() >= 1, "Krug: Partikel")
	await frames(60)
	bursts = game.current_room.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D)
	check_eq(bursts.size(), 0, "Partikel entfernen sich selbst")

	# Gegnertod: Rauch
	hit.damage = 99
	slime._on_hurt(hit)
	hit.free()
	await frames(2)
	bursts = game.current_room.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D)
	check(bursts.size() >= 1, "Gegnertod: Rauchwolke")
	game.queue_free()
	await frames(2)
	check_eq(Engine.time_scale, 1.0, "Spielzeit nach Ende normal")
