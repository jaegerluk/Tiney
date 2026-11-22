class_name DropTable
extends Resource
## Zufälliger Drop aus gewichteten Einträgen. `nothing_weight` ist das Gewicht für „kein Drop“.

## Gruppe aller zur Laufzeit gedroppten Objekte. Game sichert sie beim Verlassen eines Raums.
const DROP_GROUP := &"room_drops"

@export var entries: Array[DropEntry] = []
@export var nothing_weight: float = 1.0


## Würfelt einen Drop aus. null = nichts.
func roll() -> PackedScene:
	var total := nothing_weight
	for entry in entries:
		total += entry.weight
	var pick := randf() * total
	for entry in entries:
		if pick < entry.weight:
			return entry.scene
		pick -= entry.weight
	return null


## Würfelt und setzt den Drop (falls einer kommt) an `position` in `parent`. Sicher in Physik-Callbacks.
func spawn(parent: Node, position: Vector2) -> void:
	spawn_scene(roll(), parent, position)


## Setzt eine Drop-Szene in einen Raum. Sicher in Physik-Callbacks. null = nichts.
static func spawn_scene(scene: PackedScene, parent: Node, position: Vector2) -> void:
	if scene == null or parent == null:
		return
	var drop: Node2D = scene.instantiate()
	drop.position = position
	drop.add_to_group(DROP_GROUP)
	parent.add_child.call_deferred(drop)
