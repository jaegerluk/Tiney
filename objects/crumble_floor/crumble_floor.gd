class_name CrumbleFloor
extends Node2D
## Bröckelnde Bodenplatte (ein Tile). Betritt der Spieler sie, zerfällt sie nach `delay` zu einem Loch.
## Sie zählt nicht als sicherer Boden (nach einem Sturz landet man davor).
## Beim nächsten Betreten des Raums ist sie wieder ganz; mit regrow_time > 0 schon vorher.
## Mit target_room fällt man durch das Loch in einen anderen Raum (wie bei Pit).

@export var delay: float = 0.5
## Sekunden, bis sie von selbst wieder ganz ist. 0 = erst beim nächsten Betreten des Raums.
@export var regrow_time: float = 0.0
@export_file("*.tscn") var target_room: String = ""
@export var target_entry: StringName = &""

var is_broken: bool = false
var _triggered: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _pit: Pit = $Pit


func _ready() -> void:
	_pit.target_room = target_room
	_pit.target_entry = target_entry
	_set_pit_active(false)
	var trigger: Area2D = $Trigger
	trigger.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			(body as Player).hazard_entered()
			if not _triggered and not is_broken:
				_crumble())
	trigger.body_exited.connect(func(body: Node2D) -> void:
		if body is Player:
			(body as Player).hazard_exited())


func _crumble() -> void:
	_triggered = true
	_sprite.frame = 1
	var tween := create_tween()
	for i in 4:
		tween.tween_property(_sprite, "offset:x", 1.0, delay / 8.0)
		tween.tween_property(_sprite, "offset:x", -1.0, delay / 8.0)
	await tween.finished
	_sprite.offset.x = 0.0
	is_broken = true
	_sprite.visible = false
	_set_pit_active(true)
	if regrow_time > 0.0:
		await get_tree().create_timer(regrow_time, false).timeout
		_regrow()


func _regrow() -> void:
	is_broken = false
	_triggered = false
	_sprite.frame = 0
	_sprite.visible = true
	_set_pit_active(false)


func _set_pit_active(active: bool) -> void:
	_pit.visible = active
	_pit.set_deferred("monitoring", active)
