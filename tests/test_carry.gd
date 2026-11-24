extends TestCase
## Heben & Werfen: Krug heben, tragen sperrt das Schwert, Wurf zerbricht, trifft Gegner und Kristalle,
## Inhalt fällt am Aufprallort heraus; Treffer lässt fallen; Stein nur werfbar.

const POT := preload("res://objects/breakable/pot.tscn")
const STONE := preload("res://objects/breakable/stone.tscn")


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var room := game.current_room
	room.get_node("Cow").queue_free()  # läuft sonst durch die Wurfbahn
	var player: Player = game.get_node("Player")
	player.god_mode = true

	# Krug mit festem Inhalt in den Raum stellen und heben
	var pot: Breakable = POT.instantiate()
	pot.fixed_drop = load("res://items/pickups/rupee_blue.tscn")
	pot.position = Vector2(44, 280)
	room.add_child(pot)
	player.global_position = Vector2(60, 280)
	player.face(Vector2.LEFT)
	await frames(3)
	await tap("interact")
	await frames(3)
	check(player.is_carrying(), "Interaktion hebt den Krug")
	check(not is_instance_valid(pot), "Krug ist vom Boden weg")
	check(player.get_node("CarriedSprite").visible, "Krug über dem Kopf")

	# Tragen: kein Schwert
	await frames(2)
	player.face(Vector2.RIGHT)
	hold("attack")
	await frames(2)
	check(not player.is_attacking(), "Beim Tragen kein Schwerthieb")
	hold("attack", false)
	check(not player.is_carrying(), "Angriffstaste wirft")
	await frames(40)
	var drops := get_tree().get_nodes_in_group(DropTable.DROP_GROUP).filter(func(n: Node) -> bool: return room.is_ancestor_of(n))
	check_eq(drops.size(), 1, "Inhalt fällt beim Aufprall heraus")
	if drops.size() == 1:
		check(drops[0].position.x > 60.0 + 50.0, "…ein Stück weiter weg (Wurfweite, x=%d)" % drops[0].position.x)
		drops[0].queue_free()

	# Wurf trifft Gegner: 1 Treffer
	var zombie: Zombie = load("res://enemies/zombie/zombie.tscn").instantiate()
	zombie.position = Vector2(110, 280)
	zombie.drop_table = null
	room.add_child(zombie)
	zombie.set_physics_process(false)
	var pot2: Breakable = POT.instantiate()
	pot2.drop_table = null
	pot2.position = Vector2(44, 280)
	room.add_child(pot2)
	player.global_position = Vector2(60, 280)
	player.face(Vector2.LEFT)
	await frames(3)
	await tap("interact")
	await frames(3)
	player.face(Vector2.RIGHT)
	await tap("interact")
	await frames(40)
	check_eq(zombie.health, zombie.max_health - 1, "Wurf trifft Gegner: 1 Treffer")
	zombie.queue_free()

	# Wurf löst einen Kristallschalter aus
	var crystal: CrystalSwitch = load("res://objects/crystal_switch/crystal_switch.tscn").instantiate()
	crystal.position = Vector2(110, 286)
	room.add_child(crystal)
	var pot_c: Breakable = POT.instantiate()
	pot_c.drop_table = null
	pot_c.position = Vector2(44, 280)
	room.add_child(pot_c)
	player.global_position = Vector2(60, 280)
	player.face(Vector2.LEFT)
	await frames(3)
	await tap("interact")
	await frames(3)
	player.face(Vector2.RIGHT)
	await tap("interact")
	await frames(40)
	check(crystal.is_on, "Wurf löst den Kristallschalter aus")
	crystal.queue_free()

	# Getroffen werden: Krug fällt herunter und zerbricht
	var pot3: Breakable = POT.instantiate()
	pot3.drop_table = null
	pot3.position = Vector2(44, 280)
	room.add_child(pot3)
	player.global_position = Vector2(60, 280)
	player.face(Vector2.LEFT)
	await frames(3)
	await tap("interact")
	await frames(3)
	check(player.is_carrying(), "Wieder am Tragen")
	player.god_mode = false
	await frames(70)
	var hit := Hitbox.new()
	hit.damage = 10
	player._on_hurt(hit)
	hit.free()
	await frames(3)
	check(not player.is_carrying(), "Treffer: Krug fällt herunter")

	# Stein: Schwert zerbricht ihn nicht, heben geht
	player.revive()
	var stone: Breakable = STONE.instantiate()
	stone.position = Vector2(44, 280)
	room.add_child(stone)
	player.global_position = Vector2(60, 280)
	player.face(Vector2.LEFT)
	await frames(80)
	await tap("attack")
	await frames(30)
	check(is_instance_valid(stone), "Schwert zerbricht den Stein nicht")
	await tap("interact")
	await frames(3)
	check(player.is_carrying(), "Stein lässt sich heben")
	player.face(Vector2.RIGHT)
	await tap("interact")
	await frames(40)
	check(not player.is_carrying(), "Stein geworfen")

	# Krug weiterhin per Schwert zerbrechlich
	var pot4: Breakable = POT.instantiate()
	pot4.drop_table = null
	pot4.position = Vector2(44, 280)
	room.add_child(pot4)
	player.face(Vector2.LEFT)
	await frames(3)
	await tap("attack")
	await frames(30)
	check(not is_instance_valid(pot4), "Krug geht auch per Schwert kaputt")

	# Raumwechsel beim Tragen: verworfen
	var pot5: Breakable = POT.instantiate()
	pot5.drop_table = null
	pot5.position = Vector2(44, 280)
	room.add_child(pot5)
	await frames(3)
	await tap("interact")
	await frames(3)
	game.teleport("res://world/test_area/test_area.tscn", &"start")
	await frames(3)
	check(not player.is_carrying(), "Raumwechsel: getragener Krug verworfen")
	game.queue_free()
