class_name Chest
extends StaticBody2D
## Truhe mit festem Inhalt (eine Pickup-Szene). Öffnen: daneben stehen, zur Truhe schauen, "interact".
## Bleibt offen (Zustand in GameState). Den Inhalt zeigt Game: Der Held hält ihn hoch, dazu eine Meldung.

signal item_presented(icon: Texture2D, message: String)

## Pickup-Szene, z. B. res://items/pickups/big_key.tscn. Leer = leere Truhe.
@export var content: PackedScene

var is_open: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if owner != null and GameState.get_value(GameState.flag_id(self), false):
		is_open = true
	_sprite.frame = 1 if is_open else 0
	($InteractZone as InteractZone).interacted.connect(open)


func open(player: Player) -> void:
	if is_open:
		return
	is_open = true
	_sprite.frame = 1
	if owner != null:
		GameState.set_value(GameState.flag_id(self), true)
	if content == null:
		item_presented.emit(null, "Die Truhe ist leer.")
		return
	var pickup: Pickup = content.instantiate()
	pickup._apply(player)
	item_presented.emit(pickup.get_icon(), pickup.get_message())
	pickup.free()

