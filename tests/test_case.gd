class_name TestCase
extends Node
## Basis für Headless-Tests. Wird von tests/run_tests.gd geladen; run() überschreiben (darf await nutzen).

var failures: Array[String] = []


func run() -> void:
	pass


func check(condition: bool, message: String) -> void:
	if condition:
		print("  ok      ", message)
	else:
		failures.append(message)
		printerr("  FEHLER  ", message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (ist %s, erwartet %s)" % [message, actual, expected])


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Aktion gedrückt halten bzw. loslassen (für Polling mit Input.is_action_*).
func hold(action: StringName, pressed: bool = true) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


## Aktion einmal antippen: drücken, einen Physik-Frame warten, loslassen.
func tap(action: StringName) -> void:
	hold(action, true)
	await frames(1)
	hold(action, false)


## Hält eine Aktion für eine Anzahl Physik-Frames.
func hold_for(action: StringName, count: int) -> void:
	hold(action, true)
	await frames(count)
	hold(action, false)
