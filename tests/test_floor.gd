extends TestCase
## Boden und Wände als Tiles: Boden vollständig, Wände blockieren.


func run() -> void:
	for entry in [["res://world/test_area/test_area.tscn", 32, 28], ["res://world/test_area/test_room_2.tscn", 16, 14]]:
		var room: Room = load(entry[0]).instantiate()
		var floor_layer: TileMapLayer = room.get_node("Floor")
		var cells := floor_layer.get_used_cells()
		check_eq(cells.size(), entry[1] * entry[2], "%s: alle Bodenzellen gesetzt" % room.name)
		check_eq(floor_layer.get_used_rect(), Rect2i(0, 0, entry[1], entry[2]), "%s: Boden deckt den Raum ab" % room.name)
		var variants := {}
		for cell in cells:
			variants[floor_layer.get_cell_atlas_coords(cell)] = true
		check(variants.size() >= 3, "%s: mehrere Varianten (%d)" % [room.name, variants.size()])
		check(floor_layer.tile_set.get_source(0).has_tile(Vector2i(3, 0)), "TileSet hat 4 Varianten")
		room.free()

	# Wände: Tiles mit Kollision blockieren den Spieler
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var walls: TileMapLayer = game.current_room.get_node("Walls")
	check(walls.get_used_cells().size() > 100, "Wände als Tiles gemalt")
	check(walls.tile_set.get_physics_layer_collision_layer(0) == 1, "Wand-Tiles auf Ebene world")
	var player: Player = game.get_node("Player")
	player.global_position = Vector2(40, 96)
	hold("move_left")
	await frames(40)
	hold("move_left", false)
	check(player.global_position.x >= 16 + 5, "Linke Wand blockiert (x=%d)" % player.global_position.x)
	player.global_position = Vector2(200, 300)
	hold("move_right")
	await frames(60)
	hold("move_right", false)
	check(player.global_position.x <= 240 - 5, "Trennwand blockiert (x=%d)" % player.global_position.x)
	game.queue_free()
