class_name InteractZone
extends Area2D
## Bereich vor einem Objekt: Steht der Spieler darin, schaut passend und drückt "interact",
## wird `interacted` gesendet. Kind eines Objekts (Truhe, Schild, NPC, Shop-Ware …).

signal interacted(player: Player)

enum FacingRule {
	## Spieler muss zum Elternobjekt schauen (von jeder Seite).
	TOWARD_PARENT,
	## Spieler muss nach oben schauen (z. B. Schild, Statue).
	UP,
}

@export var facing_rule: FacingRule = FacingRule.TOWARD_PARENT

var _player: Player = null


func _init() -> void:
	collision_layer = 32
	collision_mask = 2
	monitorable = false


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			_player = body)
	body_exited.connect(func(body: Node2D) -> void:
		if body == _player:
			_player = null)


func has_player() -> bool:
	return _player != null


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not event.is_action_pressed("interact") or not _facing_ok():
		return
	get_viewport().set_input_as_handled()
	interacted.emit(_player)


func _facing_ok() -> bool:
	if facing_rule == FacingRule.UP:
		return _player.facing == Vector2.UP
	var to_parent := (get_parent() as Node2D).global_position - _player.global_position
	var direction := Vector2(signf(to_parent.x), 0.0) if absf(to_parent.x) > absf(to_parent.y) else Vector2(0.0, signf(to_parent.y))
	return _player.facing == direction
