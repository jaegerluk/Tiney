class_name Player
extends CharacterBody2D
## Der Held: Bewegung in 8 Richtungen, Blickrichtung in 4 Richtungen, Schwertangriff mit Hitbox.

signal health_changed(current: int, maximum: int)
signal died

## Lebenspunkte pro Herz. ½ Herz = 10 LP. Feine Einheit, damit skalierter Schaden sauber passt.
const HP_PER_HEART := 20

## Pixel pro Sekunde.
@export var move_speed: float = 90.0
## In Lebenspunkten (LP): 60 = 3 Herzen.
@export var max_health: int = 60
@export var inventory: Inventory
## Abstand der Schwert-Hitbox vom Mittelpunkt in Blickrichtung.
@export var sword_reach: float = 12.0
## Sekunden Unverwundbarkeit nach einem Treffer.
@export var invincible_time: float = 1.0
## Sekunden ohne Steuerung beim Rückstoß.
@export var knockback_time: float = 0.2

var health: int
## Debug: kein Schaden.
var god_mode: bool = false
## Immer eine der vier Grundrichtungen.
var facing: Vector2 = Vector2.DOWN
## Aktuelle Laufeingabe (null, wenn gesperrt oder beim Angriff). Für Türen, Schieben usw.
var move_input: Vector2 = Vector2.ZERO
## Letzte Position auf sicherem Boden (nicht über einem Loch).
var last_safe_position: Vector2 = Vector2.ZERO

var _attacking: bool = false
var _controls_enabled: bool = true
var _hazards: int = 0
var _falling: bool = false
var _fall_tween: Tween = null
var _invincible_left: float = 0.0
var _knockback_left: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _anim_tree: AnimationTree = $AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _anim_tree.get("parameters/playback")
@onready var _sword_hitbox: Hitbox = $SwordHitbox
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	health = max_health
	_anim_tree.animation_finished.connect(_on_animation_finished)
	_sword_shape.disabled = true
	_hurtbox.hurt.connect(_on_hurt)
	_set_facing(facing)


func _process(delta: float) -> void:
	if _invincible_left > 0.0:
		_invincible_left -= delta
		_sprite.visible = _invincible_left <= 0.0 or int(_invincible_left * 20.0) % 2 == 0
		if _invincible_left <= 0.0:
			_hurtbox.recheck()


func _physics_process(delta: float) -> void:
	move_input = Vector2.ZERO
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, _knockback_velocity.length() * delta * 5.0)
	elif not _controls_enabled:
		velocity = Vector2.ZERO
		_playback.travel("idle")
	elif _attacking:
		velocity = Vector2.ZERO
	else:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		move_input = input
		velocity = input * move_speed
		if input != Vector2.ZERO:
			_set_facing(_facing_from(input))
		if Input.is_action_just_pressed("use_item") and inventory:
			inventory.use_selected(self)
		if Input.is_action_just_pressed("attack"):
			_start_attack()
		else:
			_playback.travel("walk" if input != Vector2.ZERO else "idle")
	move_and_slide()
	if _hazards == 0 and not _falling:
		last_safe_position = global_position


## Nimmt einen Gegenstand ins Inventar auf. Gibt false zurück, wenn kein Platz frei ist.
func collect(item: Item) -> bool:
	return inventory != null and inventory.insert(item)


func take_damage(amount: int) -> void:
	if health <= 0 or god_mode:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()


func is_invincible() -> bool:
	return _invincible_left > 0.0


## Volles Leben, keine Nachwirkungen von Treffern (z. B. nach dem Tod).
func revive() -> void:
	health = max_health
	_invincible_left = 0.0
	_knockback_left = 0.0
	_sprite.visible = true
	health_changed.emit(health, max_health)


## Herzcontainer: mehr Maximum, Leben ganz aufgefüllt.
func add_max_health(amount: int) -> void:
	max_health += amount
	health = max_health
	health_changed.emit(health, max_health)


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func is_attacking() -> bool:
	return _attacking


## Sperrt die Steuerung, z. B. während eines Raumwechsels.
func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled


## Hält ein Item über den Kopf (null = wieder normal). Während des Hochhaltens ist das Spiel pausiert.
func hold_up(icon: Texture2D) -> void:
	var held: Sprite2D = $HeldItem
	held.texture = icon
	held.visible = icon != null
	if icon != null:
		_sprite.flip_h = false
		_sprite.frame = 0


## Füße (für Löcher und Ähnliches).
func feet_position() -> Vector2:
	return global_position + Vector2(0, 4)


## Von Löchern aufgerufen: Bereich betreten/verlassen, in dem kein sicherer Boden ist.
func hazard_entered() -> void:
	_hazards += 1


func hazard_exited() -> void:
	_hazards = maxi(_hazards - 1, 0)


func is_falling() -> bool:
	return _falling


## Fällt: Steuerung aus, schrumpft und verschwindet. Danach land_at() oder ein Raumwechsel.
func fall() -> void:
	if _falling:
		return
	_falling = true
	_controls_enabled = false
	velocity = Vector2.ZERO
	_fall_tween = create_tween()
	_fall_tween.tween_property(_sprite, "scale", Vector2(0.1, 0.1), 0.4)
	await _fall_tween.finished
	# Inzwischen woanders gelandet (Tod, Raumwechsel)? Dann nicht mehr verstecken.
	if _falling:
		_sprite.visible = false


## Darf gerade in ein Loch fallen (nicht schon fallend, steuerbar, lebendig).
func can_fall() -> bool:
	return not _falling and _controls_enabled and health > 0


## Nach einem Sturz ohne Zielraum: kurz Pause, dann wieder steuerbar und kurz unverwundbar.
func recover_from_fall(position_: Vector2, lock_time: float = 0.4) -> void:
	land_at(position_, false)
	_invincible_left = invincible_time
	await get_tree().create_timer(lock_time, false).timeout
	if not _falling and health > 0:
		_controls_enabled = true


## An einer Position (wieder) normal erscheinen, z. B. nach einem Sturz oder Raumwechsel.
## enable_controls = false, wenn der Aufrufer die Steuerung selbst wieder freigibt (Raumwechsel).
func land_at(position_: Vector2, enable_controls: bool = true) -> void:
	if _fall_tween:
		_fall_tween.kill()
		_fall_tween = null
	global_position = position_
	last_safe_position = position_
	_hazards = 0
	_sprite.scale = Vector2.ONE
	_sprite.visible = true
	if _falling and enable_controls:
		_controls_enabled = true
	_falling = false


## Dreht den Spieler in eine der vier Grundrichtungen.
func face(direction: Vector2) -> void:
	_set_facing(direction)


## Bei Diagonalen bleibt die Blickrichtung erhalten, wenn sie Teil der Diagonale ist (wie in ALttP).
func _facing_from(input: Vector2) -> Vector2:
	var horizontal := Vector2(signf(input.x), 0.0)
	var vertical := Vector2(0.0, signf(input.y))
	var diagonal := absf(input.x) > 0.1 and absf(input.y) > 0.1
	if diagonal and (facing == horizontal or facing == vertical):
		return facing
	return horizontal if absf(input.x) >= absf(input.y) else vertical


func _set_facing(direction: Vector2) -> void:
	facing = direction
	_sprite.flip_h = direction.x < 0.0
	for state in ["idle", "walk", "attack"]:
		_anim_tree.set("parameters/%s/blend_position" % state, direction)
	_sword_hitbox.position = direction * sword_reach
	_sword_hitbox.rotation = direction.angle()


func _start_attack() -> void:
	_attacking = true
	_sword_shape.set_deferred("disabled", false)
	_playback.travel("attack")


func _on_hurt(hitbox: Hitbox) -> void:
	if is_invincible() or health <= 0:
		return
	_knockback_velocity = hitbox.knockback_direction(global_position) * hitbox.knockback
	_knockback_left = knockback_time
	_invincible_left = invincible_time
	take_damage(hitbox.damage)


func _on_animation_finished(anim_name: StringName) -> void:
	if String(anim_name).begins_with("attack"):
		_attacking = false
		_sword_shape.set_deferred("disabled", true)
