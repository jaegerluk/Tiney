class_name HUD
extends CanvasLayer
## Bildschirmanzeige: Leben, Rubine, Schlüssel (nur im Dungeon), Inventar-Menü.
## Leben kommt von Game (Spieler-Signal), Rubine und Schlüssel direkt aus GameState.

@onready var _health_bar: HealthBar = $HealthBar
@onready var dialog_box: DialogBox = $DialogBox
@onready var _item_icon: TextureRect = %EquippedIcon
@onready var _item_amount: Label = %EquippedAmount
## Inventar des Spielers, für die Anzeige des ausgewählten Items.
@export var inventory: Inventory
@onready var _rupee_label: Label = %RupeeLabel
@onready var _key_counter: Control = %KeyCounter
@onready var _key_label: Label = %KeyLabel
@onready var _big_key_icon: Control = %BigKeyIcon
@onready var _message_box: Control = %MessageBox
@onready var _message_label: Label = %MessageLabel
@onready var _boss_panel: Control = %BossPanel
@onready var _info_box: Control = %InfoBox
@onready var _info_label: Label = %InfoLabel
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: ProgressBar = %BossBar

var _boss: Enemy = null


func _ready() -> void:
	GameState.rupees_changed.connect(_on_rupees_changed)
	GameState.keys_changed.connect(_on_keys_changed)
	GameState.dungeon_changed.connect(_on_dungeon_changed)
	GameState.big_keys_changed.connect(_on_big_keys_changed)
	_message_box.visible = false
	_boss_panel.visible = false
	_info_box.visible = false
	if inventory:
		inventory.changed.connect(_on_inventory_changed)
		_on_inventory_changed()
	_on_rupees_changed(GameState.rupees)
	_on_dungeon_changed(GameState.current_dungeon)


func show_health(current: int, maximum: int) -> void:
	_health_bar.show_health(current, maximum)


func _on_inventory_changed() -> void:
	var item := inventory.selected_item()
	_item_icon.texture = item.texture if item else null
	var amount: int = inventory.slots[inventory.selected].amount if item else 0
	_item_amount.text = str(amount) if amount > 1 else ""


## Boss-Lebensleiste am unteren Rand, bis der Boss besiegt ist oder der Raum wechselt.
func show_boss(boss: Enemy) -> void:
	hide_boss()
	_boss = boss
	_boss_name.text = boss.display_name
	_boss_bar.max_value = boss.max_health
	_boss_bar.value = boss.health
	boss.health_changed.connect(_on_boss_health_changed)
	boss.died.connect(hide_boss)
	_boss_panel.visible = true


func hide_boss() -> void:
	if _boss and is_instance_valid(_boss):
		if _boss.health_changed.is_connected(_on_boss_health_changed):
			_boss.health_changed.disconnect(_on_boss_health_changed)
		if _boss.died.is_connected(hide_boss):
			_boss.died.disconnect(hide_boss)
	_boss = null
	_boss_panel.visible = false


func _on_boss_health_changed(current: int, _maximum: int) -> void:
	_boss_bar.value = current


## Info-Box (z. B. Beschreibung einer Ware); das Spiel läuft weiter.
func show_info(text: String) -> void:
	_info_label.text = text
	_info_box.visible = true


func hide_info() -> void:
	_info_box.visible = false


func show_message(text: String) -> void:
	_message_label.text = text
	_message_box.visible = true


func hide_message() -> void:
	_message_box.visible = false


func _on_big_keys_changed(dungeon: StringName, amount: int) -> void:
	if dungeon == GameState.current_dungeon:
		_big_key_icon.visible = amount > 0


func _on_rupees_changed(amount: int) -> void:
	_rupee_label.text = "%03d" % amount


func _on_keys_changed(dungeon: StringName, amount: int) -> void:
	if dungeon == GameState.current_dungeon:
		_key_label.text = str(amount)


func _on_dungeon_changed(dungeon: StringName) -> void:
	_key_counter.visible = dungeon != &""
	_key_label.text = str(GameState.keys())
	_big_key_icon.visible = GameState.big_keys() > 0
