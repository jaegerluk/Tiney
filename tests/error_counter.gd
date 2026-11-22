class_name TestErrorCounter
extends Logger
## Zählt Engine- und Skriptfehler (auch push_error), damit der Test-Runner sie als Fehlschlag wertet.
## printerr-Ausgaben der Tests zählen nicht (die laufen über _log_message).

var count: int = 0
var _mutex := Mutex.new()


func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
		_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	_mutex.lock()
	count += 1
	_mutex.unlock()
