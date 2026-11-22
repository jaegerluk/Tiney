class_name RupeePickup
extends Pickup
## Rubin. Wert 1 = grün, 5 = blau, 20 = rot.

const TEXTURES := {
	1: preload("res://assets/sprites/pickups/rupee_green.png"),
	5: preload("res://assets/sprites/pickups/rupee_blue.png"),
	20: preload("res://assets/sprites/pickups/rupee_red.png"),
}

@export_enum("Grün (1):1", "Blau (5):5", "Rot (20):20") var value: int = 1:
	set(new_value):
		value = new_value
		if is_node_ready():
			_update_sprite()

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_update_sprite()
	super()


func _apply(_player: Player) -> bool:
	GameState.add_rupees(value)
	return true


func get_icon() -> Texture2D:
	return TEXTURES.get(value, TEXTURES[1])


func _update_sprite() -> void:
	_sprite.texture = TEXTURES.get(value, TEXTURES[1])
