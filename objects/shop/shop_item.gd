class_name ShopItem
extends Node2D
## Ware im Laden: liegt mit Preis aus. Davorstellen, hinschauen, "interact" -> Kaufwunsch an den Shop.
## Inhalt ist eine Pickup-Szene oder (bei hint_pages) ein Hinweis des Händlers.

signal buy_requested(item: ShopItem, player: Player)

@export var price: int = 10
## Pickup-Szene, die man bekommt (z. B. res://items/pickups/heart.tscn).
@export var content: PackedScene
## Statt eines Gegenstands: Der Händler sagt diese Seiten (z. B. ein Hinweis).
@export_multiline var hint_pages: Array[String] = []
## Symbol auf der Theke. Leer = Symbol des Inhalts.
@export var icon: Texture2D
## Vorrat. -1 = unbegrenzt. Begrenzter Vorrat bleibt über Raumwechsel erhalten.
@export var stock: int = -1

var remaining: int = -1

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _price_label: Label = $Price


func _ready() -> void:
	remaining = stock
	if owner != null and stock >= 0:
		remaining = GameState.get_value(GameState.flag_id(self), stock)
	_sprite.texture = icon if icon else _content_icon()
	_price_label.text = str(price)
	_update_visibility()
	($InteractZone as InteractZone).interacted.connect(func(player: Player) -> void:
		buy_requested.emit(self, player))


func is_sold_out() -> bool:
	return remaining == 0


## Vom Shop nach einem Kauf aufgerufen.
func mark_sold() -> void:
	if remaining > 0:
		remaining -= 1
		if owner != null:
			GameState.set_value(GameState.flag_id(self), remaining)
	_update_visibility()


func _update_visibility() -> void:
	visible = not is_sold_out()
	($InteractZone as InteractZone).set_deferred("monitoring", not is_sold_out())


func _content_icon() -> Texture2D:
	if content == null:
		return null
	var pickup: Pickup = content.instantiate()
	var texture := pickup.get_icon()
	pickup.free()
	return texture
