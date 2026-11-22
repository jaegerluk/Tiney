class_name Inventory
extends Resource
## Inventar aus festen Slots. Meldet jede Änderung über das eingebaute Signal `changed`.

@export var slots: Array[InventorySlot] = []
## Ausgewählter Slot für "use_item" (-1 = keiner).
@export var selected: int = -1


## Inhalt als Liste [[item, amount], ...] für Spielstände.
func snapshot() -> Array:
	var data: Array = []
	for slot in slots:
		data.append([slot.item, slot.amount])
	data.append(selected)
	return data


func restore(data: Array) -> void:
	for i in mini(slots.size(), data.size()):
		if data[i] is Array:
			slots[i].item = data[i][0]
			slots[i].amount = data[i][1]
	selected = data[-1] if not data.is_empty() and data[-1] is int else -1
	emit_changed()


func select(index: int) -> void:
	selected = clampi(index, -1, slots.size() - 1)
	emit_changed()


func selected_item() -> Item:
	if selected < 0 or selected >= slots.size():
		return null
	return slots[selected].item


## Benutzt das ausgewählte Item. Verbrauchbare Items werden abgezogen. false = nichts passiert.
func use_selected(player: Player) -> bool:
	var item := selected_item()
	if item == null or not item.use(player):
		return false
	if item.consumable:
		var slot := slots[selected]
		slot.amount -= 1
		if slot.amount <= 0:
			slot.item = null
			slot.amount = 0
	emit_changed()
	return true


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
