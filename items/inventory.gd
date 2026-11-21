class_name Inventory
extends Resource
## Inventar aus festen Slots. Meldet jede Änderung über das eingebaute Signal `changed`.

@export var slots: Array[InventorySlot] = []


## Legt einen Gegenstand ab. Gleiche Gegenstände werden gestapelt.
## Gibt false zurück, wenn kein Platz mehr frei ist.
func insert(item: Item) -> bool:
	var target: InventorySlot = null
	for slot in slots:
		if slot.item == item:
			target = slot
			break
	if target == null:
		for slot in slots:
			if slot.is_empty():
				target = slot
				target.item = item
				break
	if target == null:
		return false
	target.amount += 1
	emit_changed()
	return true
