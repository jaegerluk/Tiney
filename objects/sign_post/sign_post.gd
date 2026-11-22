class_name SignPost
extends StaticBody2D
## Schild. Davor stehen, nach oben schauen, "interact": Der Text erscheint in der Textbox (ohne Bild).
## Leerzeilen im Text trennen Seiten.

signal dialog_requested(pages: Array, speaker: String, portrait: Texture2D)

@export_multiline var text: String = "Du liest ein Schild."


func _ready() -> void:
	($InteractZone as InteractZone).interacted.connect(func(_player: Player) -> void:
		dialog_requested.emit(Array(text.split("\n\n")), "", null))
