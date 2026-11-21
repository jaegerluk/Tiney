# Tiney – Projektregeln

Kleines Top-down-Action-Adventure im Stil von *A Link to the Past*, gebaut mit Godot 4.7 und GDScript.
Spieldesign, Umfang und Meilensteine: **[docs/design.md](docs/design.md)**. Dieses Dokument enthält nur Technik und Arbeitsweise.

## Arbeitsweise
- Antworten auf Deutsch, direkt und knapp.
- Kleine, testbare Schritte, ein Feature nach dem anderen. Nach jedem Schritt headless prüfen, danach testet der Nutzer im Editor.
- Nach jedem abgeschlossenen Schritt ein Commit mit klarer deutscher Nachricht. **Pushen nur auf Anweisung.**
- Wichtige Entscheidungen immer hier (Technik) oder in `docs/design.md` (Spiel) festhalten, nicht nur im Chat.
- Der Godot-Editor darf offen sein. Ausnahme: Bei Änderungen an `project.godot` sollte er geschlossen sein, sonst überschreibt er die Datei beim Speichern.

## Headless prüfen
```bash
godot --headless --editor --quit          # Import, .uid-Dateien, Parser-Fehler
godot --headless --quit-after 120         # Hauptszene ~2 s laufen lassen
```
Die Ausgabe darf kein `ERROR` und kein `SCRIPT ERROR` enthalten. Meldungen über „leaked“ RIDs beim Beenden sind harmlos.
`--script` ist für Prüfungen ungeeignet: Dort sind Autoloads nicht geladen, und `ResourceSaver` entfernt UIDs.

## Ordnerstruktur (nach Features)
| Ordner | Inhalt |
|---|---|
| `autoload/` | Singletons: Schwierigkeit, Raumwechsel, Audio, Spielstand |
| `player/` | Spielerszene, Zustände, Hitbox/Hurtbox |
| `enemies/` | ein Unterordner pro Gegnertyp, Basiswerte als `.tres` |
| `objects/` | Schalter, Türen, Truhen, Schilder, Treppen |
| `items/` | Inventar-Logik, Item-Ressourcen, Pickups |
| `ui/` | HUD, Lebensanzeige, Inventar-/Menü-UI |
| `world/` | Räume je Gebiet: `test_area/`, `hub/`, `dungeon_1/` … |
| `assets/` | Grafik und Audio, nur genutzte Dateien, Quellen in `assets/CREDITS.md` |
| `docs/` | Design-Dokument |

Szene und Skript liegen zusammen und tragen denselben Namen (`player/player.tscn`, `player/player.gd`).
Objekte und Gegner bekommen je einen Unterordner (`objects/floor_switch/floor_switch.tscn`).

## Konventionen
- **Benennung:** Dateien und Ordner in `snake_case`, `class_name` in `PascalCase`, Signale im Präteritum (`opened`, `health_changed`), private Member mit `_`-Präfix.
- **Statische Typisierung**, wo sinnvoll: `var speed: float = 80.0`, `func take_damage(amount: int) -> void`.
- **Signale nach oben, Aufrufe nach unten:** Kinder kennen ihre Eltern nicht. Querverbindungen laufen über Signale, die im Editor oder in der Elternszene verbunden werden. Keine `get_node("../..")`-Ketten.
- **Gruppen oder `class_name` statt `has_method`:** z. B. `body is Player` oder `body.is_in_group("player")`.
- **Physik statt `position +=`:** Bewegte Figuren sind `CharacterBody2D` und bewegen sich mit `velocity` und `move_and_slide()`.
- **Kampf über Hitbox/Hurtbox** (`Area2D` auf eigenen Kollisionsebenen), nie über globale Flags.
- **Kollisionsebenen** (benannt in `project.godot`):

  | Nr. | Name | Wer liegt darauf |
  |---|---|---|
  | 1 | `world` | Wände, geschlossene Türen, feste Objekte |
  | 2 | `player` | Spielerkörper |
  | 3 | `enemies` | Gegnerkörper |
  | 4 | `player_attack` | Schwert-Hitbox des Spielers |
  | 5 | `enemy_attack` | Gegner-Hitboxen |
  | 6 | `triggers` | Pickups, Schalter, Schilder, Ausgänge (Maske: `player`) |
- **Keine globalen Zustands-Flags** für einzelne Übergänge. Raumwechsel laufen datengetrieben über Ausgänge mit Ziel-Raum und Ziel-Marker.
- `@export` für alles, was im Editor eingestellt werden soll. Keine Zahlen fest im Code, die Design-Werte sind.

## Schwierigkeit (Kernmechanik, siehe design.md)
- Zentraler Wert `difficulty` (1,0–10,0) in einem Autoload.
- **Gegnerwerte nie fest verdrahten:** Basiswerte stehen in einer Resource (`.tres`). Effektiver Wert = Basiswert × Multiplikator(d) aus dem Autoload, getrennt nach Leben, Schaden und Tempo.
- **Raumvarianten:** Optionale Gegner und Hindernisse bekommen `min_tier: int` und erscheinen erst ab dieser ganzzahligen Stufe. Eine Szene pro Raum, keine Kopien.

## Technische Eckdaten
- Interne Auflösung 256×224, 16×16-Tiles. Ganzzahlige Skalierung (Stretch-Modus `viewport`, Skalierung `integer`), Texturfilter Nearest.
- Renderer: GL Compatibility.
- Fenster startet mit 1024×896 (×4). Snap von 2D-Transforms und Vertices auf Pixel ist an.
- Eingaben nur über Aktionen der Input-Map (Tastatur und Gamepad), nie über Tastencodes im Code.
  Gamepad nach Position, SNES-artig (Angriff unten, Interaktion rechts, Item links):

  | Aktion | Tastatur | Gamepad |
  |---|---|---|
  | `move_up/down/left/right` | WASD, Pfeiltasten | Steuerkreuz, linker Stick |
  | `attack` | J, Leertaste | unten (Xbox A) |
  | `interact` | K, E | rechts (Xbox B) |
  | `use_item` | L, Q | links (Xbox X) |
  | `menu` | Esc, Tab | Start |

  Die Aktionen `up/down/left/right/inventory` gehören zum alten Prototyp und fallen mit ihm weg.
- Git: `core.fileMode=false` (Rechtewechsel 644→755 ist Rauschen). `.godot/` wird ignoriert, `.uid`-Dateien werden eingecheckt.

## Aktueller Stand
- Godot 4.7, Ordnerstruktur angelegt, pixelgenaue Einstellungen gesetzt.
- Der alte Prototyp ist entfernt. Er bleibt unter dem Tag `prototyp-alt` erreichbar (`git show prototyp-alt:<pfad>`).
- Hauptszene: `world/test_area/test_area.tscn` (2×2 Bildschirme). Darin: Spieler, `RoomCamera` mit Grenzen, Schalter → Tür, Schild, Äpfel, HUD mit Lebensanzeige und Inventar.
- Übernommen und neu aufgebaut: `Player` (Bewegung, Blickrichtung, Schwert-Hitbox, Leben), `Inventory`/`Item`/`Pickup`, `InventoryUI`, `HealthBar`, `FloorSwitch`, `SwitchDoor`, `SignPost`, `RoomCamera`.
- Noch nicht vorhanden: Gegner, Raumwechsel, Treppen, Schlüssel, Schwierigkeits-Autoload.

## Entscheidungen
- **Neuaufbau statt Weiterbau** des Prototyps. Übernommen werden Inventar, Schalter/Tür, Spieler-Animationen, Kamera-Grenzen, Schild und Lebensanzeige. Neu geschrieben werden Raumwechsel, Kampf und Gegner.
- **Beim Upgrade auf 4.7 nicht alle Szenen per Skript neu gespeichert**, weil dabei UIDs verloren gingen. Szenen werden im Editor beim nächsten Speichern im neuen Format geschrieben.
- **Alle Grafiken sind Platzhalter.** Eigene Pixel-Art kommt, wenn die Mechaniken stehen.
- **Leben in halben Herzen** (`max_health = 6` = 3 Herzen). Die `HealthBar` ist ein Platzhalter für eine Herzanzeige.
- **Schilder liest man mit `interact`**, wenn man davor steht und nach oben schaut (wie in ALttP). Im Prototyp erschien der Text automatisch.
- **Das Inventar-Menü pausiert das Spiel** (`InventoryUI` läuft mit `process_mode = Always`).
