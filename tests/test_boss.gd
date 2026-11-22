extends TestCase
## Boss-Gerüst: Raum schließt, Boss-Leiste, Sturmangriff, Zombies bei halbem Leben,
## Sieg -> Belohnungen (Herzcontainer, Kugel mit Hochhalten), Tür auf, Boss bleibt besiegt.

const BOSS_ROOM := "res://world/test_area/test_boss_room.tscn"
const ROOM2 := "res://world/test_area/test_room_2.tscn"


func run() -> void:
	var game: Game = load("res://world/game.tscn").instantiate()
	add_child(game)
	await frames(2)
	var player: Player = game.get_node("Player")
	var hud: HUD = game.get_node("HUD")
	await game.change_room(BOSS_ROOM, &"from_room_2")
	var king: ZombieKing = game.current_room.get_node("ZombieKing")
	var lock: RoomLock = game.current_room.get_node("RoomLock")
	check(not king.active, "Boss wartet, bis sich die Tür schließt")
	await frames(40)
	check(lock.is_locked, "Bossraum ist verschlossen")
	check(king.active, "Boss aktiv")
	check(hud.get_node("%BossPanel").visible, "Boss-Leiste sichtbar")
	check_eq(hud.get_node("%BossName").text, "Zombie-König", "Boss-Name")
	check_eq(king.max_health, 12, "12 Hiebe bei 4,0")

	# Sturmangriff kommt
	var seen_charge := false
	for i in 400:
		await frames(1)
		player.global_position = Vector2(128, 60)
		if king.state_name() == "CHARGE":
			seen_charge = true
			break
	check(seen_charge, "Sturmangriff nach Ankündigung")

	# Bis halbes Leben: Zombies erscheinen
	player.global_position = Vector2(40, 190)
	king.global_position = Vector2(180, 120)
	var hit := Hitbox.new()
	hit.damage = 1
	hit.knockback = 0.0
	for i in 6:
		king._on_hurt(hit)
	check_eq(hud.get_node("%BossBar").value, 6.0, "Boss-Leiste sinkt")
	await frames(3)
	var minions := game.current_room.get_children().filter(func(n: Node) -> bool: return n is Zombie)
	check_eq(minions.size(), 2, "Bei halbem Leben: 2 Zombies")

	# Besiegen
	for i in 6:
		king._on_hurt(hit)
	hit.free()
	await frames(3)
	check(king.is_dead(), "Boss besiegt")
	check(not hud.get_node("%BossPanel").visible, "Boss-Leiste weg")
	check(minions.all(func(m) -> bool: return not is_instance_valid(m) or m.is_queued_for_deletion()), "Gerufene Zombies verschwinden")
	check(not lock.is_locked and (lock.get_node("ShutterDoor") as ShutterDoor).is_open, "Tür geht auf")
	var drops := get_tree().get_nodes_in_group(DropTable.DROP_GROUP).filter(func(n: Node) -> bool: return game.current_room.is_ancestor_of(n))
	check_eq(drops.size(), 2, "Herzcontainer und Kugel fallen heraus")

	# Kugel aufheben: wird hochgehalten
	var orb: Node2D = null
	for d in drops:
		if d is OrbPickup:
			orb = d
	if orb:
		player.global_position = orb.global_position
		await frames(3)
		check_eq(GameState.orbs.size(), 1, "Kugel eingesammelt")
		check(get_tree().paused, "Kugel wird hochgehalten (Pause)")
		check_eq(hud.get_node("%MessageLabel").text, "Du hast eine magische Kugel gefunden! (1 von 3)", "Kugel-Meldung")
		for i in 200:
			await frames(1)
			if not get_tree().paused:
				break

	# Raum verlassen und zurück: Boss bleibt besiegt, Tür offen
	await game.change_room(ROOM2, &"from_boss_room")
	await game.change_room(BOSS_ROOM, &"from_room_2")
	await frames(40)
	check(not game.current_room.has_node("ZombieKing"), "Boss bleibt besiegt")
	check(not (game.current_room.get_node("RoomLock") as RoomLock).is_locked, "Bossraum bleibt offen")
	check(not hud.get_node("%BossPanel").visible, "Keine Boss-Leiste mehr")
	game.queue_free()
