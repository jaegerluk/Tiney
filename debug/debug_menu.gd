class_name DebugMenu
extends CanvasLayer
## Debug-Menü (F1), nur in Debug-Läufen (Start aus dem Editor). Pausiert das Spiel.
## Schwierigkeit, Unverwundbarkeit, Sachen geben, Teleport, Raum zurücksetzen, Gegner besiegen.
## Die Oberfläche wird im Code gebaut; Texte sind Entwickler-Texte (deutsch).

const ACTION := &"debug_menu"
const ROOT_FOLDER := "res://world"

@export var game_path: NodePath = ^".."

var _game: Game
var _panel: PanelContainer
var _difficulty_label: Label
var _difficulty_slider: HSlider
var _god_check: CheckBox
var _room_list: OptionButton
var _room_paths: Array[String] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game = get_node(game_path) as Game
	if not InputMap.has_action(ACTION):
		InputMap.add_action(ACTION)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_F1
		InputMap.action_add_event(ACTION, key)
	_build()
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func toggle() -> void:
	if not _panel.visible and get_tree().paused:
		return
	_panel.visible = not _panel.visible
	get_tree().paused = _panel.visible
	if _panel.visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION):
		toggle()
		get_viewport().set_input_as_handled()


# --- Aktionen (auch für Tests direkt aufrufbar) ---

func set_difficulty(value: float) -> void:
	Difficulty.value = value
	_game.reload_room()
	_refresh()


func set_god_mode(enabled: bool) -> void:
	_player().god_mode = enabled


func give(what: String) -> void:
	match what:
		"rupees":
			GameState.add_rupees(100)
		"key":
			GameState.add_key()
		"big_key":
			GameState.add_big_key()
		"heart":
			_player().add_max_health(Player.HP_PER_HEART)
		"potion":
			_player().collect(load("res://items/potion.tres"))
		"heal":
			_player().heal(9999)


func teleport_to(room_path: String) -> void:
	_game.teleport(room_path)
	if is_open():
		toggle()


func reset_room() -> void:
	_game.reload_room(true)


func defeat_enemies() -> void:
	var hit := Hitbox.new()
	hit.damage = 9999
	hit.knockback = 0.0
	for node in _game.current_room.find_children("*", "", true, false):
		if node is Enemy and not (node as Enemy).is_dead():
			(node as Enemy)._on_hurt(hit)
	hit.free()


func room_paths() -> Array[String]:
	var result: Array[String] = []
	_collect_rooms(ROOT_FOLDER, result)
	result.sort()
	return result


# --- Oberfläche ---

func _build() -> void:
	var theme := Theme.new()
	theme.default_font_size = 8
	_panel = PanelContainer.new()
	_panel.theme = theme
	_panel.position = Vector2(8, 8)
	_panel.custom_minimum_size = Vector2(240, 0)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "DEBUG (F1 schließt)"
	box.add_child(title)

	var diff_row := HBoxContainer.new()
	box.add_child(diff_row)
	_difficulty_label = Label.new()
	_difficulty_label.custom_minimum_size = Vector2(90, 0)
	diff_row.add_child(_difficulty_label)
	_difficulty_slider = HSlider.new()
	_difficulty_slider.min_value = Difficulty.MIN
	_difficulty_slider.max_value = Difficulty.MAX
	_difficulty_slider.step = 0.1
	_difficulty_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_difficulty_slider.value_changed.connect(func(v: float) -> void:
		_difficulty_label.text = "Schwierigkeit %.1f" % v)
	diff_row.add_child(_difficulty_slider)
	_button(box, "Schwierigkeit anwenden (Raum neu laden)", func() -> void: set_difficulty(_difficulty_slider.value))

	_god_check = CheckBox.new()
	_god_check.text = "Unverwundbar"
	_god_check.toggled.connect(set_god_mode)
	box.add_child(_god_check)

	var give_grid := GridContainer.new()
	give_grid.columns = 3
	box.add_child(give_grid)
	for entry in [["+100 Rubine", "rupees"], ["+1 Schlüssel", "key"], ["+1 Gr. Schlüssel", "big_key"],
			["+1 Herz", "heart"], ["+1 Heiltrank", "potion"], ["Leben voll", "heal"]]:
		var what: String = entry[1]
		_button(give_grid, entry[0], func() -> void: give(what))

	_room_list = OptionButton.new()
	box.add_child(_room_list)
	_button(box, "Teleport", func() -> void:
		if _room_list.selected >= 0:
			teleport_to(_room_paths[_room_list.selected]))
	_button(box, "Raum zurücksetzen (alles wie neu)", reset_room)
	_button(box, "Alle Gegner im Raum besiegen", defeat_enemies)


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _refresh() -> void:
	_difficulty_slider.value = Difficulty.value
	_difficulty_label.text = "Schwierigkeit %.1f" % Difficulty.value
	_god_check.set_pressed_no_signal(_player().god_mode)
	_room_paths = room_paths()
	_room_list.clear()
	for path in _room_paths:
		_room_list.add_item(path.trim_prefix(ROOT_FOLDER + "/").trim_suffix(".tscn"))
	var current := _room_paths.find(_game.current_room.scene_file_path)
	if current >= 0:
		_room_list.select(current)
	_difficulty_slider.grab_focus()


func _player() -> Player:
	return _game.get_node("Player") as Player


func _collect_rooms(folder: String, out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(folder):
		_collect_rooms(folder.path_join(sub), out)
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".tscn") and file != "game.tscn":
			out.append(folder.path_join(file))
