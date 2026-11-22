class_name HealthBar
extends Control
## Lebensanzeige in Abschnitten: ein Abschnitt pro Herz (2 halbe Herzen), voll, halb oder leer.
## Wächst automatisch mit max_health (Herzcontainer).

@export var segment_size: Vector2 = Vector2(16, 6)
@export var gap: float = 2.0
@export var fill_color: Color = Color(0.86, 0.16, 0.24)
@export var empty_color: Color = Color(0.1, 0.08, 0.1)
@export var border_color: Color = Color(0.85, 0.85, 0.85)

var current: int = 6
var maximum: int = 6


func _ready() -> void:
	_update_size()


func show_health(new_current: int, new_maximum: int) -> void:
	current = new_current
	maximum = new_maximum
	_update_size()
	queue_redraw()


func segment_count() -> int:
	return ceili(maximum / 2.0)


## Füllung eines Abschnitts: 1 = voll, 0.5 = halb, 0 = leer.
func segment_fill(index: int) -> float:
	return clampf((current - index * 2) / 2.0, 0.0, 1.0)


func _draw() -> void:
	for i in segment_count():
		var outer := Rect2(Vector2(i * (segment_size.x + gap), 0), segment_size)
		var inner := outer.grow(-1)
		draw_rect(outer, border_color)
		draw_rect(inner, empty_color)
		var fill := segment_fill(i)
		if fill > 0.0:
			draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * fill), inner.size.y)), fill_color)


func _update_size() -> void:
	var count := segment_count()
	custom_minimum_size = Vector2(count * segment_size.x + maxi(count - 1, 0) * gap, segment_size.y)
	size = custom_minimum_size
