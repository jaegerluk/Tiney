class_name Pickup
extends Area2D
## Ein Gegenstand am Boden. Der Spieler nimmt ihn beim Berühren auf, wenn im Inventar Platz ist.

@export var item: Item:
	set(value):
		item = value
		if is_node_ready():
			_update_sprite()

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_update_sprite()
	body_entered.connect(_on_body_entered)


func _update_sprite() -> void:
	_sprite.texture = item.texture if item else null


func _on_body_entered(body: Node2D) -> void:
	if body is Player and item and (body as Player).collect(item):
		queue_free()
