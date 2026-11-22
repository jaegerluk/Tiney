class_name ItemPickup
extends Pickup
## Gegenstand fürs Inventar.

@export var item: Item:
	set(value):
		item = value
		if is_node_ready():
			_update_sprite()

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_update_sprite()
	super()


func _apply(player: Player) -> bool:
	return item != null and player.collect(item)


func get_icon() -> Texture2D:
	return item.texture if item else null


func get_message() -> String:
	return "You got: %s" % item.name if item else ""


func _update_sprite() -> void:
	_sprite.texture = item.texture if item else null
