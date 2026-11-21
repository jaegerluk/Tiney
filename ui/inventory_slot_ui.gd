class_name InventorySlotUI
extends Control
## Zeigt einen Inventar-Slot: Symbol und Anzahl (ab 2).

@onready var _icon: TextureRect = %Icon
@onready var _amount: Label = %Amount


func show_slot(slot: InventorySlot) -> void:
	var has_item := slot != null and not slot.is_empty()
	_icon.visible = has_item
	_icon.texture = slot.item.texture if has_item else null
	_amount.visible = has_item and slot.amount > 1
	_amount.text = str(slot.amount) if has_item else ""
