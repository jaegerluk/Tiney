class_name SignPost
extends StaticBody2D
## Schild. Der Spieler liest es, wenn er davor steht, nach oben schaut und "interact" drückt.

@export_multiline var text: String = "Du liest ein Schild."

var _reader: Player = null

@onready var _bubble: Control = $TextBubble
@onready var _label: Label = %Label


func _ready() -> void:
	_label.text = text
	_bubble.visible = false
	var area: Area2D = $ReadArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _reader == null or not event.is_action_pressed("interact"):
		return
	if _bubble.visible or _reader.facing == Vector2.UP:
		_bubble.visible = not _bubble.visible
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_reader = body


func _on_body_exited(body: Node2D) -> void:
	if body == _reader:
		_reader = null
		_bubble.visible = false
