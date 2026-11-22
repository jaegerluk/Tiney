class_name HUD
extends CanvasLayer
## Bildschirmanzeige: Leben, Rubine, Schlüssel (nur im Dungeon), Inventar-Menü.
## Leben kommt von Game (Spieler-Signal), Rubine und Schlüssel direkt aus GameState.

@onready var _health_bar: HealthBar = $HealthBar
@onready var _rupee_label: Label = %RupeeLabel
@onready var _key_counter: Control = %KeyCounter
@onready var _key_label: Label = %KeyLabel


func _ready() -> void:
	GameState.rupees_changed.connect(_on_rupees_changed)
	GameState.keys_changed.connect(_on_keys_changed)
	GameState.dungeon_changed.connect(_on_dungeon_changed)
	_on_rupees_changed(GameState.rupees)
	_on_dungeon_changed(GameState.current_dungeon)


func show_health(current: int, maximum: int) -> void:
	_health_bar.show_health(current, maximum)


func _on_rupees_changed(amount: int) -> void:
	_rupee_label.text = "%03d" % amount


func _on_keys_changed(dungeon: StringName, amount: int) -> void:
	if dungeon == GameState.current_dungeon:
		_key_label.text = str(amount)


func _on_dungeon_changed(dungeon: StringName) -> void:
	_key_counter.visible = dungeon != &""
	_key_label.text = str(GameState.keys())
