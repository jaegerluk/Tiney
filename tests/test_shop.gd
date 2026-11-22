extends TestCase
## Shop: zu teuer, Kauf zieht Rubine ab, Hinweis als Dialog, Item ins Inventar, Vorrat, Ladenbesitzer.

const SHOP := "res://world/test_area/test_shop.tscn"
const AREA := "res://world/test_area/test_area.tscn"

var game: Game
var player: Player
var box: DialogBox


func run() -> void:
	game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	player = game.get_node("Player")
	box = game.get_node("HUD/DialogBox")
	for slot in player.inventory.slots:
		slot.item = null
		slot.amount = 0

	# Durch die neue Nordöffnung in den Shop
	player.global_position = Vector2(80, 30)
	hold("move_up")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestShop":
			break
	hold("move_up", false)
	await frames(20)
	check_eq(game.current_room.name, &"TestShop", "Nordöffnung führt in den Shop")

	# Davorstehen zeigt die Beschreibung
	var potion_item: ShopItem = game.current_room.get_node("Shop/Potion")
	player.global_position = potion_item.global_position + Vector2(0, 12)
	player.face(Vector2.UP)
	await frames(3)
	var hud: HUD = game.get_node("HUD")
	check(hud.get_node("%InfoBox").visible, "Beschreibung beim Davorstehen")
	check(hud.get_node("%InfoLabel").text.begins_with("Heiltrank – 30 Rubine"), "Name und Preis in der Beschreibung")
	check(not get_tree().paused, "Spiel läuft dabei weiter")
	player.global_position = Vector2(128, 170)
	await frames(3)
	check(not hud.get_node("%InfoBox").visible, "Weggehen blendet die Beschreibung aus")

	# Zu teuer
	await _interact_with("Shop/Potion")
	check(box.is_running(), "Zu teuer: Händler sagt etwas")
	check(box.get_node("%NamePanel").visible, "Mit Name des Händlers")
	await _close_dialog()
	check_eq(GameState.rupees, 0, "Nichts abgezogen")

	GameState.add_rupees(100)
	# Hinweis
	await _interact_with("Shop/Hint")
	check(box.is_running(), "Hinweis kommt als Dialog")
	await _close_dialog()
	check_eq(GameState.rupees, 99, "Hinweis kostet 1 Rubin")

	# Apfel ins Inventar
	await _interact_with("Shop/Apple")
	await _until_unpaused()
	check_eq(GameState.rupees, 96, "Apfel kostet 3")
	check_eq(player.inventory.slots[0].item, load("res://items/apple.tres"), "Apfel im Inventar")

	# Schlüssel: nur einmal
	await _interact_with("Shop/SmallKey")
	await _until_unpaused()
	check_eq(GameState.keys(), 1, "Schlüssel gekauft")
	check_eq(GameState.rupees, 46, "Schlüssel kostet 50")
	var key_item: ShopItem = game.current_room.get_node("Shop/SmallKey")
	check(not key_item.visible, "Schlüssel ausverkauft")
	await _interact_with("Shop/SmallKey")
	await frames(10)
	check_eq(GameState.rupees, 46, "Ausverkauft: kein zweiter Kauf")

	# Herz: auch bei vollem Leben
	await _interact_with("Shop/Heart")
	await _until_unpaused()
	check_eq(GameState.rupees, 41, "Herz kostet 5")
	check((game.current_room.get_node("Shop/Heart") as ShopItem).visible, "Herz unbegrenzt")

	# Ladenbesitzer über die Theke ansprechen
	var keeper: TalkNpc = game.current_room.get_node("Shopkeeper")
	player.global_position = Vector2(keeper.global_position.x, 112)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)
	check(box.is_running() and box.get_node("%SpeakerName").text == "Ladenbesitzer", "Ladenbesitzer spricht")
	await _close_dialog()

	# Vorrat bleibt nach Raumwechsel
	await game.change_room(AREA, &"from_shop")
	await game.change_room(SHOP, &"from_test_area")
	await frames(2)
	check(not (game.current_room.get_node("Shop/SmallKey") as ShopItem).visible, "Schlüssel bleibt ausverkauft")
	game.queue_free()


func _interact_with(path: String) -> void:
	var target: Node2D = game.current_room.get_node(path)
	player.global_position = target.global_position + Vector2(0, 12)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)


func _close_dialog() -> void:
	var guard := 0
	while box.is_running() and guard < 30:
		await tap("interact")
		await frames(3)
		guard += 1
	await frames(2)


func _until_unpaused() -> void:
	await frames(2)
	var guard := 0
	while get_tree().paused and guard < 300:
		await frames(1)
		guard += 1
	await frames(2)
