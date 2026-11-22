# Tiney – Projektregeln

Kleines Top-down-Action-Adventure im Stil von *A Link to the Past*, gebaut mit Godot 4.7 und GDScript.
Spieldesign, Umfang und Meilensteine: **[docs/design.md](docs/design.md)**. Dieses Dokument enthält nur Technik und Arbeitsweise.

## Arbeitsweise
- Antworten auf Deutsch, direkt und knapp.
- Kleine, testbare Schritte, ein Feature nach dem anderen. Nach jedem Schritt headless prüfen, danach testet der Nutzer im Editor.
- Nach jedem abgeschlossenen Schritt ein Commit mit klarer deutscher Nachricht. **Pushen nur auf Anweisung.**
- Wichtige Entscheidungen immer hier (Technik) oder in `docs/design.md` (Spiel) festhalten, nicht nur im Chat.
- **Design-Entscheidungen erfragen:** Alles, was der Spieler sieht oder spürt (Inhalte, Werte, Drops, Platzierung, Verhalten), vor dem Umsetzen kurz mit einer Zwischenfrage klären, mit Empfehlung. Technische Details selbst entscheiden.
- Der Godot-Editor darf offen sein. Ausnahme: Bei Änderungen an `project.godot` sollte er geschlossen sein, sonst überschreibt er die Datei beim Speichern.

## Headless prüfen
```bash
godot --headless --editor --quit          # Import, .uid-Dateien, Parser-Fehler
godot --headless --quit-after 120         # Hauptszene ~2 s laufen lassen
godot --headless --fixed-fps 60 --path . tests/run_tests.tscn               # alle Tests
godot --headless --fixed-fps 60 --path . tests/run_tests.tscn -- test_rooms # einzelne Tests
```
Die Ausgabe darf kein `ERROR` und kein `SCRIPT ERROR` enthalten. Meldungen über „leaked“ RIDs beim Beenden sind harmlos.
Der Test-Runner endet mit `ALLE TESTS OK` (Exit-Code 0) oder listet die fehlgeschlagenen Tests (Exit-Code 1).
`--script` ist für Prüfungen ungeeignet: Dort sind Autoloads nicht geladen, und `ResourceSaver` entfernt UIDs.

**Tests schreiben:** `tests/test_<thema>.gd` mit `extends TestCase`, `run()` überschreiben (darf `await` nutzen).
Hilfen: `check`, `check_eq`, `frames(n)`, `hold(action)`, `tap(action)`. Der Runner setzt vor jedem Test
`GameState`, `Difficulty`, Eingaben und Pause zurück. Neue Features bekommen einen Test.

## Ordnerstruktur (nach Features)
| Ordner | Inhalt |
|---|---|
| `autoload/` | Singletons: `Difficulty`, `GameState` (später Audio, Speichern) |
| `combat/` | `Hitbox`, `Hurtbox` |
| `player/` | Spielerszene, Zustände, Hitbox/Hurtbox |
| `enemies/` | ein Unterordner pro Gegnertyp, Basiswerte als `.tres` |
| `npcs/` | Harmlose Figuren (Kuh …), ein Unterordner pro Typ |
| `objects/` | Schalter, Türen, Truhen, Schilder, Treppen |
| `items/` | Inventar-Logik, Item-Ressourcen, `pickups/`, `drops/` (DropTables) |
| `ui/` | HUD, Lebensanzeige, Inventar-/Menü-UI |
| `world/` | `game.tscn` (Hauptszene), `Room`, `RoomEntry`, Räume je Gebiet: `test_area/`, `hub/`, `dungeon_1/` … |
| `assets/` | Grafik und Audio, nur genutzte Dateien, Quellen in `assets/CREDITS.md` |
| `docs/` | Design-Dokument |
| `tests/` | Headless-Tests und Runner |
| `tools/` | Hilfsskripte außerhalb von Godot (z. B. `make_placeholders.py`) |

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
  | 6 | `triggers` | Pickups, Schalter, Schilder, Statuen, Ausgänge (Maske: `player`) |
  | 7 | `npcs` | NPC-Körper (Kuh). Spieler und Gegner maskieren `world` + `npcs` |
- **Keine globalen Zustands-Flags** für einzelne Übergänge. Raumwechsel laufen datengetrieben über Ausgänge mit Ziel-Raum und Ziel-Marker.
- `@export` für alles, was im Editor eingestellt werden soll. Keine Zahlen fest im Code, die Design-Werte sind.

## Raumsystem
- `world/game.tscn` ist die Hauptszene: Spieler, `RoomCamera`, HUD und Überblendung bleiben bestehen. Nur der Raum unter `RoomHolder` wird getauscht (`Game.change_room(pfad, eingang)`).
- Jede Raumszene hat als Wurzel ein `Room` (`world/room.gd`) mit `dungeon_id`, zwei Kamera-Markern und einem Knoten `Entries` mit `RoomEntry`-Markern. Der Knotenname eines Eingangs ist seine ID.
- Ausgänge sind `RoomExit`-Instanzen (`target_room`, `target_entry`). Eingänge so legen, dass der Spieler beim Ankommen nicht schon in einem Ausgang steht.
- **Nichts erscheint neu.** Platzierte Pickups, Krüge/Gras, Gegner und Schlüsseltüren merken sich über `GameState.mark_gone(self)` / `is_gone(self)`, dass sie weg sind. Die ID ist `GameState.flag_id(self)` = Szenenpfad + Knotenpfad. Deshalb **Knoten mit Zustand nach dem Platzieren nicht mehr umbenennen.**
- Zustände wie Schalter speichert `GameState.set_value/get_value`. Ein `FloorSwitch` sendet seinen Zustand beim Laden erneut über `toggled`.
- Zur Laufzeit erzeugte Drops entstehen nur über `DropTable.spawn_scene()` (Gruppe `room_drops`). Game sichert sie beim Verlassen des Raums und erzeugt sie beim Betreten neu.
- **Speicherstatuen:** `SaveStatue` sendet `save_requested`, `Room` reicht es an `Game.save_game()` weiter. Der Spielstand besteht aus `GameState.snapshot()`, `Inventory.snapshot()`, Raum, Respawn-Position und Blickrichtung. Er liegt nur im Speicher. Der Start zählt als erster Spielstand. Beim Tod wird alles darauf zurückgesetzt, der Spieler bekommt volles Leben. Neue Zustände, die zurückgesetzt werden sollen, gehören deshalb in `GameState` (oder in einen eigenen Snapshot).
- Die Y-Sortierung ist in Game, RoomHolder und Raum aktiv. Boden hat `z_index = -10`, Wände `-5`.

## Dungeon-Objekte und Kampf
- **Pickups** erben von `Pickup` (`items/pickups/pickup.gd`) und überschreiben `_apply(player) -> bool`. `persistent = true` heißt: einmalig.
- **Schlüssel** gelten pro Dungeon (`GameState.keys(dungeon)`). Der HUD-Zähler zeigt den aktuellen Dungeon.
- **Großer Schlüssel** ebenfalls pro Dungeon (`GameState.big_keys()`), HUD-Symbol neben dem Zähler. Die Bosstür (`objects/boss_door`, eine `LockedDoor` mit `big_key = true`) verbraucht ihn.
- **Truhen** (`Chest`): `content` ist eine Pickup-Szene. Öffnen von jeder Seite mit `interact`. Zustand über `GameState.set_value`. Die Truhe sendet `item_presented(icon, message)` über `Room` an `Game.present_item()`: Spiel pausiert, der Held hält das Item hoch (`Player.hold_up`), das HUD zeigt die Meldung (`HUD.show_message`). Pickups liefern dafür `get_icon()` und `get_message()`.
- **Drops** über `DropTable`-Ressourcen (`items/drops/*.tres`): gewichtete Einträge plus `nothing_weight`.
- **Gegner** erben von `Enemy` (`enemies/enemy.gd`), Basiswerte in `EnemyStats` (`enemies/<typ>/<typ>_stats.tres`). Verhalten in `_ai_velocity()`.
- **Krüge/Gras:** `fixed_drop` (fester Inhalt) hat Vorrang vor `drop_table` (Zufall). Ohne beides kommt nichts.
- **Böden** als `TileMapLayer` „Floor“ mit `assets/tilesets/basic_tileset.tres` (z_index −10).
- **Hitbox/Hurtbox:** Spieler-Hurtbox maskiert `enemy_attack`, Gegner-, NPC- und Zerbrechbares-Hurtboxen maskieren `player_attack`. Nach der Unverwundbarkeit prüft `Hurtbox.recheck()` noch überlappende Hitboxen.

## Schwierigkeit (Kernmechanik, siehe design.md)
- Autoload `Difficulty`: `value` (1,0–10,0, Standard **4,0** = Basiswerte), `multiplier(stat)` = k^(d − 4) mit k in `Difficulty.GROWTH` (Leben 1.15, Schaden 1.15, Tempo 1.04), `scaled_int()` rundet und gibt mindestens 1, `tier()` = ganzzahlige Stufe.
- **Gegnerwerte nie fest verdrahten:** Basiswerte stehen in einer Resource (`.tres`). Effektiver Wert = Basiswert × Multiplikator(d) aus dem Autoload, getrennt nach Leben, Schaden und Tempo.
- **Raumvarianten:** Optionale Gegner und Hindernisse bekommen `min_tier: int` und erscheinen erst ab dieser ganzzahligen Stufe. Eine Szene pro Raum, keine Kopien. `Room.apply_tier()` entfernt sie beim Laden. Jeder Knoten mit einer Eigenschaft `min_tier` wird berücksichtigt.

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
- Hauptszene: `world/game.tscn`, Startraum `world/test_area/test_area.tscn` (2×2 Bildschirme), verbunden mit `test_room_2.tscn` (Dungeon `test`).
- Testbereich (Steinboden): Speicherstatue, Truhe (roter Rubin), Schalter → Tür, Schild, Äpfel, Rubine (1/5/20), Herz, Schlüssel, Krüge (Pot3 enthält einen Schlüssel), Gras, Kuh, zwei Schleime und ein dritter ab Stufe 6. In Raum 2: Schlüsseltür, dahinter Truhe mit großem Schlüssel und Bosstür in der Südwand. Dahinter `test_boss_room.tscn` (Platzhalter).
- Vorhanden: `Player` (Bewegung, Schwert, Leben, Rückstoß, Unverwundbarkeit), Inventar, Pickups, HUD (Leben, Rubine, Schlüssel), Raumwechsel mit Überblendung, Persistenz (nichts erscheint neu), Speicherstatuen, Schlüsseltüren, Truhen, großer Schlüssel und Bosstür, Krüge/Gras mit festem oder zufälligem Inhalt, Gegner-Basis und Schleim, Kuh, Lebensanzeige in Herz-Abschnitten, Steinboden-TileSet, Schwierigkeit mit Raumvarianten, Headless-Tests.
- Noch nicht vorhanden: Boss, große Truhen, Treppen, Scrollen zwischen Bildschirmen, Game Over, Speichern auf Festplatte mit Titelmenü, Heben und Werfen, Sound, Wand-Tiles.

## Entscheidungen
- **Neuaufbau statt Weiterbau** des Prototyps. Übernommen werden Inventar, Schalter/Tür, Spieler-Animationen, Kamera-Grenzen, Schild und Lebensanzeige. Neu geschrieben werden Raumwechsel, Kampf und Gegner.
- **Beim Upgrade auf 4.7 nicht alle Szenen per Skript neu gespeichert**, weil dabei UIDs verloren gingen. Szenen werden im Editor beim nächsten Speichern im neuen Format geschrieben.
- **Alle Grafiken sind Platzhalter.** Eigene Pixel-Art kommt, wenn die Mechaniken stehen.
- **Leben in halben Herzen** (`max_health = 6` = 3 Herzen). Die `HealthBar` ist ein Platzhalter für eine Herzanzeige.
- **Schilder liest man mit `interact`**, wenn man davor steht und nach oben schaut (wie in ALttP). Im Prototyp erschien der Text automatisch.
- **Das Inventar-Menü pausiert das Spiel** (`InventoryUI` läuft mit `process_mode = Always`).
- **Persistente Hauptszene** statt `change_scene_to_file`: Spieler und HUD überleben den Raumwechsel; später lässt sich Scrollen zwischen Räumen ergänzen.
- **Tod:** Alles auf den Stand der letzten Speicherstatue (Welt, Rubine, Schlüssel, Inventar), volles Leben an der Statue. Die Statue selbst heilt nicht.
- **Spieler und Gegner kollidieren nicht miteinander**, nur ihre Hitboxen/Hurtboxen wirken (wie ALttP). NPCs wie die Kuh blockieren dagegen.
- **Platzhalter-Sprites** für Rubine, Schlüssel, Herz, Krug, Gras, Schlüsseltür, Statue und Steinboden erzeugt `tools/make_placeholders.py`.
