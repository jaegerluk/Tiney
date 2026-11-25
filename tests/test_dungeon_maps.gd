extends TestCase
## Prüft die Kartendaten aller Dungeons (jeder Ordner unter world/ mit Räumen, die eine dungeon_id haben):
## - alle Räume eines Ordners gehören zum selben Dungeon
## - keine Überlappung auf einem Stockwerk
## - jeder Ausgang führt zu einem existierenden Raum und Eingang
## - Ausgänge an einer Wand führen (auf demselben Stockwerk) in den Raum direkt daneben
## - Gegenüberliegende Durchgänge liegen an derselben Stelle der gemeinsamen Wand
## - Treppen liegen auf beiden Stockwerken an derselben Stelle


func run() -> void:
	DungeonMap.clear_cache()
	var folders: Array[String] = []
	_collect_folders("res://world", folders)
	var checked := 0
	for folder in folders:
		var map := DungeonMap.new(folder)
		if map.dungeon_id == &"":
			continue
		checked += 1
		_check_map(map)
	check(checked >= 1, "Mindestens ein Dungeon geprüft (%d)" % checked)

	# Testbereich: ein paar feste Erwartungen
	var test_map := DungeonMap.for_room("res://world/test_area/test_area.tscn")
	var area := test_map.room("res://world/test_area/test_area.tscn")
	check_eq(area.size, Vector2i(2, 2), "Startraum ist 2×2 Bildschirme")
	check_eq(area.walls.size(), 2, "Startraum: Innenwand mit einer Lücke (zwei Wandstücke)")
	check_eq(test_map.floors(), [-1, 0] as Array[int], "Stockwerke B1 und 1F")
	var kinds := {}
	for data in test_map.rooms:
		for m in data.markers:
			kinds[m.kind] = kinds.get(m.kind, 0) + 1
	check(kinds.get(DungeonMap.Marker.CHEST, 0) >= 3, "Truhen gefunden")
	check(kinds.get(DungeonMap.Marker.KEY_DOOR, 0) >= 1, "Schlüsseltür gefunden")
	check_eq(kinds.get(DungeonMap.Marker.BOSS_DOOR, 0), 1, "Bosstür gefunden")
	check_eq(kinds.get(DungeonMap.Marker.BOSS, 0), 1, "Boss gefunden")
	check(kinds.get(DungeonMap.Marker.SAVE, 0) >= 1, "Speicherstatue gefunden")
	check(kinds.get(DungeonMap.Marker.STAIRS, 0) >= 2, "Treppen gefunden")


func _check_map(map: DungeonMap) -> void:
	var name := map.folder.get_file()
	for data in map.rooms:
		check_eq(data.dungeon, map.dungeon_id, "%s: Raum %s gehört zum Dungeon" % [name, data.path.get_file()])
	# Überlappung
	for i in map.rooms.size():
		for j in range(i + 1, map.rooms.size()):
			var a: Dictionary = map.rooms[i]
			var b: Dictionary = map.rooms[j]
			if a.floor == b.floor and Rect2i(a.cell, a.size).intersects(Rect2i(b.cell, b.size)):
				check(false, "%s: %s und %s überlappen auf der Karte" % [name, a.path.get_file(), b.path.get_file()])
	# Ausgänge
	for data in map.rooms:
		for exit in data.exits:
			var label := "%s: Ausgang in %s bei %s" % [name, data.path.get_file(), exit.pos]
			if not ResourceLoader.exists(exit.target):
				check(false, label + " → Zielraum fehlt (%s)" % exit.target)
				continue
			var target := map.room(exit.target)
			if target.is_empty():
				continue  # führt aus dem Dungeon hinaus
			if not target.entries.has(exit.entry):
				check(false, label + " → Eingang '%s' fehlt in %s" % [exit.entry, exit.target.get_file()])
			if exit.stairs:
				_check_stairs(map, data, exit, target, label)
			if exit.side == Vector2i.ZERO or target.floor != data.floor:
				continue
			var cell: Vector2i = map.cell_at(data.path, exit.pos) + exit.side
			if not Rect2i(target.cell, target.size).has_point(cell):
				check(false, label + " → %s liegt auf der Karte nicht daneben (erwartet Zelle %s)" % [exit.target.get_file(), cell])
			for back in target.exits:
				if back.target == data.path and back.side == -exit.side:
					var here := _global(data, exit.pos)
					var there := _global(target, back.pos)
					var along := absf(here.y - there.y) if exit.side.x != 0 else absf(here.x - there.x)
					if along > 8.0:
						check(false, label + " → Gegenstück in %s liegt %d px versetzt" % [exit.target.get_file(), along])


## Treppen: Die Gegentreppe im Zielraum liegt auf der Karte an derselben Stelle.
func _check_stairs(map: DungeonMap, data: Dictionary, exit: Dictionary, target: Dictionary, label: String) -> void:
	for back in target.exits:
		if back.stairs and back.target == data.path:
			var offset := _global(data, exit.pos) - _global(target, back.pos)
			if offset.length() > 8.0:
				check(false, label + " → Treppe in %s liegt an anderer Stelle (Versatz %s)" % [exit.target.get_file(), offset])
			return


func _global(data: Dictionary, pos: Vector2) -> Vector2:
	return Vector2(data.cell) * DungeonMap.SCREEN + pos


func _collect_folders(folder: String, out: Array[String]) -> void:
	out.append(folder)
	for sub in DirAccess.get_directories_at(folder):
		_collect_folders(folder.path_join(sub), out)
