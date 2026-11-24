class_name TorchGroup
extends Node2D
## Fasst Torch-Kinder zusammen: sendet toggled(true), sobald alle brennen, und toggled(false),
## sobald eine ausgeht. Z. B. mit SwitchDoor.set_open verbinden.

signal toggled(all_lit: bool)

var all_lit: bool = false


func _ready() -> void:
	for torch in _torches():
		torch.toggled.connect(func(_lit: bool) -> void: _check())
	_check.call_deferred()


func _torches() -> Array[Torch]:
	var result: Array[Torch] = []
	for child in get_children():
		if child is Torch:
			result.append(child)
	return result


func _check() -> void:
	var torches := _torches()
	var now := not torches.is_empty() and torches.all(func(t: Torch) -> bool: return t.is_lit())
	if now != all_lit:
		all_lit = now
		toggled.emit(all_lit)
