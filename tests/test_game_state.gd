extends TestCase


func run() -> void:
	# Rubine
	GameState.add_rupees(1)
	GameState.add_rupees(5)
	GameState.add_rupees(20)
	check_eq(GameState.rupees, 26, "Rubine 1+5+20")
	GameState.add_rupees(5000)
	check_eq(GameState.rupees, 999, "Obergrenze 999")
	check(not GameState.spend_rupees(1000), "Zu teuer: nichts abgezogen")
	check(GameState.spend_rupees(99), "Bezahlen klappt")
	check_eq(GameState.rupees, 900, "Rest nach Bezahlen")

	# Schlüssel pro Dungeon
	GameState.current_dungeon = &"dungeon_1"
	GameState.add_key()
	GameState.add_key()
	GameState.add_key(&"dungeon_2")
	check_eq(GameState.keys(), 2, "Zwei Schlüssel in Dungeon 1")
	GameState.current_dungeon = &"dungeon_2"
	check_eq(GameState.keys(), 1, "Ein Schlüssel in Dungeon 2")
	check(GameState.use_key(), "Schlüssel in Dungeon 2 benutzt")
	check(not GameState.use_key(), "Kein Schlüssel mehr in Dungeon 2")
	check_eq(GameState.keys(&"dungeon_1"), 2, "Dungeon 1 unberührt")

	# Merker
	check(not GameState.has_flag("a:b"), "Merker anfangs leer")
	GameState.set_flag("a:b")
	check(GameState.has_flag("a:b"), "Merker gesetzt")

	# Schwierigkeit
	check_eq(Difficulty.value, 4.0, "Standard-Schwierigkeit 4,0")
	check(is_equal_approx(Difficulty.multiplier(Difficulty.Stat.HEALTH), 1.0), "Bei 4,0 Multiplikator 1")
	check_eq(Difficulty.scaled_int(3, Difficulty.Stat.HEALTH), 3, "Basiswert bei 4,0 unverändert")
	Difficulty.value = 8.0
	check(Difficulty.multiplier(Difficulty.Stat.HEALTH) > 1.5, "Bei 8,0 deutlich mehr Leben")
	check_eq(Difficulty.tier(), 8, "Stufe 8")
	Difficulty.value = 6.75
	check(is_equal_approx(Difficulty.value, 6.8), "Auf eine Nachkommastelle gerundet")
	check_eq(Difficulty.tier(), 6, "Stufe 6 bei 6,8")
	Difficulty.value = 42.0
	check_eq(Difficulty.value, 10.0, "Obergrenze 10")
	Difficulty.value = 1.0
	check_eq(Difficulty.scaled_int(1, Difficulty.Stat.DAMAGE), 1, "Mindestens 1 Schaden")
