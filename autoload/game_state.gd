extends Node
## Spielstand: Rubine, Schlüssel pro Dungeon, Merker für dauerhafte Dinge. Autoload "GameState".

signal rupees_changed(amount: int)
signal keys_changed(dungeon: StringName, amount: int)
signal big_keys_changed(dungeon: StringName, amount: int)
signal dungeon_changed(dungeon: StringName)
signal orbs_changed(count: int)

const MAX_RUPEES := 999

var rupees: int = 0
## Dungeon des aktuellen Raums. Bestimmt, welche Schlüssel zählen.
var current_dungeon: StringName = &"":
	set(value):
		current_dungeon = value
		dungeon_changed.emit(value)
		keys_changed.emit(value, keys())
		big_keys_changed.emit(value, big_keys())

var _keys: Dictionary[StringName, int] = {}
## Große Schlüssel pro Dungeon. Werden an der Bosstür verbraucht.
var _big_keys: Dictionary[StringName, int] = {}
## Magische Kugeln (IDs, z. B. der Dungeon). Drei öffnen die große Tür.
var orbs: Array[StringName] = []
var _flags: Dictionary[String, bool] = {}
var _values: Dictionary[String, Variant] = {}
## Liegen gelassene Drops je Raumpfad: [{"scene": Pfad, "position": Vector2}, ...]
var _room_drops: Dictionary[String, Array] = {}


func reset() -> void:
	rupees = 0
	_keys.clear()
	_big_keys.clear()
	orbs.clear()
	_flags.clear()
	_values.clear()
	_room_drops.clear()
	current_dungeon = &""
	rupees_changed.emit(rupees)


func add_rupees(amount: int) -> void:
	rupees = clampi(rupees + amount, 0, MAX_RUPEES)
	rupees_changed.emit(rupees)


## Gibt false zurück (und zieht nichts ab), wenn das Geld nicht reicht.
func spend_rupees(amount: int) -> bool:
	if amount > rupees:
		return false
	add_rupees(-amount)
	return true


## Schlüssel im angegebenen Dungeon, leer = aktueller Dungeon.
func keys(dungeon: StringName = &"") -> int:
	return _keys.get(_dungeon_or_current(dungeon), 0)


func add_key(dungeon: StringName = &"") -> void:
	var d := _dungeon_or_current(dungeon)
	_keys[d] = keys(d) + 1
	keys_changed.emit(d, _keys[d])


## Verbraucht einen Schlüssel. Gibt false zurück, wenn keiner da ist.
func use_key(dungeon: StringName = &"") -> bool:
	var d := _dungeon_or_current(dungeon)
	if keys(d) <= 0:
		return false
	_keys[d] -= 1
	keys_changed.emit(d, _keys[d])
	return true


func big_keys(dungeon: StringName = &"") -> int:
	return _big_keys.get(_dungeon_or_current(dungeon), 0)


func add_big_key(dungeon: StringName = &"") -> void:
	var d := _dungeon_or_current(dungeon)
	_big_keys[d] = big_keys(d) + 1
	big_keys_changed.emit(d, _big_keys[d])


## Verbraucht den großen Schlüssel. Gibt false zurück, wenn keiner da ist.
func use_big_key(dungeon: StringName = &"") -> bool:
	var d := _dungeon_or_current(dungeon)
	if big_keys(d) <= 0:
		return false
	_big_keys[d] -= 1
	big_keys_changed.emit(d, _big_keys[d])
	return true


func add_orb(id: StringName) -> void:
	if not orbs.has(id):
		orbs.append(id)
	orbs_changed.emit(orbs.size())


func set_flag(id: String) -> void:
	_flags[id] = true


func has_flag(id: String) -> bool:
	return _flags.has(id)


## Zustand eines Objekts (z. B. Schalter an/aus).
func set_value(id: String, value: Variant) -> void:
	_values[id] = value


func get_value(id: String, default: Variant = null) -> Variant:
	return _values.get(id, default)


## true, wenn ein im Raum platziertes Objekt schon eingesammelt, zerstört oder getötet wurde.
## Objekte ohne owner (zur Laufzeit erzeugt) sind nie „weg“.
func is_gone(node: Node) -> bool:
	return node.owner != null and has_flag(flag_id(node))


## Merkt sich, dass ein im Raum platziertes Objekt weg ist. Ohne owner passiert nichts.
func mark_gone(node: Node) -> void:
	if node.owner != null:
		set_flag(flag_id(node))


func store_drops(room_path: String, drops: Array) -> void:
	_room_drops[room_path] = drops.duplicate(true)


func get_drops(room_path: String) -> Array:
	return _room_drops.get(room_path, []).duplicate(true)


## Tiefe Kopie des gesamten Stands (für Speicherstatuen).
func snapshot() -> Dictionary:
	return {
		"rupees": rupees,
		"keys": _keys.duplicate(),
		"big_keys": _big_keys.duplicate(),
		"orbs": orbs.duplicate(),
		"flags": _flags.duplicate(),
		"values": _values.duplicate(true),
		"room_drops": _room_drops.duplicate(true),
	}


## Setzt alles auf einen mit snapshot() gemerkten Stand zurück.
func restore(data: Dictionary) -> void:
	rupees = data.rupees
	_keys.assign(data["keys"])
	_big_keys.assign(data.get("big_keys", {}))
	orbs.assign(data.get("orbs", []))
	orbs_changed.emit(orbs.size())
	_flags.assign(data.flags)
	_values.assign(data["values"].duplicate(true))
	_room_drops.assign(data.room_drops.duplicate(true))
	rupees_changed.emit(rupees)
	keys_changed.emit(current_dungeon, keys())
	big_keys_changed.emit(current_dungeon, big_keys())


## Eindeutige ID für einen Knoten in einer Raumszene: "<Szenenpfad>:<Pfad im Raum>".
## Der Knoten muss Teil einer gespeicherten Szene sein (owner gesetzt).
func flag_id(node: Node) -> String:
	var room := node.owner if node.owner else node
	return "%s:%s" % [room.scene_file_path, room.get_path_to(node)]


func _dungeon_or_current(dungeon: StringName) -> StringName:
	return dungeon if dungeon != &"" else current_dungeon
