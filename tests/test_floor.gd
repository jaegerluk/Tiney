extends TestCase
## Steinboden: Die TileMapLayer beider Testräume ist vollständig gefüllt.


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
