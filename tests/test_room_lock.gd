extends TestCase
## Verschlusstüren: zu nach dem Betreten, auf nach dem letzten Gegner, bleiben danach offen.

const ARENA := "res://world/test_area/test_arena.tscn"
const AREA := "res://world/test_area/test_area.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")

	# Durch die Ostöffnung (rechte Hälfte, unten) in den Kampfraum
	player.global_position = Vector2(480, 368)
	hold("move_right")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestArena":
			break
	hold("move_right", false)
	await frames(15)
	check_eq(game.current_room.name, &"TestArena", "Ostöffnung führt in den Kampfraum")
	var lock: RoomLock = game.current_room.get_node("RoomLock")
	var door: ShutterDoor = lock.get_node("ShutterDoor")
	check(door.is_open, "Tür zuerst offen")
	await frames(40)
	check(lock.is_locked and not door.is_open, "Tür fällt nach dem Betreten zu")

	# Gegner nacheinander besiegen
	var hit := Hitbox.new()
	hit.damage = 99
	for name in ["Zombie", "Slime1"]:
		var enemy: Enemy = game.current_room.get_node(name)
		enemy.drop_table = null
		enemy._on_hurt(hit)
	await frames(2)
	check(not door.is_open, "Noch ein Gegner übrig: Tür bleibt zu")
	var last: Enemy = game.current_room.get_node("Slime2")
	last.drop_table = null
	last._on_hurt(hit)
	hit.free()
	await frames(2)
	check(door.is_open and not lock.is_locked, "Letzter Gegner besiegt: Tür geht auf")

	# Raus und wieder rein: bleibt offen
	await game.change_room(AREA, &"from_arena")
	await game.change_room(ARENA, &"from_test_area")
	await frames(60)
	lock = game.current_room.get_node("RoomLock")
	check((lock.get_node("ShutterDoor") as ShutterDoor).is_open and not lock.is_locked, "Gesäuberter Raum bleibt offen")
	game.queue_free()
