class_name DropTable
extends Resource
## Zufälliger Drop aus gewichteten Einträgen. `nothing_weight` ist das Gewicht für „kein Drop“.

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
	var scene := roll()
	if scene == null or parent == null:
		return
	var drop: Node2D = scene.instantiate()
	drop.position = position
	parent.add_child.call_deferred(drop)
