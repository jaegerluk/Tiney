extends TestCase
## Halteschalter (Spieler/Block) und Kristallschalter in drei Modi.

const SWITCHES := "res://world/test_area/test_switches.tscn"
const AREA := "res://world/test_area/test_area.tscn"

var game: Game
var player: Player


func run() -> void:
	game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	player = game.get_node("Player")

	# Durch die Westöffnung
	player.global_position = Vector2(30, 112)
	await frames(2)
	hold("move_left")
	for i in 60:
		await frames(1)
		if game.current_room.name == &"TestSwitches":
			break
	hold("move_left", false)
	await frames(20)
	check_eq(game.current_room.name, &"TestSwitches", "Westöffnung führt in den Schalterraum")
	var room := game.current_room

	# Halteschalter: nur solange man draufsteht
	var door_hold: SwitchDoor = room.get_node("DoorHold")
	player.global_position = room.get_node("HoldSwitch").global_position
	await frames(3)
	check(door_hold.is_open, "Draufstehen öffnet")
	player.global_position = Vector2(64, 196)
	await frames(3)
	check(not door_hold.is_open, "Runtergehen schließt")
	# Block draufschieben (von rechts, zweimal nach links)
	var block: PushBlock = room.get_node("PushBlock")
	player.global_position = block.global_position + Vector2(16, 0)
	await frames(2)
	for n in 2:
		hold("move_left")
		await frames(35)
		hold("move_left", false)
		await frames(20)
	check_eq(block.position, Vector2(64, 168), "Block auf dem Halteschalter")
	player.global_position = Vector2(160, 190)
	await frames(3)
	check(door_hold.is_open, "Block hält die Tür offen")

	# Kristall Umschalter: echter Schwerthieb
	var toggle: CrystalSwitch = room.get_node("CrystalToggle")
	var door_toggle: SwitchDoor = room.get_node("DoorToggle")
	player.global_position = toggle.global_position + Vector2(0, 16)
	player.face(Vector2.UP)
	await frames(3)
	await tap("attack")
	await frames(5)
	check(toggle.is_on and door_toggle.is_open, "Treffer: Umschalter an, Tür auf")
	check_eq(toggle.get_node("Sprite2D").frame, 1, "Umschalter rot")
	await frames(40)
	await tap("attack")
	await frames(5)
	check(not toggle.is_on and not door_toggle.is_open, "Zweiter Treffer: wieder zu")
	await frames(40)
	await tap("attack")
	await frames(30)

	# Einmalig
	var once: CrystalSwitch = room.get_node("CrystalOnce")
	var hit := Hitbox.new()
	once._on_hurt(hit)
	await frames(30)
	once._on_hurt(hit)
	check(once.is_on and (room.get_node("DoorOnce") as SwitchDoor).is_open, "Einmalig: bleibt offen")
	check_eq(once.get_node("Sprite2D").frame, 3, "Einmalig benutzt: grau")

	# Zeitschalter
	var timed: CrystalSwitch = room.get_node("CrystalTimed")
	var door_timed: SwitchDoor = room.get_node("DoorTimed")
	timed._on_hurt(hit)
	hit.free()
	await frames(2)
	check(door_timed.is_open, "Zeitschalter öffnet")
	await frames(180)
	check(door_timed.is_open, "Nach 3 s noch offen")
	await frames(80)
	check(not door_timed.is_open and not timed.is_on, "Nach 4 s wieder zu")

	# Raumwechsel: Umschalter und Einmalig bleiben, Block bleibt auf dem Halteschalter
	player.global_position = Vector2(480, 176)
	await game.change_room(AREA, &"from_switches")
	await game.change_room(SWITCHES, &"from_test_area")
	await frames(5)
	room = game.current_room
	check((room.get_node("CrystalToggle") as CrystalSwitch).is_on and (room.get_node("DoorToggle") as SwitchDoor).is_open, "Umschalter bleibt an")
	check((room.get_node("DoorOnce") as SwitchDoor).is_open, "Einmalig bleibt offen")
	check((room.get_node("DoorHold") as SwitchDoor).is_open, "Block hält die Tür auch nach Raumwechsel offen")
	check(not (room.get_node("DoorTimed") as SwitchDoor).is_open, "Zeitschalter ist zu")
	game.queue_free()
