class_name InventorySlot
extends Resource
## Ein Platz im Inventar: ein Gegenstand und seine Anzahl.

@export var item: Item
@export var amount: int = 0


func is_empty() -> bool:
	return item == null
