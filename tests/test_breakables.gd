extends TestCase
## Krüge und Gras: Schwert zerstört sie, Drops kommen aus der DropTable, nach Raumwechsel wieder da.

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	# DropTable: Verteilung mit festem Seed
	seed(1234)
	var pot_drops: DropTable = load("res://items/drops/pot_drops.tres")
	var counts := {}
	for i in 1000:
		var scene := pot_drops.roll()
		var key := scene.resource_path.get_file() if scene else "nichts"
		counts[key] = counts.get(key, 0) + 1
	print("  Krug-Drops bei 1000 Würfen: ", counts)
	check(counts.get("nichts", 0) > 300 and counts.get("nichts", 0) < 500, "Etwa 40 % nichts")
	check(counts.has("rupee.tscn") and counts.has("rupee_blue.tscn") and counts.has("heart.tscn"), "Alle Drop-Arten kommen vor")

	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var room := game.current_room

	# Krug mit garantiertem Drop: blauer Rubin
	var pot: Breakable = room.get_node("Pot2")
	var sure := DropTable.new()
	var entry := DropEntry.new()
	entry.scene = load("res://items/pickups/rupee_blue.tscn")
	sure.entries = [entry]
	sure.nothing_weight = 0.0
	pot.drop_table = sure
	player.global_position = pot.global_position + Vector2(0, 18)
	player.face(Vector2.UP)
	await frames(2)
	await tap("attack")
	await frames(30)
	check(not is_instance_valid(pot), "Krug zerstört")
	var drop := room.get_node_or_null("RupeeBlue")
	check(drop != null, "Blauer Rubin fällt heraus")
	if drop:
		player.global_position = drop.global_position
		await frames(3)
		check_eq(GameState.rupees, 5, "Gedroppter Rubin einsammelbar")

	# Gras
	var grass: Breakable = room.get_node("Grass1")
	player.global_position = grass.global_position + Vector2(-16, 0)
	player.face(Vector2.RIGHT)
	await frames(2)
	await tap("attack")
	await frames(30)
	check(not is_instance_valid(grass), "Gras geschnitten")
	check(room.has_node("Grass2"), "Nachbargras steht noch")

	# Ohne Schwert blockieren Krüge den Weg
	var pot1: Breakable = room.get_node("Pot1")
	player.global_position = pot1.global_position + Vector2(0, 20)
	hold("move_up")
	await frames(30)
	hold("move_up", false)
	check(player.global_position.y > pot1.global_position.y + 6, "Krug blockiert")

	# Raumwechsel: alles wieder da
	await game.change_room(ROOM2, &"from_test_area")
	await game.change_room(AREA, &"from_room_2")
	await frames(2)
	check(game.current_room.has_node("Pot2") and game.current_room.has_node("Grass1"), "Krug und Gras erscheinen wieder")
	game.queue_free()
