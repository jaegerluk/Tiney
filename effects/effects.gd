class_name Effects
extends RefCounted
## Kleine Effekte für das Spielgefühl. Partikel als einmalige CPUParticles2D, die sich selbst entfernen.
## Trefferstopp und Bildschirmwackeln laufen über die Gruppe "game_feel" (Game), damit Auslöser
## Game nicht kennen müssen.

const GAME_FEEL_GROUP := &"game_feel"


## Kurzer Partikelausbruch an `position` (lokale Koordinaten von `parent`).
static func burst(parent: Node, position: Vector2, color: Color, amount: int = 8,
		speed: float = 45.0, lifetime: float = 0.35, size: float = 2.0) -> CPUParticles2D:
	if parent == null:
		return null
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = amount
	particles.lifetime = lifetime
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 120)
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.scale_amount_min = size
	particles.scale_amount_max = size
	particles.color = color
	particles.z_index = 5
	parent.add_child.call_deferred(particles)
	particles.ready.connect(func() -> void: particles.emitting = true)
	particles.finished.connect(particles.queue_free)
	return particles


## Spiel kurz einfrieren (Treffer).
static func hit_stop(tree: SceneTree, duration: float = 0.06) -> void:
	tree.call_group(GAME_FEEL_GROUP, "hit_stop", duration)


## Bildschirm wackeln lassen (Stärke in Pixeln).
static func shake(tree: SceneTree, strength: float = 2.0, duration: float = 0.15) -> void:
	tree.call_group(GAME_FEEL_GROUP, "shake", strength, duration)
