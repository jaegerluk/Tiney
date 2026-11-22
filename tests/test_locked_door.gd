extends TestCase
## Schlüsseltür: ohne Schlüssel zu, mit Schlüssel auf, bleibt nach Raumwechsel offen.

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	await game.change_room(ROOM2, &"from_test_area")

	# Ohne Schlüssel gegen die Tür laufen
	player.global_position = Vector2(128, 96)
	await _push_down(30)
	check(game.current_room.has_node("LockedDoor"), "Ohne Schlüssel bleibt die Tür zu")
	check(player.global_position.y < 112, "Tür blockiert den Weg")

	# Schlüssel eines anderen Dungeons zählt nicht
	GameState.add_key(&"dungeon_1")
	await _push_down(20)
	check(game.current_room.has_node("LockedDoor"), "Schlüssel aus anderem Dungeon öffnet nicht")

	# Mit Schlüssel dieses Dungeons
	GameState.add_key()
	await _push_down(5)
	check_eq(GameState.keys(), 0, "Schlüssel verbraucht")
	await frames(30)
	check(not game.current_room.has_node("LockedDoor"), "Tür geöffnet")
	await _push_down(40)
	check(player.global_position.y > 150, "Spieler kommt durch")

	# Raum verlassen und zurück: Tür bleibt offen
	await game.change_room(AREA, &"from_room_2")
	await game.change_room(ROOM2, &"from_test_area")
	await frames(2)
	check(not game.current_room.has_node("LockedDoor"), "Tür bleibt nach Raumwechsel offen")
	game.queue_free()


func _push_down(count: int) -> void:
	hold("move_down")
	await frames(count)
	hold("move_down", false)
