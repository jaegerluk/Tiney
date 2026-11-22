class_name HealthBar
extends Control
## Lebensleiste: durchgehender Strahl mit Trennstrichen pro Herz.
## Schaden: der rote Teil schrumpft sofort, der verlorene Teil leuchtet hell und läuft dann nach.
## Heilen und mehr Maximum (Herzcontainer) gleiten flüssig.

## Breite eines Herzens in Pixeln.
@export var heart_width: float = 16.0
@export var bar_height: float = 6.0
@export var fill_color: Color = Color(0.86, 0.16, 0.24)
@export var trail_color: Color = Color(1.0, 0.85, 0.85)
@export var empty_color: Color = Color(0.1, 0.08, 0.1)
@export var border_color: Color = Color(0.85, 0.85, 0.85)
@export var tick_color: Color = Color(0.1, 0.08, 0.1, 0.8)
## Wartezeit, bevor der Nachlauf startet, und Dauer der Animationen (Sekunden).
@export var trail_delay: float = 0.35
@export var slide_time: float = 0.3

var current: int = 60
var maximum: int = 60

## Angezeigte Werte (animiert), in LP.
var shown_health: float = 60.0:
	set(value):
		shown_health = value
		queue_redraw()
var shown_trail: float = 60.0:
	set(value):
		shown_trail = value
		queue_redraw()
var shown_max: float = 60.0:
	set(value):
		shown_max = value
		_update_size()
		queue_redraw()

var _health_tween: Tween
var _max_tween: Tween


func _ready() -> void:
	_update_size()


func show_health(new_current: int, new_maximum: int) -> void:
	var first := not is_node_ready() or (current == new_current and maximum == new_maximum)
	current = new_current
	maximum = new_maximum
	if first:
		shown_health = current
		shown_trail = current
		shown_max = maximum
		return
	if _max_tween:
		_max_tween.kill()
	if not is_equal_approx(shown_max, maximum):
		_max_tween = create_tween()
		_max_tween.tween_property(self, "shown_max", float(maximum), slide_time)
	if _health_tween:
		_health_tween.kill()
	_health_tween = create_tween()
	if current < shown_health:
		shown_health = current
		_health_tween.tween_interval(trail_delay)
		_health_tween.tween_property(self, "shown_trail", float(current), slide_time)
	else:
		shown_trail = maxf(shown_trail, shown_health)
		_health_tween.set_parallel()
		_health_tween.tween_property(self, "shown_health", float(current), slide_time)
		_health_tween.tween_property(self, "shown_trail", float(current), slide_time)


## Anzahl Herzen (für Trennstriche), aufgerundet.
func heart_count() -> int:
	return ceili(shown_max / Player.HP_PER_HEART)


func _draw() -> void:
	var width := _bar_width()
	draw_rect(Rect2(0, 0, width, bar_height), border_color)
	var inner := Rect2(1, 1, width - 2, bar_height - 2)
	draw_rect(inner, empty_color)
	var per_hp := inner.size.x / maxf(shown_max, 1.0)
	if shown_trail > shown_health:
		draw_rect(Rect2(inner.position.x, inner.position.y, roundf(shown_trail * per_hp), inner.size.y), trail_color)
	draw_rect(Rect2(inner.position.x, inner.position.y, roundf(shown_health * per_hp), inner.size.y), fill_color)
	for i in range(1, heart_count()):
		var x := roundf(inner.position.x + i * Player.HP_PER_HEART * per_hp)
		if x < inner.end.x:
			draw_rect(Rect2(x, inner.position.y, 1, inner.size.y), tick_color)


func _bar_width() -> float:
	return roundf(shown_max / Player.HP_PER_HEART * heart_width) + 2.0


func _update_size() -> void:
	custom_minimum_size = Vector2(_bar_width(), bar_height)
	size = custom_minimum_size
