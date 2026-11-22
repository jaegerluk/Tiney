class_name RoomLock
extends Node2D
## Verschluss eines Raums: Die ShutterDoor-Kinder schließen kurz nach dem Betreten
## und öffnen sich, wenn alle Gegner besiegt sind. Danach bleiben sie offen (Merker).

signal locked
signal unlocked

## Gegner, die besiegt werden müssen. Leer = alle Gegner im Raum.
@export var enemies: Array[Enemy] = []
## Sekunden nach dem Betreten, bis die Türen zufallen.
@export var close_delay: float = 0.4

var is_locked: bool = false
var _remaining: Array[Enemy] = []


func _ready() -> void:
	if GameState.is_gone(self):
		_set_doors(true)
		return
	await get_tree().process_frame
	_remaining = _collect_enemies()
	if _remaining.is_empty():
		_clear()
		return
	for enemy in _remaining:
		enemy.died.connect(_on_enemy_died.bind(enemy))
	await get_tree().create_timer(close_delay, false).timeout
	while _doors().any(func(d: ShutterDoor) -> bool: return d.is_blocked()):
		await get_tree().create_timer(0.1, false).timeout
	if not _remaining.is_empty():
		is_locked = true
		_set_doors(false)
		locked.emit()


func _collect_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	var candidates: Array = enemies if not enemies.is_empty() else _all_enemies(owner if owner else get_parent())
	for node in candidates:
		var enemy := node as Enemy
		if enemy and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_dead():
			result.append(enemy)
	return result


func _all_enemies(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is Enemy:
			found.append(child)
		found.append_array(_all_enemies(child))
	return found


func _on_enemy_died(enemy: Enemy) -> void:
	_remaining.erase(enemy)
	if _remaining.is_empty():
		_clear()


func _clear() -> void:
	GameState.mark_gone(self)
	is_locked = false
	_set_doors(true)
	unlocked.emit()


func _doors() -> Array[ShutterDoor]:
	var result: Array[ShutterDoor] = []
	for child in get_children():
		if child is ShutterDoor:
			result.append(child)
	return result


func _set_doors(open: bool) -> void:
	for door in _doors():
		door.is_open = open
