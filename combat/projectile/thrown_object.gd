class_name ThrownObject
extends Projectile
## Geworfener Gegenstand (Krug, Stein). Fliegt im kleinen Bogen `max_distance` weit und zerbricht
## beim Aufprall (Wand, Gegner, Schalter, Boden). Inhalt (fester Drop oder Zufall) fällt dort heraus.

@export var max_distance: float = 64.0
@export var debris_color: Color = Color(0.67, 0.4, 0.24)
@export var fixed_drop: PackedScene
@export var drop_table: DropTable
## Höhe beim Abwurf (über dem Kopf) und Bogenhöhe in Pixeln.
@export var start_height: float = 20.0
@export var arc_height: float = 6.0

var _traveled: float = 0.0
var _shattered: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	rotation = 0.0
	_update_arc()


func _physics_process(delta: float) -> void:
	if _shattered:
		return
	super(delta)
	_traveled += speed * delta
	_update_arc()
	if _traveled >= max_distance:
		_shatter()


func _update_arc() -> void:
	var t := clampf(_traveled / maxf(max_distance, 1.0), 0.0, 1.0)
	_sprite.offset.y = -lerpf(start_height, 2.0, t) - sin(t * PI) * arc_height


func _stick() -> void:
	_shatter()


func _destroy() -> void:
	_shatter()


func _shatter() -> void:
	if _shattered:
		return
	_shattered = true
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	var parent := get_parent()
	Effects.burst(parent, position, debris_color, 10, 55.0, 0.4, 2.0)
	if fixed_drop:
		DropTable.spawn_scene(fixed_drop, parent, position)
	elif drop_table:
		drop_table.spawn(parent, position)
	destroyed.emit()
	queue_free()
