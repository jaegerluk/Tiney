class_name InventoryUI
extends Control
## Inventar-Raster. Die Aktion "menu" öffnet und schließt es, solange es offen ist, pausiert das Spiel.

@export var inventory: Inventory

@onready var _slot_views: Array[Node] = %Grid.get_children()


func _ready() -> void:
	visible = false
	if inventory:
		inventory.changed.connect(_refresh)
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if not visible and get_tree().paused:
			return
		visible = not visible
		get_tree().paused = visible
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for i in mini(inventory.slots.size(), _slot_views.size()):
		(_slot_views[i] as InventorySlotUI).show_slot(inventory.slots[i])
