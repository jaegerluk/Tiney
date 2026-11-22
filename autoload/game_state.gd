extends Node
## Spielstand: Rubine, Schlüssel pro Dungeon, Merker für dauerhafte Dinge. Autoload "GameState".

signal rupees_changed(amount: int)
signal keys_changed(dungeon: StringName, amount: int)
signal dungeon_changed(dungeon: StringName)

const MAX_RUPEES := 999

var rupees: int = 0
## Dungeon des aktuellen Raums. Bestimmt, welche Schlüssel zählen.
var current_dungeon: StringName = &"":
	set(value):
		current_dungeon = value
		dungeon_changed.emit(value)
		keys_changed.emit(value, keys())

var _keys: Dictionary[StringName, int] = {}
var _flags: Dictionary[String, bool] = {}


func reset() -> void:
	rupees = 0
	_keys.clear()
	_flags.clear()
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


func set_flag(id: String) -> void:
	_flags[id] = true


func has_flag(id: String) -> bool:
	return _flags.has(id)


## Eindeutige ID für einen Knoten in einer Raumszene: "<Szenenpfad>:<Pfad im Raum>".
## Der Knoten muss Teil einer gespeicherten Szene sein (owner gesetzt).
func flag_id(node: Node) -> String:
	var room := node.owner if node.owner else node
	return "%s:%s" % [room.scene_file_path, room.get_path_to(node)]


func _dungeon_or_current(dungeon: StringName) -> StringName:
	return dungeon if dungeon != &"" else current_dungeon
