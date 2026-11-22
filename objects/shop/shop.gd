class_name Shop
extends Node2D
## Laden: verwaltet die ShopItem-Kinder (Preis, Rubine, Vorrat) und spricht als Händler.
## Meldungen und Hochhalten laufen wie bei Truhen über Room an Game.

signal dialog_requested(pages: Array, speaker: String, portrait: Texture2D)
signal item_presented(icon: Texture2D, message: String)

@export var seller_name: String = "Händler"
@export var seller_portrait: Texture2D
## %d wird durch den Preis ersetzt.
@export_multiline var too_expensive_text: String = "Das kostet %d Rubine. Komm wieder, wenn du genug hast."
@export_multiline var cannot_carry_text: String = "Du kannst nichts mehr tragen."


func _ready() -> void:
	for child in get_children():
		if child is ShopItem:
			(child as ShopItem).buy_requested.connect(_on_buy_requested)


func _on_buy_requested(item: ShopItem, player: Player) -> void:
	if item.is_sold_out():
		return
	if GameState.rupees < item.price:
		_say([too_expensive_text % item.price])
		return
	if not item.hint_pages.is_empty():
		GameState.spend_rupees(item.price)
		item.mark_sold()
		_say(item.hint_pages)
		return
	if item.content == null:
		return
	var pickup: Pickup = item.content.instantiate()
	if not pickup._apply(player):
		pickup.free()
		_say([cannot_carry_text])
		return
	GameState.spend_rupees(item.price)
	item.mark_sold()
	item_presented.emit(pickup.get_icon(), pickup.get_message())
	pickup.free()


func _say(pages: Array) -> void:
	dialog_requested.emit(pages, seller_name, seller_portrait)
