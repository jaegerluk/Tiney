class_name RoomExit
extends Area2D
## Ausgang in einen anderen Raum. Läuft der Spieler hinein, meldet der Raum den Wechsel an Game.
## Eingänge im Zielraum so setzen, dass der Spieler nicht direkt wieder in einem Ausgang steht.

signal triggered(target_room: String, target_entry: StringName)

@export_file("*.tscn") var target_room: String = ""
@export var target_entry: StringName = &"start"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and target_room != "":
		triggered.emit(target_room, target_entry)
