class_name RoomCamera
extends Camera2D
## Raumkamera. Zwei Modi:
## - screen_scroll (Standard, ALttP): Kamera steht pro Bildschirm still; überschreitet das Ziel eine
##   Bildschirmgrenze, schiebt sie zum nächsten Bildschirm (scroll_started/scroll_finished).
## - sonst: folgt dem Ziel frei innerhalb der Raumgrenzen.

signal scroll_started(direction: Vector2)
signal scroll_finished

## Wem die Kamera folgt (der Spieler).
@export var target: Node2D
@export var scroll_time: float = 0.5
@export var screen_scroll: bool = true
## Bewegt sich das Ziel in einem Frame weiter als das (Teleport, Sturz, Skript), springt die Kamera mit.
@export var teleport_distance: float = 24.0

var bounds: Rect2 = Rect2(-100000, -100000, 200000, 200000)
var _screen: Vector2i = Vector2i.ZERO
var _scrolling: bool = false
var _last_target_position: Vector2 = Vector2.ZERO
var _shake_strength: float = 0.0
var _shake_left: float = 0.0
var _shake_time: float = 0.0


## true, wenn ein Knoten gerade im sichtbaren Bildschirm liegt (mit Rand in Pixeln).
static func is_on_screen(node: CanvasItem, margin: float = 0.0) -> bool:
	var point := node.get_global_transform_with_canvas().origin
	return node.get_viewport_rect().grow(margin).has_point(point)


func set_bounds(new_bounds: Rect2) -> void:
	bounds = new_bounds
	limit_left = roundi(bounds.position.x)
	limit_top = roundi(bounds.position.y)
	limit_right = roundi(bounds.end.x)
	limit_bottom = roundi(bounds.end.y)


## Springt ohne Animation zum Ziel (nach Raumwechsel, Tod …).
func snap_to_target() -> void:
	if target == null:
		return
	if screen_scroll:
		_screen = screen_of(target.global_position)
		global_position = screen_center(_screen)
	else:
		global_position = target.global_position
	_last_target_position = target.global_position
	reset_smoothing()


## Bildschirmwackeln: zufälliger Versatz, klingt über `duration` ab.
func shake(strength: float, duration: float) -> void:
	if strength >= _shake_strength * (_shake_left / maxf(_shake_time, 0.001)):
		_shake_strength = strength
		_shake_left = duration
		_shake_time = duration


func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		var power := _shake_strength * maxf(_shake_left, 0.0) / maxf(_shake_time, 0.001)
		offset = Vector2(randf_range(-power, power), randf_range(-power, power)).round()
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO


func is_scrolling() -> bool:
	return _scrolling


func screen_size() -> Vector2:
	return get_viewport_rect().size


## Index des Bildschirms (Spalte, Zeile) innerhalb des Raums.
func screen_of(point: Vector2) -> Vector2i:
	var size := screen_size()
	var count := Vector2i(maxi(ceili(bounds.size.x / size.x), 1), maxi(ceili(bounds.size.y / size.y), 1))
	var index := Vector2i(((point - bounds.position) / size).floor())
	return index.clamp(Vector2i.ZERO, count - Vector2i.ONE)


func screen_center(index: Vector2i) -> Vector2:
	return bounds.position + (Vector2(index) + Vector2(0.5, 0.5)) * screen_size()


func _physics_process(_delta: float) -> void:
	if target == null or _scrolling:
		return
	if not screen_scroll:
		global_position = target.global_position
		return
	if target.global_position.distance_to(_last_target_position) > teleport_distance:
		snap_to_target()
		return
	_last_target_position = target.global_position
	var index := screen_of(target.global_position)
	if index != _screen:
		_scroll_to(index)


func _scroll_to(index: Vector2i) -> void:
	_scrolling = true
	var direction := Vector2(index - _screen)
	_screen = index
	scroll_started.emit(direction)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "global_position", screen_center(index), scroll_time)
	await tween.finished
	_scrolling = false
	scroll_finished.emit()
