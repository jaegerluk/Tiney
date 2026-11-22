extends Node
## Schwierigkeit 1,0–10,0 (siehe docs/design.md). Autoload "Difficulty".
## Gegnerwerte: Basiswert × multiplier(stat). Bei NORMAL gelten die Basiswerte unverändert.
## Raumvarianten: Knoten mit `min_tier` erscheinen erst ab tier() >= min_tier.

signal changed(value: float)

enum Stat { HEALTH, DAMAGE, SPEED }

const MIN := 1.0
const MAX := 10.0
const NORMAL := 4.0
## Wachstum je Stat: m(d) = k^(d − NORMAL). Zum Balancing hier anpassen.
const GROWTH: Dictionary[Stat, float] = {
	Stat.HEALTH: 1.15,
	Stat.DAMAGE: 1.15,
	Stat.SPEED: 1.04,
}

var value: float = NORMAL:
	set(new_value):
		value = clampf(snappedf(new_value, 0.1), MIN, MAX)
		changed.emit(value)


## Ganzzahlige Stufe für Raumvarianten.
func tier() -> int:
	return floori(value)


func multiplier(stat: Stat) -> float:
	return pow(GROWTH[stat], value - NORMAL)


func scaled(base: float, stat: Stat) -> float:
	return base * multiplier(stat)


## Gerundet, mindestens 1. Für Leben und Schaden.
func scaled_int(base: int, stat: Stat) -> int:
	return maxi(1, roundi(scaled(base, stat)))
