class_name ZombieKing
extends Enemy
## Boss: Zombie-König. Wartet bis activate() (z. B. wenn sich die Bossraum-Tür schließt).
## Schlurft auf den Spieler zu, kündigt Sturmangriffe an, ruft bei halbem Leben Zombies.
## Nach dem Sieg: Belohnungen fallen heraus, gerufene Zombies verschwinden.

signal boss_appeared(boss: Enemy)

enum State { WALK, TELEGRAPH, CHARGE }

## Sturmangriff: Tempo in px/s (bei 4,0), Ankündigung und Dauer in Sekunden.
@export var charge_speed: float = 130.0
@export var telegraph_time: float = 0.5
@export var charge_time: float = 0.6
## Pause zwischen Sturmangriffen (Zufall zwischen min und max).
@export var charge_interval_min: float = 2.5
@export var charge_interval_max: float = 4.0
@export var minion_scene: PackedScene
@export var minion_count: int = 2
## Belohnungen beim Sieg (Pickup-Szenen), z. B. Herzcontainer und Kugel.
@export var rewards: Array[PackedScene] = []
@export var step_time: float = 0.3

var active: bool = false
var _state: State = State.WALK
var _timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _summoned: bool = false
var _minions: Array[Node] = []
var _step: float = 0.0


func activate() -> void:
	if active or _dead:
		return
	active = true
	_timer = randf_range(charge_interval_min, charge_interval_max)
	boss_appeared.emit(self)


func state_name() -> String:
	return State.keys()[_state]


func _ai_velocity(delta: float) -> Vector2:
	var player := find_player()
	if not active or player == null:
		return Vector2.ZERO
	_timer -= delta
	_sprite.offset.x = 0.0
	match _state:
		State.WALK:
			if _timer <= 0.0:
				_state = State.TELEGRAPH
				_timer = telegraph_time
				return Vector2.ZERO
			_animate(delta)
			var direction := global_position.direction_to(player.global_position)
			_sprite.flip_h = direction.x < 0.0
			return direction * move_speed
		State.TELEGRAPH:
			_sprite.offset.x = 1.0 if int(_timer * 30.0) % 2 == 0 else -1.0
			if _timer <= 0.0:
				_state = State.CHARGE
				_timer = charge_time
				_charge_direction = global_position.direction_to(player.global_position)
			return Vector2.ZERO
		State.CHARGE:
			_animate(delta * 3.0)
			if _timer <= 0.0:
				_state = State.WALK
				_timer = randf_range(charge_interval_min, charge_interval_max)
			return _charge_direction * charge_speed * (move_speed / maxf(stats.move_speed, 1.0))
	return Vector2.ZERO


func _on_hurt(hitbox: Hitbox) -> void:
	super(hitbox)
	if not _dead and not _summoned and health * 2 <= max_health:
		_summon()


func _animate(delta: float) -> void:
	_step += delta
	if _step >= step_time:
		_step = 0.0
		_sprite.frame = 1 - _sprite.frame


func _summon() -> void:
	_summoned = true
	if minion_scene == null:
		return
	for i in minion_count:
		var minion: Node2D = minion_scene.instantiate()
		var side := -1.0 if i % 2 == 0 else 1.0
		minion.position = position + Vector2(side * 40.0, 0.0)
		_minions.append(minion)
		get_parent().add_child.call_deferred(minion)


func _on_died() -> void:
	for minion in _minions:
		if is_instance_valid(minion) and minion is Enemy and not (minion as Enemy).is_dead():
			minion.queue_free()
	for i in rewards.size():
		var offset := Vector2((i - (rewards.size() - 1) / 2.0) * 20.0, 0.0)
		DropTable.spawn_scene(rewards[i], get_parent(), position + offset)
