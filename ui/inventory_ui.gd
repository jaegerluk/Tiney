class_name InventoryUI
extends Control
## Inventar-Raster. "menu" öffnet/schließt es (Spiel pausiert, solange es offen ist).
## Mit den Bewegungstasten wählt man ein Item aus; "use_item" setzt es im Spiel ein.

@export var inventory: Inventory
@export var columns: int = 4

var _cursor_index: int = 0

@onready var _slot_views: Array[Node] = %Grid.get_children()
@onready var _cursor: Control = %Cursor
@onready var _item_name: Label = %ItemName


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
		if visible:
			_cursor_index = maxi(inventory.selected, 0)
			_update_cursor()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	var step := 0
	if event.is_action_pressed("move_left"):
		step = -1
	elif event.is_action_pressed("move_right"):
		step = 1
	elif event.is_action_pressed("move_up"):
		step = -columns
	elif event.is_action_pressed("move_down"):
		step = columns
	if step != 0:
		_cursor_index = posmod(_cursor_index + step, _slot_views.size())
		_update_cursor()
		get_viewport().set_input_as_handled()


func _update_cursor() -> void:
	var slot := _slot_views[_cursor_index] as Control
	_cursor.global_position = slot.global_position - Vector2(1, 1)
	inventory.select(_cursor_index)


func _refresh() -> void:
	for i in mini(inventory.slots.size(), _slot_views.size()):
		(_slot_views[i] as InventorySlotUI).show_slot(inventory.slots[i])
	var item := inventory.selected_item()
	_item_name.text = item.name if item else ""
