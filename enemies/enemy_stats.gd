class_name EnemyStats
extends Resource
## Basiswerte eines Gegnertyps bei Standard-Schwierigkeit (4,0). Skaliert wird in Enemy über Difficulty.

@export var max_health: int = 2
## In halben Herzen.
@export var damage: int = 1
## Pixel pro Sekunde.
@export var move_speed: float = 40.0
## 0 = voller Rückstoß, 1 = kein Rückstoß.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
