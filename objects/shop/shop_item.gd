class_name ShopItem
extends Node2D
## Ware im Laden: liegt mit Preis aus. Davorstellen, hinschauen, "interact" -> Kaufwunsch an den Shop.
## Inhalt ist eine Pickup-Szene oder (bei hint_pages) ein Hinweis des Händlers.

signal buy_requested(item: ShopItem, player: Player)
## Beschreibung anzeigen bzw. ausblenden, solange der Spieler vor der Ware steht.
signal info_shown(text: String)
signal info_hidden

## Name und Beschreibung für die Info-Box beim Davorstehen.
@export var item_name: String = ""
@export_multiline var description: String = ""

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
	var zone := $InteractZone as InteractZone
	zone.interacted.connect(func(player: Player) -> void:
		buy_requested.emit(self, player))
	zone.player_entered.connect(func(_player: Player) -> void:
		if not is_sold_out():
			info_shown.emit(info_text()))
	zone.player_exited.connect(func(_player: Player) -> void:
		info_hidden.emit())


## Text für die Info-Box: Name, Preis, Beschreibung.
func info_text() -> String:
	var cost := "1 rupee" if price == 1 else "%d rupees" % price
	var title := "%s – %s" % [item_name, cost] if item_name != "" else cost
	return title + ("\n" + description if description != "" else "")


func is_sold_out() -> bool:
	return remaining == 0


## Vom Shop nach einem Kauf aufgerufen.
func mark_sold() -> void:
	if remaining > 0:
		remaining -= 1
		if owner != null:
			GameState.set_value(GameState.flag_id(self), remaining)
	_update_visibility()
	if is_sold_out():
		info_hidden.emit()


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
