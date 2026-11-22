extends TestCase
## Items: im Menü auswählen, mit use_item benutzen, Heilung, kein Verbrauch bei vollem Leben, HUD-Anzeige.


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var inv: Inventory = player.inventory
	inv.restore([])
	for slot in inv.slots:
		slot.item = null
		slot.amount = 0
	var apple: Item = load("res://items/apple.tres")
	var potion: Item = load("res://items/potion.tres")
	inv.insert(apple)
	inv.insert(apple)
	inv.insert(potion)
	var hud: HUD = game.get_node("HUD")

	# Menü öffnen, mit rechts auf den Trank
	await tap("menu")
	check(get_tree().paused, "Menü pausiert")
	check_eq(inv.selected, 0, "Cursor startet auf dem ersten Slot")
	await tap("move_right")
	check_eq(inv.selected_item(), potion, "Rechts: Heiltrank ausgewählt")
	await tap("move_left")
	check_eq(inv.selected_item(), apple, "Links: Apfel ausgewählt")
	check_eq(game.get_node("HUD/InventoryUI/%ItemName").text, "Apfel", "Name im Menü")
	await tap("menu")
	check(not get_tree().paused, "Menü zu")
	check_eq(hud.get_node("%EquippedIcon").texture, apple.texture, "HUD zeigt das ausgewählte Item")
	check_eq(hud.get_node("%EquippedAmount").text, "2", "HUD zeigt die Anzahl")

	# Bei vollem Leben nicht verbraucht
	await tap("use_item")
	await frames(2)
	check_eq(inv.slots[0].amount, 2, "Volles Leben: Apfel nicht verbraucht")

	# Apfel heilt ½ Herz
	player.take_damage(30)
	await frames(70)
	await tap("use_item")
	await frames(2)
	check_eq(player.health, 40, "Apfel heilt 10 LP (30 -> 40)")
	check_eq(inv.slots[0].amount, 1, "Ein Apfel verbraucht")
	await tap("use_item")
	await frames(2)
	check(inv.slots[0].is_empty(), "Letzter Apfel weg, Slot leer")
	check_eq(hud.get_node("%EquippedIcon").texture, null, "HUD leer, wenn Slot leer")

	# Heiltrank: volles Leben
	inv.select(1)
	await tap("use_item")
	await frames(2)
	check_eq(player.health, player.max_health, "Heiltrank füllt alles auf")
	check(inv.slots[1].is_empty(), "Heiltrank verbraucht")
	game.queue_free()
