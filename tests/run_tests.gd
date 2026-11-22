extends Node
## Führt alle tests/test_*.gd aus. Aufruf (im Projektordner):
##   godot --headless --fixed-fps 60 --path . tests/run_tests.tscn
##   godot --headless --fixed-fps 60 --path . tests/run_tests.tscn -- test_rooms   (nur einzelne Tests)


func _ready() -> void:
	var only := OS.get_cmdline_user_args()
	var files := Array(DirAccess.get_files_at("res://tests")).filter(
		func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	var failed: Array[String] = []
	for file: String in files:
		if not only.is_empty() and not only.has(file.get_basename()):
			continue
		print("== ", file.get_basename())
		_reset_state()
		var test: TestCase = load("res://tests/" + file).new()
		add_child(test)
		await test.run()
		if not test.failures.is_empty():
			failed.append(file.get_basename())
		test.queue_free()
		await get_tree().process_frame
	_reset_state()
	if failed.is_empty():
		print("ALLE TESTS OK")
	else:
		printerr("FEHLGESCHLAGEN: ", ", ".join(failed))
	get_tree().quit(1 if not failed.is_empty() else 0)


func _reset_state() -> void:
	get_tree().paused = false
	for action in InputMap.get_actions():
		Input.action_release(action)
	GameState.reset()
	Difficulty.value = Difficulty.NORMAL
