class_name DialogBox
extends Control
## Textbox am unteren Rand mit Schreibmaschinen-Effekt; optional Porträt und Name darüber.
## "interact" zeigt die Seite sofort ganz bzw. blättert weiter. Läuft auch bei pausiertem Spiel.

signal finished

## Buchstaben pro Sekunde.
@export var chars_per_second: float = 40.0

var _pages: Array = []
var _page: int = 0
var _shown_chars: float = 0.0
var _running: bool = false
var _blink: float = 0.0

@onready var _text: Label = %Text
@onready var _more: Label = %More
@onready var _portrait_panel: Control = %PortraitPanel
@onready var _portrait: TextureRect = %Portrait
@onready var _name_panel: Control = %NamePanel
@onready var _name: Label = %SpeakerName


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_running() -> bool:
	return _running


## Zeigt die Seiten nacheinander und kehrt zurück, wenn der Spieler die letzte weggeklickt hat.
func run(pages: Array, speaker: String = "", portrait: Texture2D = null) -> void:
	_pages = pages if not pages.is_empty() else [""]
	_page = 0
	_name.text = speaker
	_name_panel.visible = speaker != ""
	_portrait.texture = portrait
	_portrait_panel.visible = portrait != null
	visible = true
	_running = true
	_show_page()
	await finished


func page_complete() -> bool:
	return _text.visible_characters < 0 or _text.visible_characters >= _text.get_total_character_count()


func _process(delta: float) -> void:
	if not _running:
		return
	if not page_complete():
		_shown_chars += delta * chars_per_second
		_text.visible_characters = mini(int(_shown_chars), _text.get_total_character_count())
	_blink += delta
	_more.visible = page_complete() and int(_blink * 3.0) % 2 == 0


func _unhandled_input(event: InputEvent) -> void:
	if not _running or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if not page_complete():
		_text.visible_characters = -1
	elif _page < _pages.size() - 1:
		_page += 1
		_show_page()
	else:
		_running = false
		visible = false
		finished.emit()


func _show_page() -> void:
	_text.text = str(_pages[_page])
	_shown_chars = 0.0
	_text.visible_characters = 0
	_blink = 0.0
