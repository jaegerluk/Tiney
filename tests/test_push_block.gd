extends TestCase
## Schiebeblock: kurz dagegen laufen schiebt ein Tile, Wände blockieren, drückt Schalter, Position bleibt.

const AREA := "res://world/test_area/test_area.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var block: PushBlock = game.current_room.get_node("PushBlock")
	var switch: FloorSwitch = game.current_room.get_node("FloorSwitch")
	check_eq(block.position, Vector2(160, 176), "Startposition")

	# Kurzes Antippen schiebt nicht
	player.global_position = block.global_position + Vector2(0, 16)
	await frames(2)
	await _push(Vector2.UP, 8)
	check_eq(block.position, Vector2(160, 176), "Kurz dagegen: nichts passiert")

	# Zweimal schieben -> auf dem Schalter
	await _push(Vector2.UP, 35)
	await frames(20)
	check_eq(block.position, Vector2(160, 160), "Ein Tile nach oben")
	await _push(Vector2.UP, 35)
	await frames(20)
	check_eq(block.position, Vector2(160, 144), "Noch ein Tile")
	await _push(Vector2.UP, 35)
	await frames(20)
	check_eq(block.position, Vector2(160, 128), "Auf dem Schalter")
	check(switch.is_on, "Block drückt den Schalter")
	check(game.current_room.get_node("SwitchDoor").is_open, "Tür geht auf")

	# Position bleibt über Raumwechsel
	player.global_position = Vector2(64, 96)
	await game.change_room(ROOM2, &"from_test_area")
	await game.change_room(AREA, &"from_room_2")
	await frames(2)
	check_eq((game.current_room.get_node("PushBlock") as PushBlock).position, Vector2(160, 128), "Block bleibt, wo er ist")
	game.queue_free()
	await frames(2)

	# Wand blockiert
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(300, 284)
	add_child(wall)
	var solo: PushBlock = load("res://objects/push_block/push_block.tscn").instantiate()
	solo.position = Vector2(300, 300)
	add_child(solo)
	var p2: Player = load("res://player/player.tscn").instantiate()
	p2.position = Vector2(300, 316)
	add_child(p2)
	await frames(2)
	await _push(Vector2.UP, 40)
	await frames(20)
	check_eq(solo.position, Vector2(300, 300), "Wand dahinter: Block bleibt stehen")
	await frames(2)


	# Ziehen: von rechts greifen (nach links schauen), dann nach rechts wegziehen
	var pull: PushBlock = load("res://objects/push_block/push_block.tscn").instantiate()
	pull.position = Vector2(100, 150)
	add_child(pull)
	p2.global_position = Vector2(116, 150)
	p2.face(Vector2.LEFT)
	await frames(3)
	hold("interact")
	await frames(3)
	check(pull.is_grabbed() and p2.is_grabbing(), "Interaktion halten: Held packt den Block")
	hold("move_right")
	await frames(10)
	check_eq(p2.global_position.x, 116.0, "Festhalten: Held läuft nicht weg")
	await frames(40)
	hold("move_right", false)
	await frames(5)
	check_eq(pull.position, Vector2(116, 150), "Block ein Tile gezogen")
	check_eq(p2.global_position, Vector2(132, 150), "Held mitgerückt")
	hold("interact", false)
	await frames(3)
	check(not pull.is_grabbed() and not p2.is_grabbing(), "Loslassen beendet den Griff")

	# Wand hinter dem Helden: Ziehen geht nicht
	var behind := StaticBody2D.new()
	var bshape := CollisionShape2D.new()
	var brect := RectangleShape2D.new()
	brect.size = Vector2(16, 32)
	bshape.shape = brect
	behind.add_child(bshape)
	behind.position = Vector2(148, 150)
	add_child(behind)
	await frames(2)
	hold("interact")
	await frames(3)
	hold("move_right")
	await frames(50)
	hold("move_right", false)
	hold("interact", false)
	await frames(5)
	check_eq(pull.position, Vector2(116, 150), "Kein Platz hinter dem Helden: Block bleibt")
	behind.queue_free()

	# Nur schiebbarer Block: kein Griff, dunkler
	var push_only: PushBlock = load("res://objects/push_block/push_block.tscn").instantiate()
	push_only.pullable = false
	push_only.position = Vector2(200, 60)
	add_child(push_only)
	p2.global_position = Vector2(216, 60)
	p2.face(Vector2.LEFT)
	await frames(3)
	hold("interact")
	await frames(3)
	check(not push_only.is_grabbed(), "Nur schiebbar: kein Griff")
	hold("interact", false)
	check(push_only.get_node("Sprite2D").modulate != Color.WHITE, "Nur schiebbar: dunkler")
	for n in [pull, push_only, p2, solo]:
		n.queue_free()
	await frames(2)


func _push(direction: Vector2, count: int) -> void:
	var action := "move_up" if direction == Vector2.UP else "move_down"
	hold(action)
	await frames(count)
	hold(action, false)
