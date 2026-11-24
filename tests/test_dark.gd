extends TestCase
## Dunkle Räume und Fackeln: Dunkelheit + Lichtkreis, Schalter zünden Fackeln an, alle an -> Tür auf,
## Fackel mit Brenndauer geht aus, dauerhafte bleiben nach Raumwechsel an.

const DARK := "res://world/test_area/test_dark.tscn"
const TRAPS := "res://world/test_area/test_traps.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	check(not player.get_node("PointLight2D").enabled, "Heller Raum: kein Lichtkreis")
	game.teleport(TRAPS, &"from_cellar")
	await frames(2)
	player.global_position = Vector2(30, 64)
	hold("move_left")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestDark":
			break
	hold("move_left", false)
	await frames(20)
	check_eq(game.current_room.name, &"TestDark", "Westöffnung des Fallenraums führt in den dunklen Raum")
	var room := game.current_room
	check(room.has_node("Darkness"), "Dunkler Raum: Abdunklung aktiv")
	check(player.get_node("PointLight2D").enabled, "Lichtkreis um den Helden")

	var group: TorchGroup = room.get_node("TorchGroup")
	var door: SwitchDoor = room.get_node("RewardDoor")
	await frames(2)
	check((room.get_node("TorchGroup/TorchLit") as Torch).is_lit(), "Vorplatzierte Fackel brennt")
	check(not group.all_lit and not door.is_open, "Noch nicht alle an: Tür zu")

	player.global_position = room.get_node("FloorSwitch").global_position
	await frames(3)
	check((room.get_node("TorchGroup/TorchSwitch") as Torch).is_lit(), "Bodenschalter zündet Fackel an")
	player.global_position = Vector2(100, 120)
	await frames(3)
	check((room.get_node("TorchGroup/TorchSwitch") as Torch).is_lit(), "Schalter wieder aus: Fackel brennt weiter")

	var hit := Hitbox.new()
	(room.get_node("CrystalOnce") as CrystalSwitch)._on_hurt(hit)
	await frames(3)
	check(group.all_lit and door.is_open, "Alle drei an: Tür geht auf")

	# Fackel mit Brenndauer
	(room.get_node("CrystalTimed") as CrystalSwitch)._on_hurt(hit)
	hit.free()
	await frames(2)
	var timed: Torch = room.get_node("TimedTorch")
	check(timed.is_lit(), "Zeit-Kristall zündet die obere Fackel an")
	await frames(120)
	check(timed.is_lit(), "Kristall längst aus, Fackel brennt noch (eigene Brenndauer)")
	await frames(260)
	check(not timed.is_lit(), "Nach 6 s geht sie aus")

	# Raumwechsel: dauerhafte Fackeln bleiben an
	await game.change_room(TRAPS, &"from_dark")
	check(not player.get_node("PointLight2D").enabled, "Zurück im hellen Raum: kein Lichtkreis")
	await game.change_room(DARK, &"from_traps")
	await frames(3)
	room = game.current_room
	check((room.get_node("TorchGroup/TorchSwitch") as Torch).is_lit() and (room.get_node("TorchGroup/TorchCrystal") as Torch).is_lit(), "Fackeln bleiben an")
	check((room.get_node("RewardDoor") as SwitchDoor).is_open, "Tür bleibt offen")
	game.queue_free()
