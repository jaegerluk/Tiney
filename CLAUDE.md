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
**Commit nur, wenn der Runner mit Exit-Code 0 endet.** Den Exit-Code direkt prüfen, nicht über eine gefilterte Ausgabe (ein `grep` in der Befehlskette verdeckt Fehlschläge).
Ein Testskript, das sich nicht laden lässt (Parse-Fehler), zählt als fehlgeschlagen.
Er zählt über einen `Logger` (`tests/error_counter.gd`) auch Engine- und Skriptfehler während eines Tests als Fehlschlag, denn GDScript läuft nach einem Laufzeitfehler einfach weiter.
`--script` ist für Prüfungen ungeeignet: Dort sind Autoloads nicht geladen, und `ResourceSaver` entfernt UIDs.

**Tests schreiben:** `tests/test_<thema>.gd` mit `extends TestCase`, `run()` überschreiben (darf `await` nutzen).
Hilfen: `check`, `check_eq`, `frames(n)`, `hold(action)`, `tap(action)`. Der Runner setzt vor jedem Test
`GameState`, `Difficulty`, Eingaben und Pause zurück. Neue Features bekommen einen Test.

## Ordnerstruktur (nach Features)
| Ordner | Inhalt |
|---|---|
| `autoload/` | Singletons: `Difficulty`, `GameState` (später Audio, Speichern) |
| `combat/` | `Hitbox`, `Hurtbox`, `projectile/` (Geschosse, Pfeil) |
| `player/` | Spielerszene, Zustände, Hitbox/Hurtbox |
| `enemies/` | ein Unterordner pro Gegnertyp, Basiswerte als `.tres` |
| `npcs/` | Harmlose Figuren: `cow`, `talk_npc` (Dialog-NPC) |
| `objects/` | Schalter, Türen (Schlüssel, Boss, Gitter + `room_lock`), Truhen, Schilder, Statuen, Treppen, Löcher, Schiebeblöcke, Shop, `interact_zone` |
| `items/` | Inventar-Logik, Item-Ressourcen, `pickups/`, `drops/` (DropTables) |
| `ui/` | HUD, Lebensleiste, Dialogbox, Inventar-/Menü-UI |
| `world/` | `game.tscn` (Hauptszene), `Room`, `RoomEntry`, Räume je Gebiet: `test_area/`, `hub/`, `dungeon_1/` … |
| `assets/` | Grafik und Audio, nur genutzte Dateien, Quellen in `assets/CREDITS.md` |
| `docs/` | Design-Dokument |
| `tests/` | Headless-Tests und Runner |
| `debug/` | Debug-Menü (F1, nur in Debug-Läufen) |
| `effects/` | `Effects`: Partikel, Trefferstopp, Bildschirmwackeln |
| `tools/` | Hilfsskripte außerhalb von Godot: `make_placeholders.py` (Sprites), `room_builder.py` (Raumszenen mit Tiles), `tidy_tscn.py` (Reihenfolge in .tscn reparieren) |

Szene und Skript liegen zusammen und tragen denselben Namen (`player/player.tscn`, `player/player.gd`).
Objekte und Gegner bekommen je einen Unterordner (`objects/floor_switch/floor_switch.tscn`).

## Konventionen
- **Benennung:** Dateien und Ordner in `snake_case`, `class_name` in `PascalCase`, Signale im Präteritum (`opened`, `health_changed`), private Member mit `_`-Präfix.
- **Sprache:** Alle Texte, die der Spieler sieht (Dialoge, Schilder, Meldungen, Shop, Namen), sind **englisch**, direkt als Strings (kein Übersetzungssystem). Code-Kommentare, Tests, Commits und Doku bleiben deutsch.
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
  | 8 | `traps` | Körper von Klingenfallen (stoßen an Wände und einander, blockieren den Spieler nicht) |
- **Keine globalen Zustands-Flags** für einzelne Übergänge. Raumwechsel laufen datengetrieben über Ausgänge mit Ziel-Raum und Ziel-Marker.
- `@export` für alles, was im Editor eingestellt werden soll. Keine Zahlen fest im Code, die Design-Werte sind.

## Raumsystem
- `world/game.tscn` ist die Hauptszene: Spieler, `RoomCamera`, HUD und Überblendung bleiben bestehen. Nur der Raum unter `RoomHolder` wird getauscht (`Game.change_room(pfad, eingang)`).
- Jede Raumszene hat als Wurzel ein `Room` (`world/room.gd`) mit `dungeon_id`, zwei Kamera-Markern und einem Knoten `Entries` mit `RoomEntry`-Markern. Der Knotenname eines Eingangs ist seine ID.
- Ausgänge sind `RoomExit`-Instanzen (`target_room`, `target_entry`). Eingänge so legen, dass der Spieler beim Ankommen nicht schon in einem Ausgang steht.
- **Nichts erscheint neu.** Platzierte Pickups, Krüge/Gras, Gegner und Schlüsseltüren merken sich über `GameState.mark_gone(self)` / `is_gone(self)`, dass sie weg sind. Die ID ist `GameState.flag_id(self)` = Szenenpfad + Knotenpfad. Deshalb **Knoten mit Zustand nach dem Platzieren nicht mehr umbenennen.**
- Zustände wie Schalter speichert `GameState.set_value/get_value`. Ein `FloorSwitch` sendet seinen Zustand beim Laden erneut über `toggled`.
- Zur Laufzeit erzeugte Drops entstehen nur über `DropTable.spawn_scene()` (Gruppe `room_drops`). Game sichert sie beim Verlassen des Raums und erzeugt sie beim Betreten neu.
- **Speicherstatuen:** Die Statue steht in einer Pfütze (Area `Puddle`). Betreten speichert automatisch. `SaveStatue` sendet `save_requested`, `Room` reicht es an `Game.save_game()` weiter. Der Spielstand besteht aus `GameState.snapshot()`, `Inventory.snapshot()`, Raum, Respawn-Position und Blickrichtung. Er liegt nur im Speicher. Der Start zählt als erster Spielstand. Beim Tod wird alles darauf zurückgesetzt, der Spieler bekommt volles Leben. Neue Zustände, die zurückgesetzt werden sollen, gehören deshalb in `GameState` (oder in einen eigenen Snapshot).
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
- **Schalter:** `FloorSwitch` (Modus TOGGLE = grün, `floor_switch.tscn`; HOLD = orange, `hold_switch.tscn`: an, solange Spieler oder Block daraufstehen). `CrystalSwitch` reagiert auf Treffer, Modus TOGGLE (blau/rot), ONCE (grün → grau) oder TIMED (gelb, `duration`). Alle senden `toggled(is_on)`, verbunden in der Raumszene, z. B. mit `SwitchDoor.set_open`. Eine `SwitchDoor` darf mehrere Schalter haben, sie ist offen, solange mindestens einer an ist. **Keine Softlocks:** Wo eine Tür hinter dem Spieler zufallen kann (Zeitschalter), gehört ein Schalter auch auf die Innenseite. TOGGLE/ONCE bleiben gespeichert, HOLD/TIMED nicht.
- **Fallen:** `Spikes` (ALWAYS/TIMED, `phase_offset` für Wellen), `BladeTrap` (SENTRY stahlblau / PATROL bronze), `CrumbleFloor` (zerfällt zu einem `Pit`, zählt nicht als sicherer Boden, beim Wiederbetreten ganz, optional `regrow_time`). Fallenschaden ist ein Basiswert in LP und skaliert mit `Difficulty`. Taktende Stacheln und lauernde Klingenfallen sind nur auf dem Bildschirm aktiv (`RoomCamera.is_on_screen`). Achtung: Kindknoten addieren ihren `z_index` zum Elternknoten (das Loch in der Bröckelplatte braucht deshalb `z_index = 1`).
- **Gittertüren:** `RoomLock` mit `ShutterDoor`-Kindern. Gegner aus dem Inspector oder alle im Raum. Signale `locked`/`unlocked`, z. B. `locked` → `ZombieKing.activate`.
- **Geschosse:** `Projectile` (`combat/projectile/`), Team ENEMY/PLAYER setzt die Ebene der Hitbox. Treffer → verschwindet (`Hitbox.landed`), Wand → steckt `stick_time` fest. Schwert-Hitboxen mit `deflects_projectiles` zerstören gegnerische Geschosse (Startschwert: aus). Skelett-Schütze `Archer` (`enemies/archer/`): Abstand halten, in Linie zielen und schießen, nur auf dem Bildschirm.
- **Boss:** Gegner mit `display_name` und Signal `boss_appeared` (HUD-Leiste). Belohnungen als Pickup-Szenen (`rewards`). Kugeln in `GameState.orbs`.
- **Spielgefühl:** `Effects.burst()` für Partikel, `Effects.hit_stop()` / `Effects.shake()` rufen Game über die Gruppe `game_feel` (Trefferstopp über `Engine.time_scale`). Breakables haben `debris_color`.
- **Debug-Menü** (`debug/debug_menu.gd`, F1, zur Laufzeit angemeldet): Schwierigkeit, unverwundbar (`Player.god_mode`), Sachen geben, Teleport (`Game.teleport`), Raum zurücksetzen (`GameState.clear_room` + `Game.reload_room`), Gegner besiegen.
- **Hitbox/Hurtbox:** Spieler-Hurtbox maskiert `enemy_attack`, Gegner-, NPC- und Zerbrechbares-Hurtboxen maskieren `player_attack`. Nach der Unverwundbarkeit prüft `Hurtbox.recheck()` noch überlappende Hitboxen.

## Interaktion, Dialoge, Präsentation
- **`InteractZone`** (Area2D-Kind eines Objekts): „davorstehen, hinschauen, `interact`“. `facing_rule`: zum Objekt (`TOWARD_PARENT`) oder nach oben (`UP`). Genutzt von Truhe, Schild, NPC und Shop-Ware. Signale `interacted`, `player_entered`, `player_exited`.
- **Signale an Game über Room:** Jedes Objekt mit den Signalen `dialog_requested(pages, speaker, portrait)`, `item_presented(icon, message)` `boss_appeared(boss)`, `info_shown(text)` oder `info_hidden` wird automatisch verbunden, auch wenn es erst zur Laufzeit in den Raum kommt (`child_entered_tree`). Ausgänge, Treppen, Löcher (`fell_through`) und Statuen verbindet Room über ihre Klassen.
- **Dialog:** `Game.show_dialog()` pausiert das Spiel. Die `DialogBox` läuft mit `PROCESS_MODE_ALWAYS`.
- **Hochhalten:** `Game.present_item()` pausiert ~1 s, `Player.hold_up()`, `HUD.show_message()`. Pickups mit `present_on_pickup` (Herzcontainer, Kugel, großer Schlüssel) tun das auch beim Aufheben.
- Was das Spiel pausiert (Dialog, Präsentation, Menü, Bildschirm-Scroll), setzt `get_tree().paused`. Das Menü öffnet nicht, solange schon pausiert ist.

## Leben, Items, Shop
- **1 Herz = 20 LP** (`Player.HP_PER_HEART`), ½ Herz = 10. Gegnerschaden ist in LP angegeben, damit skalierter Schaden fein abgestuft ist. Gegnerleben zählt in Schwerthieben.
- **Items** (`Item`): `heal_amount`, `consumable`. Auswahl im Menü (`Inventory.selected`), Benutzen mit `use_item`. Heil-Items werden bei vollem Leben nicht verbraucht.
- **Shop:** Ein `Shop`-Knoten mit `ShopItem`-Kindern (Preis, Inhalt als Pickup-Szene oder `hint_pages`, Vorrat). Kaufen und Meldungen laufen über den Shop. Steht der Spieler vor einer Ware, zeigt das HUD `item_name`, Preis und `description` in der Info-Box (ohne Pause).

## Kamera, Treppen, Löcher, Blöcke
- **`RoomCamera`:** bildschirmweises Schieben (Bildschirm = Viewport 256×224), solange `Room.screen_scroll` an ist. Game pausiert dabei und rückt den Spieler `scroll_nudge` Pixel weiter. Sprünge über `teleport_distance` (Teleport, Sturz) lösen keinen Scroll aus, die Kamera springt mit.
- **Räume** möglichst als Vielfache von 256×224 bauen. Mitlaufende Kamera statt Schieben: am Raum `Screen Scroll` ausschalten.
- **Gegner** bleiben in Räumen mit Bildschirm-Scrollen in ihrem Start-Bildschirm (`Enemy.confine_rect`, gesetzt von Room).
- **Treppen** (`Stairs`) sind `RoomExit`s mit Sprite und kleinem Auslösebereich in der Mitte.
- **Löcher** (`Pit`, `@tool`, Größe im Inspector, komplett schwarz; mit `target_room` zusätzlich ein pulsierender Lichtschein, `glow_color`/`glow_strength`): mit `target_room` ein Stockwerk tiefer, sonst Schaden, etwas weiter weg von `Player.last_safe_position` abgesetzt, 0,4 s Sperre. Löcher wirken nur auf `Player.can_fall()`. `land_at()` bricht eine laufende Sturz-Animation ab (sonst bleibt der Spieler unsichtbar).
- **Schiebe- und Ziehblöcke:** `pullable` (Standard an; aus = nur schiebbar, dunkler). Ziehen: Interaktion halten (`Player.is_grab_held()`, `start_grab`/`end_grab`), dann wegziehen; Block und Held rücken ein Tile, wenn hinter dem Helden Platz ist.
- **Schiebeblöcke** sind `AnimatableBody2D`, denn ein per Code verschobener `StaticBody2D` löst keine zuverlässigen Überlappungen aus.

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
- Hauptszene: `world/game.tscn`. Startraum ist `world/test_area/test_area.tscn` (2×2 Bildschirme, Dungeon `test`).
- Testräume in `world/test_area/`:
  - `test_area` (Start): Statue, Truhe, Schalter + Schiebeblock → Tür, Schild, Rubine, Herz, Schlüssel, Krüge (Pot3 mit Schlüssel), Gras, Kuh, Loch, Schleime, Zombie.
    Ausgänge: Nordwand → `test_shop`, Ostwand unten rechts → `test_arena`, Südwand → `test_room_2`.
  - `test_room_2`: Gefangener (Dialog), Loch → `test_cellar`, Treppe → `test_cellar`, Schlüsseltür, Truhe mit großem Schlüssel, Bosstür → `test_boss_room`.
  - `test_shop`: Ladenbesitzer, Ware auf der Theke.
  - `test_arena`: Gittertür (RoomLock), Zombie, 2 Schleime.
  - `test_boss_room`: Zombie-König hinter Gittertür.
  - `test_cellar`: Keller mit Treppe zurück, zwei Fledermäuse, Westöffnung → `test_traps`.
  - `test_traps` (2 Bildschirme): Klingenfallen, Stachelwelle, Bröckelbrücke über Löchern.
  - `test_switches` (Westöffnung des Startraums, 2 Bildschirme breit): Halteschalter mit Block, Kristallschalter in allen drei Modi.
- Vorhanden:
  - Spieler: Bewegung, Schwert, Leben (LP), Rückstoß, Unverwundbarkeit, Stürze.
  - Welt: Raumwechsel mit Überblendung, Bildschirm-Scrollen, Treppen, Löcher, Persistenz, Speicherstatuen.
  - Objekte: Truhen, Schlüssel-, Boss- und Gittertüren, Schiebeblöcke, Krüge/Gras, Shop.
  - Figuren: Dialoge mit NPCs und Schildern, Schleim, Zombie, Zombie-König (Boss-Gerüst), Kuh.
  - UI und Items: Item-Auswahl und -Benutzung, HUD (Lebensleiste, Rubine, Schlüssel, Item, Boss-Leiste).
  - Technik: Wand- und Boden-Tiles, Schwierigkeit mit Raumvarianten, Headless-Tests.
- Noch nicht vorhanden: Game Over, Speichern auf Festplatte mit Titelmenü, Heben und Werfen, Sound, Dungeon-Item (z. B. Bogen), echter Dungeon 1.

## Entscheidungen
- **Neuaufbau statt Weiterbau** des Prototyps. Übernommen werden Inventar, Schalter/Tür, Spieler-Animationen, Kamera-Grenzen, Schild und Lebensanzeige. Neu geschrieben werden Raumwechsel, Kampf und Gegner.
- **Beim Upgrade auf 4.7 nicht alle Szenen per Skript neu gespeichert**, weil dabei UIDs verloren gingen. Szenen werden im Editor beim nächsten Speichern im neuen Format geschrieben.
- **Alle Grafiken sind Platzhalter.** Eigene Pixel-Art kommt, wenn die Mechaniken stehen.
- **Leben in Lebenspunkten:** 1 Herz = 20 LP, Start 60 LP (3 Herzen). Die `HealthBar` ist ein durchgehender Strahl mit Trennstrichen pro Herz.
- **Schilder liest man mit `interact`**, wenn man davor steht und nach oben schaut (wie in ALttP). Im Prototyp erschien der Text automatisch.
- **Das Inventar-Menü pausiert das Spiel** (`InventoryUI` läuft mit `process_mode = Always`).
- **Persistente Hauptszene** statt `change_scene_to_file`: Spieler und HUD überleben den Raumwechsel; später lässt sich Scrollen zwischen Räumen ergänzen.
- **Tod:** Alles auf den Stand der letzten Speicherstatue (Welt, Rubine, Schlüssel, Inventar), volles Leben an der Statue. Die Statue selbst heilt nicht.
- **Spieler und Gegner kollidieren nicht miteinander**, nur ihre Hitboxen/Hurtboxen wirken (wie ALttP). NPCs wie die Kuh blockieren dagegen.
- **Platzhalter-Sprites** für Rubine, Schlüssel, Herz, Krug, Gras, Schlüsseltür, Statue und Steinboden erzeugt `tools/make_placeholders.py`.
