# Tiney – Design-Dokument

> „Tiney“ ist ein Projektname und eine Erinnerung: **das Spiel klein halten.**

## Kernidee
Ein Top-down-Action-Adventure im Stil von *A Link to the Past*. Man wird ohne Tutorial direkt in den ersten Dungeon geworfen. Ein zentraler Hub verbindet drei Dungeons und das Finale. Das Besondere: **eine frei wählbare Schwierigkeit von 1,0 bis 10,0**, die sowohl die Werte der Gegner als auch den Aufbau der Räume verändert.

## Held & Stil
- Eigene Pixel-Art (alle aktuellen Grafiken sind heruntergeladene Platzhalter)
- Held: cute, Twink-Ästhetik (ersetzt die Platzhalter-Katze)

## Ablauf
1. **Start in Dungeon 1**, ohne Intro und ohne Tutorial
2. Boss besiegt → **1 von 3 magischen Kugeln**
3. Weiter in den **Hub**: drei Türen zu den Dungeons und eine große Tür, die sich mit allen drei Kugeln öffnet → **Finale**
4. Dungeon 2 und 3 sind vom Hub aus spielbar (Reihenfolge: *offen*)

## Gebiete
| Gebiet | Ästhetik | Status |
|---|---|---|
| Dungeon 1 | Kerker, Zombies | fest |
| Hub | zentraler Raum, 3+1 Türen, Shop | fest |
| Dungeon 2 | Wiese & Wald | fest |
| Dungeon 3 | – | offen |
| Finale | hinter der großen Tür, Mönch → Dämonengottheit | fest |
| Testbereich | großer Bereich zum Testen von Mechaniken, **im fertigen Spiel nicht erreichbar** | fest |

**Geheimwege** verbinden die Dungeons miteinander. Dazu kommen weitere Secrets.

## Finale & Story
1. Hinter der großen Tür wartet **ein Mönch, der den Helden aufhalten will**. Er ist der erste Endgegner.
2. Nach seiner Niederlage stellt sich heraus: **Er war der Gute.** Die drei vereinten Kugeln befreien eine alte, versiegelte **Dämonengottheit**.
3. **Die Dämonengottheit ist der wahre Endgegner.**
4. Nach ihrem Sieg **setzt sich der Held selbst auf den finsteren Thron**, und das Spiel endet.
5. Vielleicht: **kleine unterschiedliche Enden je nach Schwierigkeitsgrad**

Ideen zur Vorbereitung der Wendung (offen):
- Den Mönch schon früher kurz auftauchen lassen, zum Beispiel wie er im Hub warnt oder in einem Dungeon flieht
- Inschriften und Wandbilder in den Dungeons, die im Nachhinein einen anderen Sinn ergeben
- Kleine Veränderungen am Helden mit jeder Kugel, etwa an Farbe, Schatten oder Idle-Animation

## Musik & Sound
- Noch offen. Wie bei der Grafik zuerst Platzhalter, später etwas Eigenes.
- Mindestens benötigt: ein Track pro Gebiet (Dungeon 1–3, Hub, Finale), Boss-Musik und kurze Jingles (Item gefunden, Kugel, Game Over)
- Soundeffekte: Schwert, Treffer, Tür, Schalter, Pickup, Menü
- Mögliche Wege:
  - Selbst komponieren: Einsteigerfreundliche Chiptune-Tools sind BeepBox (im Browser), Bosca Ceoil oder FamiStudio; LMMS geht weiter.
  - Freie Musik verwenden: z. B. OpenGameArt oder freesound. Auf die Lizenz achten, CC0 ist am einfachsten.
  - Soundeffekte erzeugen: jsfxr oder ChipTone, schnell und passend zum Retro-Stil
- Die Technik ist unabhängig davon: Ein Audio-Autoload übernimmt Musikwechsel mit Überblendung beim Gebietswechsel. Getrennte Lautstärken für Musik und Effekte.

## Systeme
**Fest geplant**
- Items, die man im Laufe des Spiels findet
- Verschiedene Schwerter und Rüstungen, die man findet oder kauft
- Shop
- Herzcontainer-artige Upgrades für mehr Lebensenergie
- Sammelobjekte (ähnlich den goldenen Skulltulas)
- Bosse pro Dungeon und einige Zwischenbosse (Inspiration: *The Binding of Isaac*)
- Secrets und Geheimwege

**Vielleicht**
- Magieanzeige
- Orden
- Achievements

## Schwierigkeit 1,0–10,0 (Kernmechanik)
- Wird manuell gewählt, auf Dezimalstellen genau
- **Stufenlose Skalierung:** Angriff, Leben und Tempo der Gegner werden über eine Funktion der Schwierigkeit *d* berechnet
- **Feste Stufen** bei ganzen Zahlen (1, 2, …, 10): Es werden alternative, schwerere Raumvarianten geladen, z. B. mit einem Gegner mehr
- **Kalibrierung:** **4,0 ist der Standard**: Bei 4,0 gelten die Basiswerte unverändert, darauf wird gebaut und balanciert. Der Weg zu schwierigeren Stufen ist der interessantere Teil. 10 = absurd schwer, kaum schaffbar.

**Technische Konsequenz (früh einplanen):**
- Ein zentraler Wert `difficulty` (Autoload). Alle Gegnerwerte kommen aus *Basiswert × Multiplikator(d)*, nie fest im Gegner verdrahtet.
- Vorschlag Multiplikator: exponentiell, z. B. `m(d) = k^(d − d_normal)` mit eigenem `k` pro Wert (Leben, Schaden, Tempo). So ist 10 deutlich mehr als „doppelt so schwer“.
- Räume unterstützen von Anfang an Varianten, z. B. Gegner und Hindernisse mit einer Mindeststufe `min_tier`, die erst ab dieser Stufe erscheinen. So reicht eine Szene pro Raum statt zehn Kopien.

## Dungeon-Elemente (entschieden)
- **Kleine Schlüssel gelten pro Dungeon** (wie ALttP). Der Zähler am Bildschirmrand zeigt die Schlüssel des aktuellen Dungeons.
- **Schlüsseltüren** öffnen beim Dagegenlaufen und bleiben offen.
- **Großer Schlüssel:** einer pro Dungeon, öffnet die Bosstür und wird dabei verbraucht. Keine großen Truhen.
- **Truhen** haben einen festen Inhalt, öffnen sich von jeder Seite per Interaktion und bleiben offen. Beim Öffnen hält der Held den Inhalt kurz hoch (Spiel pausiert), bei wichtigen Dingen mit Textmeldung („Du hast den großen Schlüssel!“), bei Rubinen ohne Text.
- **Rubine** als Währung: grün 1, blau 5, rot 20. Höchstens 999.
- **Krüge und Gras** gehen vorerst mit dem Schwert kaputt. Jeder kann einen **festen Inhalt** haben (z. B. Schlüssel), sonst lassen sie zufällig Rubine oder Herzen fallen. Heben und Werfen wie in ALttP kommt später.
- **Nichts erscheint neu:** Eingesammeltes, Zerstörtes und Getötetes bleibt weg, auch nach Raumwechsel. Liegen gelassene Drops bleiben liegen, Schalter behalten ihren Zustand.
- **Türen und Durchgänge** laden einen anderen Raum (mit Abblenden).
- **Erster Gegner: Schleim.** Hüpft herum und verfolgt den Spieler aus der Nähe.
- **Kuh:** harmlos, läuft gemächlich herum und versperrt den Weg. Ein Schwerthieb stößt sie nur zurück.
- **Lebensanzeige:** ein Abschnitt pro Herz, jeweils voll, halb oder leer. Start mit 3 Herzen.

## Leben & Items (entschieden)
- **Lebensleiste:** durchgehender Strahl mit Trennstrichen pro Herz. Bei Schaden leuchtet der verlorene Teil kurz auf und läuft dann nach. Heilen und Herzcontainer füllen sich flüssig. Intern: 1 Herz = 20 Punkte, damit skalierter Schaden fein abgestuft ist. Bei 4,0 glatte Werte (½ Herz, 1 Herz).
- **Herzen** werden immer aufgesammelt, auch bei vollem Leben. **Herzcontainer:** +1 Herz, Leben voll.
- **Items** wählt man im Menü aus und benutzt sie mit der Item-Taste. Heilitems werden bei vollem Leben nicht verbraucht. Apfel heilt ½ Herz, Heiltrank alles.

## Figuren & Dialoge (entschieden)
- **Dialoge:** Textbox unten mit Schreibmaschinen-Effekt, Interaktion zeigt alles bzw. blättert weiter, Spiel pausiert. Darüber seitlich Bild und Name des Sprechers. Schilder nutzen dieselbe Box ohne Bild.
- **Gefangener** im Kerker deutet den Mönch an: “The orbs must never be brought together.”
- **Shop:** Ware liegt mit Preis auf der Theke, davorstellen zeigt Name, Preis und Beschreibung, Interaktion kauft. Der Ladenbesitzer spricht. Test-Angebot: Hinweis (1, nett, nicht hilfreich), Herz (5), Apfel (3), Heiltrank (30), Schlüssel (50, einmal).
- **Fledermaus:** flattert in zufällige Richtungen, wechselt oft den Kurs, setzt sich ab und zu kurz hin. Fliegt über Löcher und Stacheln. 1 Hieb, ½ Herz.
- **Zombie** (Gegner in Dungeon 1): bemerkt dich auf ~6 Tiles, schlurft langsam und stur hinterher, 4 Hiebe, 1 Herz Schaden.
- **Zombie-König** (Platzhalter-Boss): Bossraum schließt sich, Boss-Leiste, Sturmangriff mit Ankündigung, ruft bei halbem Leben 2 Zombies (nie direkt am Spieler), 12 Hiebe. Belohnung: Herzcontainer + magische Kugel.

## Dungeon-Mechaniken (entschieden)
- **Gittertüren:** schließen beim Betreten, öffnen sich, wenn alle Gegner besiegt sind, bleiben danach offen.
- **Schalter:** grüne Bodenschalter schalten um. Orange Halteschalter halten eine Tür nur offen, solange etwas daraufsteht (Spieler oder Block). **Kristallschalter** reagieren auf Schwerthiebe, die Farbe zeigt die Art: blau/rot schaltet hin und her, grün öffnet für immer, gelb nur für einige Sekunden. Kann eine Tür hinter dem Spieler zufallen, gibt es auch innen einen Schalter (keine Softlocks).
- **Sprache im Spiel:** Englisch.
- **Fallen:**
  - **Stacheln:** dauerhaft oder taktend (1,5 s draußen, 1,5 s drin, kurz vorher Zittern), ½ Herz.
  - **Klingenfallen:** stahlblau lauernd (schießt los, wenn man in Zeile/Spalte tritt, prallt ab, kehrt langsam zurück), bronze pendelnd. 1 Herz, unzerstörbar.
  - **Bröckelnde Platten:** zerfallen kurz nach dem Betreten zu einem Loch; beim nächsten Betreten des Raums sind sie wieder ganz.
  - Fallenschaden wächst mit der Schwierigkeit.
- **Schiebeblöcke:** kurz dagegen laufen schiebt ein Tile. Sie bleiben, wo sie sind (der Tod setzt sie über die Statue zurück). Ein Block auf einem Bodenschalter drückt ihn.
- **Löcher:** pro Loch einstellbar. Mit Ziel fällt man ein Stockwerk tiefer, ohne Ziel kostet es ½ Herz und man steht wieder am letzten sicheren Boden.
- **Kamera:** bildschirmweises Schieben wie in ALttP, pro Raum im Editor auf „mitlaufend“ umstellbar. Gegner bleiben dabei in ihrem Bildschirm. Treppen führen in andere Räume.

## Spielgefühl (entschieden)
- Kurzer Trefferstopp bei Treffern, leichtes Bildschirmwackeln, wenn man getroffen wird, und beim Boss.
- Partikel: Scherben, Halme, Rauch beim Gegnertod, Funken am Kristall. Gegner blitzen weiß auf und verpuffen.

## Speichern & Tod (entschieden)
- **Speicherstatuen** stehen in einer Wasserpfütze. Wer die Pfütze betritt, speichert automatisch (kurze Meldung „Gespeichert“). Die Statue heilt nicht. Das Konzept wird später verfeinert (z. B. einzelne Pfützen in Türen).
- **Tod:** Alles wird auf den Stand der letzten Statue zurückgesetzt (Gegner, Krüge, Türen, Schalter, Rubine, Schlüssel, Inventar). Man erscheint mit vollem Leben an der Statue. Vor der ersten Statue gilt der Spielstart.
- Speichern auf Festplatte kommt später zusammen mit einem Titelmenü (Neues Spiel / Fortsetzen).

## Offene Fragen
- Kann man die Schwierigkeit während des Spiels ändern? Gibt es Belohnungen oder Achievements für hohe Stufen?
- Skaliert auch der Schaden, den der Spieler nimmt, oder nur die Gegnerwerte?
- Thema von Dungeon 3
- Enden je nach Schwierigkeit: Welche Stufen bekommen welches Ende?
- Reihenfolge von Dungeon 2 und 3 frei wählbar?
- Kommen Magie, Orden und Achievements dazu?

## Umfang & Reihenfolge (gegen das Ausufern)
1. **Meilenstein 1 – Vertical Slice:** Testbereich, Held mit Bewegung und Schwert, ein Gegnertyp, Schwierigkeitssystem (Skalierung + Raumvarianten), Raumwechsel, Türen, Schalter, Schlüssel
2. **Meilenstein 2:** Dungeon 1 komplett mit Boss und Kugel, danach der Hub
3. **Meilenstein 3:** Dungeon 2, Shop, Ausrüstung, Herzcontainer, Sammelobjekte
4. **Danach:** Dungeon 3, Finale, Zwischenbosse, Secrets, optionale Systeme
5. **Grafik:** Eigene Pixel-Art ersetzt die Platzhalter schrittweise, nachdem die Mechaniken stehen
