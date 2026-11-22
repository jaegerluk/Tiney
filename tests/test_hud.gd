extends TestCase
## Lebensleiste: Strahl mit Trennstrichen, Nachlauf bei Schaden, flüssiges Wachsen; Herzcontainer.


func run() -> void:
	var bar: HealthBar = load("res://ui/health_bar.tscn").instantiate()
	add_child(bar)
	bar.show_health(60, 60)
	check_eq(bar.heart_count(), 3, "60 LP = 3 Herzen (Trennstriche)")
	check_eq(bar.size.x, 3 * 16 + 2.0, "Breite: 3 Herzen")

	bar.show_health(48, 60)
	check_eq(bar.shown_health, 48.0, "Schaden: roter Teil sofort kürzer")
	check_eq(bar.shown_trail, 60.0, "Nachlauf steht zunächst noch")
	await frames(45)
	check(is_equal_approx(bar.shown_trail, 48.0), "Nachlauf ist nachgezogen")

	bar.show_health(58, 60)
	check(bar.shown_health < 58.0, "Heilen gleitet (nicht sofort)")
	await frames(30)
	check(is_equal_approx(bar.shown_health, 58.0), "Heilen angekommen")

	bar.show_health(80, 80)
	await frames(30)
	check_eq(bar.heart_count(), 4, "Herzcontainer: 4 Herzen")
	check_eq(bar.size.x, 4 * 16 + 2.0, "Leiste wächst mit")
	bar.queue_free()

	# Herzcontainer-Pickup am Spieler
	var player: Player = load("res://player/player.tscn").instantiate()
	add_child(player)
	player.take_damage(25)
	var container: Pickup = load("res://items/pickups/heart_container.tscn").instantiate()
	check(container._apply(player), "Herzcontainer aufgenommen")
	check_eq(player.max_health, 80, "Maximum +1 Herz")
	check_eq(player.health, 80, "Leben ganz aufgefüllt")
	container.free()
	player.queue_free()
