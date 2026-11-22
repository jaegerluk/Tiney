class_name TalkNpc
extends StaticBody2D
## NPC zum Reden: Spieler davor, zum NPC schauen, "interact" -> Dialog mit Bild und Name.

signal dialog_requested(pages: Array, speaker: String, portrait: Texture2D)

@export var display_name: String = ""
@export var portrait: Texture2D
## Eine Seite pro Eintrag.
@export_multiline var pages: Array[String] = []


func _ready() -> void:
	($InteractZone as InteractZone).interacted.connect(func(_player: Player) -> void:
		dialog_requested.emit(pages, display_name, portrait))
