extends TestCase
## Rubine, Herz, Schlüssel (dauerhaft über Raumwechsel), Item, HUD-Zähler.

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"

var game: Game
var player: Player


func run() -> void:
	game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	player = game.get_node("Player")
	var hud: HUD = game.get_node("HUD")

	check(hud.get_node("%KeyCounter").visible, "Schlüsselzähler im Dungeon sichtbar")
	check_eq(hud.get_node("%RupeeLabel").text, "000", "Rubinzähler startet bei 000")

	# Rubine 1 + 5 + 20
	for name in ["Rupee1", "Rupee2", "Rupee3"]:
		await _step_on(name)
	check_eq(GameState.rupees, 26, "Rubine 1+5+20 eingesammelt")
	check_eq(hud.get_node("%RupeeLabel").text, "026", "HUD zeigt 026")
	check(not game.current_room.has_node("Rupee1"), "Rubin verschwindet")

	# Herz: heilt 1 Herz, wird aber auch bei vollem Leben aufgenommen
	player.take_damage(30)
	player.global_position = Vector2(64, 96)
	await frames(3)
	await _step_on("Heart")
	check_eq(player.health, 50, "Herz heilt 20 LP (30 -> 50)")
	check(not game.current_room.has_node("Heart"), "Herz aufgenommen")
	var extra: Node2D = load("res://items/pickups/heart.tscn").instantiate()
	extra.position = Vector2(200, 300)
	game.current_room.add_child(extra)
	player.heal(99)
	player.global_position = extra.global_position
	await frames(3)
	check(not is_instance_valid(extra), "Herz auch bei vollem Leben aufgenommen")
	check_eq(player.health, player.max_health, "Leben nicht über Maximum")
	player.global_position = Vector2(64, 96)
	await frames(2)

	# Schlüssel
	await _step_on("SmallKey")
	check_eq(GameState.keys(), 1, "Schlüssel eingesammelt")
	check_eq(hud.get_node("%KeyLabel").text, "1", "HUD zeigt 1 Schlüssel")

	# Raum verlassen und zurück: nichts kommt wieder
	await game.change_room(ROOM2, &"from_test_area")
	await game.change_room(AREA, &"from_room_2")
	await frames(2)
	check(not game.current_room.has_node("SmallKey"), "Schlüssel bleibt weg")
	check(not game.current_room.has_node("Rupee1"), "Rubine bleiben weg")
	check(not game.current_room.has_node("Heart"), "Herz bleibt weg")
	check_eq(GameState.keys(), 1, "Schlüssel noch im Besitz")

	# Item ins Inventar
	await _step_on("Apple1")
	check_eq(player.inventory.slots[0].amount, 1, "Apfel im Inventar")
	game.queue_free()


func _step_on(node_name: String) -> void:
	var target: Node2D = game.current_room.get_node(node_name)
	player.global_position = target.global_position - Vector2(0, 4)
	await frames(3)
	player.global_position = Vector2(64, 96)
	await frames(3)
