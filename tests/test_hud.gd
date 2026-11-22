extends TestCase
## Lebensanzeige: Abschnitte pro Herz, halbe Füllung, wächst mit max_health.


func run() -> void:
	var bar: HealthBar = load("res://ui/health_bar.tscn").instantiate()
	add_child(bar)
	bar.show_health(6, 6)
	check_eq(bar.segment_count(), 3, "6 halbe Herzen = 3 Abschnitte")
	check_eq([bar.segment_fill(0), bar.segment_fill(1), bar.segment_fill(2)], [1.0, 1.0, 1.0], "Volles Leben")
	bar.show_health(5, 6)
	check_eq([bar.segment_fill(0), bar.segment_fill(1), bar.segment_fill(2)], [1.0, 1.0, 0.5], "5/6: letzter Abschnitt halb")
	bar.show_health(2, 6)
	check_eq([bar.segment_fill(0), bar.segment_fill(1), bar.segment_fill(2)], [1.0, 0.0, 0.0], "2/6: ein Abschnitt")
	bar.show_health(0, 6)
	check_eq([bar.segment_fill(0), bar.segment_fill(1), bar.segment_fill(2)], [0.0, 0.0, 0.0], "Leer")
	bar.show_health(8, 8)
	check_eq(bar.segment_count(), 4, "Herzcontainer: 4 Abschnitte")
	check_eq(bar.size, Vector2(4 * 16 + 3 * 2, 6), "Breite wächst mit")
	bar.queue_free()
