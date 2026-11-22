extends TestCase
## Nichts erscheint neu: Gegner, Schalter, liegen gelassene Drops über Raumwechsel.

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var room := game.current_room

	# Schalter betreten -> Tür offen
	player.global_position = room.get_node("FloorSwitch").global_position
	await frames(3)
	check(room.get_node("SwitchDoor").is_open, "Schalter öffnet die Tür")

	# Schleim töten
	var slime: Enemy = room.get_node("Slime1")
	slime.drop_table = null
	var hit := Hitbox.new()
	hit.damage = 99
	slime._on_hurt(hit)
	hit.free()
	check(slime.is_dead(), "Schleim tot")

	# Drop liegen lassen (zur Laufzeit erzeugt)
	DropTable.spawn_scene(load("res://items/pickups/rupee_red.tscn"), room, Vector2(120, 300))
	await frames(2)

	player.global_position = Vector2(64, 96)
	await frames(2)
	await game.change_room(ROOM2, &"from_test_area")
	await game.change_room(AREA, &"from_room_2")
	await frames(3)
	room = game.current_room
	check(not room.has_node("Slime1"), "Toter Schleim bleibt tot")
	check(room.has_node("Slime2"), "Anderer Schleim lebt")
	check(room.get_node("FloorSwitch").is_on, "Schalter bleibt an")
	check(room.get_node("SwitchDoor").is_open, "Tür bleibt offen")
	var drops := get_tree().get_nodes_in_group(DropTable.DROP_GROUP).filter(func(n: Node) -> bool: return room.is_ancestor_of(n))
	check_eq(drops.size(), 1, "Liegen gelassener Drop wieder da")
	if drops.size() == 1:
		check_eq(drops[0].position, Vector2(120, 300), "An derselben Stelle")
		check_eq(drops[0].value, 20, "Derselbe Rubin (rot)")
		player.global_position = drops[0].global_position
		await frames(3)
		check_eq(GameState.rupees, 20, "Drop einsammelbar")
		player.global_position = Vector2(64, 96)
		await game.change_room(ROOM2, &"from_test_area")
		await game.change_room(AREA, &"from_room_2")
		await frames(3)
		var left := get_tree().get_nodes_in_group(DropTable.DROP_GROUP).filter(func(n: Node) -> bool: return game.current_room.is_ancestor_of(n))
		check_eq(left.size(), 0, "Eingesammelter Drop kommt nicht wieder")
	game.queue_free()
