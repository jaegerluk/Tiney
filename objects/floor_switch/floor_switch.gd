class_name FloorSwitch
extends Area2D
## Bodenschalter. Jedes Betreten durch den Spieler schaltet um.
## Kennt keine Tür: Die Elternszene verbindet `toggled` mit dem Ziel, z. B. SwitchDoor.set_open.
## Der Zustand bleibt über Raumwechsel erhalten; beim Laden wird `toggled` erneut gesendet.

signal toggled(is_on: bool)

@export var is_on: bool = false

@onready var _sprite_off: Sprite2D = $SpriteOff
@onready var _sprite_on: Sprite2D = $SpriteOn


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if owner != null:
		var saved: Variant = GameState.get_value(GameState.flag_id(self))
		if saved != null and saved != is_on:
			is_on = saved
			toggled.emit(is_on)
	_update_sprites()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		is_on = not is_on
		if owner != null:
			GameState.set_value(GameState.flag_id(self), is_on)
		_update_sprites()
		toggled.emit(is_on)


func _update_sprites() -> void:
	_sprite_off.visible = not is_on
	_sprite_on.visible = is_on
