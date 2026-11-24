class_name GameOverScreen
extends CanvasLayer
## Game-Over-Bildschirm: Bild wird schwarz, „GAME OVER“, blinkendes „Continue“.
## run() wartet auf Interaktion, Angriff oder Menü-Taste; close() blendet wieder aus. Läuft bei Pause.

signal continued

@export var fade_time: float = 0.6

var _waiting: bool = false
var _blink: float = 0.0

@onready var _background: ColorRect = $Background
@onready var _title: Label = $Title
@onready var _continue: Label = $Continue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_background.color.a = 0.0
	_title.visible = false
	_continue.visible = false


func is_waiting() -> bool:
	return _waiting


## Abblenden, Schriftzug zeigen, auf Bestätigung warten.
func run() -> void:
	var tween := create_tween()
	tween.tween_property(_background, "color:a", 1.0, fade_time)
	await tween.finished
	_title.visible = true
	_blink = 0.0
	_waiting = true
	await continued


## Schriftzug weg, Bild wieder aufblenden.
func close() -> void:
	_title.visible = false
	_continue.visible = false
	var tween := create_tween()
	tween.tween_property(_background, "color:a", 0.0, fade_time * 0.5)
	await tween.finished


func _process(delta: float) -> void:
	if not _waiting:
		return
	_blink += delta
	_continue.visible = int(_blink * 2.0) % 2 == 0


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_waiting = false
		_continue.visible = false
		continued.emit()
