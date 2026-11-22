extends TestCase
## Dialog: Schild (ohne Bild), Gefangener (Bild, Name, mehrere Seiten), Schreibmaschine, Pause.

const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var box: DialogBox = game.get_node("HUD/DialogBox")
	var sign_post: Node2D = game.current_room.get_node("SignPost")

	player.global_position = sign_post.global_position + Vector2(0, 8)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(3)
	check(box.is_running(), "Schild öffnet die Textbox")
	check(get_tree().paused, "Spiel pausiert")
	check(not box.get_node("%PortraitPanel").visible and not box.get_node("%NamePanel").visible, "Schild ohne Bild und Name")
	check(not box.page_complete(), "Text erscheint nach und nach")
	await tap("menu")
	check(not game.get_node("HUD/InventoryUI").visible, "Menü öffnet nicht während des Dialogs")
	await tap("interact")
	check(box.page_complete(), "Interaktion zeigt die Seite sofort ganz")
	await tap("interact")
	await frames(2)
	check(not box.is_running() and not get_tree().paused, "Dialog geschlossen, Spiel läuft")

	await game.change_room(ROOM2, &"from_test_area")
	var npc: TalkNpc = game.current_room.get_node("Prisoner")
	player.global_position = npc.global_position + Vector2(0, 14)
	player.face(Vector2.UP)
	await frames(3)
	await tap("interact")
	await frames(2)
	check(box.is_running(), "Gefangener spricht")
	check_eq(box.get_node("%SpeakerName").text, "Gefangener", "Name angezeigt")
	check(box.get_node("%PortraitPanel").visible, "Bild angezeigt")
	var taps := 0
	while box.is_running() and taps < 20:
		await frames(5)
		await tap("interact")
		taps += 1
	check(not box.is_running(), "Alle Seiten durchgeblättert")
	check(taps >= 4, "Mehrere Seiten (%d Klicks)" % taps)
	check(not get_tree().paused, "Spiel läuft wieder")
	game.queue_free()
