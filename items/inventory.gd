class_name Inventory
extends Resource
## Inventar aus festen Slots. Meldet jede Änderung über das eingebaute Signal `changed`.

@export var slots: Array[InventorySlot] = []


## Inhalt als Liste [[item, amount], ...] für Spielstände.
func snapshot() -> Array:
	var data: Array = []
	for slot in slots:
		data.append([slot.item, slot.amount])
	return data


func restore(data: Array) -> void:
	for i in mini(slots.size(), data.size()):
		slots[i].item = data[i][0]
		slots[i].amount = data[i][1]
	emit_changed()


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
