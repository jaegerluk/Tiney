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
- Sammelobjekte (Arbeitstitel „Skulltulas“, siehe unten)
- Bosse pro Dungeon und einige Zwischenbosse (Inspiration: *The Binding of Isaac*)
- Secrets und Geheimwege

- Magieleiste (für Enthüllungsglas, ggf. Feuerstab)

**Vielleicht**
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
- **Heben & Werfen:** Krüge und Steine hebt man mit Interaktion hoch. Beim Tragen läuft man normal, Schwert und Items sind gesperrt; Angriff oder Interaktion wirft (~4 Tiles). Der Wurf zerbricht beim Aufprall, macht 1 Treffer, löst Kristalle aus, der Inhalt fällt dort heraus. Wird man getroffen, fällt der Gegenstand herunter. Steine gehen nicht per Schwert kaputt.
- **Krüge und Gras** gehen weiterhin auch mit dem Schwert kaputt. Jeder kann einen **festen Inhalt** haben (z. B. Schlüssel), sonst lassen sie zufällig Rubine oder Herzen fallen. Heben und Werfen wie in ALttP kommt später.
- **Nichts erscheint neu:** Eingesammeltes, Zerstörtes und Getötetes bleibt weg, auch nach Raumwechsel. Liegen gelassene Drops bleiben liegen, Schalter behalten ihren Zustand.
- **Türen und Durchgänge** laden einen anderen Raum (mit Abblenden).
- **Erster Gegner: Schleim.** Hüpft herum und verfolgt den Spieler aus der Nähe.
- **Kuh:** harmlos, läuft gemächlich herum und versperrt den Weg. Ein Schwerthieb stößt sie nur zurück.
- **Lebensanzeige:** ein Abschnitt pro Herz, jeweils voll, halb oder leer. Start mit 3 Herzen.

## Leben & Items (entschieden)
- **Lebensleiste:** durchgehender Strahl mit Trennstrichen pro Herz. Bei Schaden leuchtet der verlorene Teil kurz auf und läuft dann nach. Heilen und Herzcontainer füllen sich flüssig. Intern: 1 Herz = 20 Punkte, damit skalierter Schaden fein abgestuft ist. Bei 4,0 glatte Werte (½ Herz, 1 Herz).
- **Herzen** werden immer aufgesammelt, auch bei vollem Leben. **Herzcontainer:** +1 Herz, Leben voll.
- **Geld-Balance:** Wer alle Truhen und Secrets mitnimmt, hat immer genug Rubine für die wichtigen Shop-Sachen. Ausnahme: höchstens einmal, für die teuerste Sache gegen Ende, muss man gezielt sparen oder farmen.
- **Items** wählt man im Menü aus und benutzt sie mit der Item-Taste. Heilitems werden bei vollem Leben nicht verbraucht. Apfel heilt ½ Herz, Heiltrank alles.

## Figuren & Dialoge (entschieden)
- **Dialoge:** Textbox unten mit Schreibmaschinen-Effekt, Interaktion zeigt alles bzw. blättert weiter, Spiel pausiert. Darüber seitlich Bild und Name des Sprechers. Schilder nutzen dieselbe Box ohne Bild.
- **Gefangener** im Kerker deutet den Mönch an: “The orbs must never be brought together.”
- **Shop:** Ware liegt mit Preis auf der Theke, davorstellen zeigt Name, Preis und Beschreibung, Interaktion kauft. Der Ladenbesitzer spricht. Test-Angebot: Hinweis (1, nett, nicht hilfreich), Herz (5), Apfel (3), Heiltrank (30), Schlüssel (50, einmal).
- **Fledermaus:** flattert in zufällige Richtungen, wechselt oft den Kurs, setzt sich ab und zu kurz hin. Fliegt über Löcher und Stacheln. 1 Hieb, ½ Herz.
- **Skelett-Schütze:** hält 4–6 Tiles Abstand, stellt sich in deine Zeile/Spalte, zielt kurz und schießt geradeaus. 2 Hiebe, Pfeil ½ Herz, alle 2 s. Pfeile bleiben kurz in Wänden stecken.
- **Pfeile abwehren** kann das Startschwert nicht, erst bessere Schwerter oder Orden.
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
  - Taktende Stacheln und lauernde Klingenfallen sind nur auf dem aktuellen Bildschirm aktiv; Stacheln beginnen ihren Takt beim Hereinkommen von vorn.
- **Schiebeblöcke:** kurz dagegen laufen schiebt ein Tile. **Ziehen:** davor Interaktion halten und wegziehen (gegen Festfahren). Pro Block einstellbar, ob er ziehbar ist; nur schiebbare Blöcke sind dunkler. Sie bleiben, wo sie sind (der Tod setzt sie über die Statue zurück). Ein Block auf einem Bodenschalter drückt ihn.
- **Löcher:** komplett schwarz. Löcher in ein tieferes Stockwerk erkennt man an einem schwachen, warmen Lichtschein von unten. Pro Loch einstellbar. Mit Ziel fällt man ein Stockwerk tiefer, ohne Ziel kostet es ½ Herz und man steht wieder am letzten sicheren Boden.
- **Kamera:** bildschirmweises Schieben wie in ALttP, pro Raum im Editor auf „mitlaufend“ umstellbar. Gegner bleiben dabei in ihrem Bildschirm. Treppen führen in andere Räume.

## Dunkle Räume (entschieden)
- Dunkle Räume sind fast schwarz; um den Helden ein kleiner Lichtkreis (~2 Tiles). Brennende Feuerschalen erhellen ihre Umgebung.
- Feuerschalen werden vorerst über Schalter angezündet; später durch die Laterne (oder eventuell den Feuerstab). Pro Schale einstellbar, ob sie dauerhaft brennt oder nach einiger Zeit ausgeht. Brennen alle Schalen einer Gruppe, kann sich z. B. eine Tür öffnen.

## Dungeon-Items (Konzept, noch nicht gebaut)
- **Prinzip:** 1–2 Items pro Dungeon. Die Rätsel eines Dungeons bauen auf seinen Items auf, der Boss nutzt sie mit.
- **Geplant:**
  - **Bogen** (für Dungeon 2): Augen-/Fernschalter, Gegner auf Distanz
  - **Bomben:** rissige Wände sprengen (Geheimwege), Gegner, Schalter hinter Gittern
  - **Enterhaken:** zu Pfosten/Truhen über Abgründe, holt kleine Dinge heran. Deckt auch Abgründe ab, kein eigenes Sprung-Item
  - **Laterne:** größerer Lichtkreis in dunklen Räumen, zündet Feuerschalen
  - **Ein neu erfundenes Item** (Idee kommt später)
- **Geplant, optional** (nicht für den Hauptweg nötig):
  - **Enthüllungsglas:** hinter einem Secret/Geheimweg; zeigt versteckte Truhen, falsche Wände, unsichtbare Wege
- **Eventuell:**
  - **Feuerstab:** Feuerschalen aus der Ferne, Ranken/Spinnweben verbrennen
- Zuordnung zu den Dungeons ist noch offen (fest nur: Bogen in Dungeon 2).
- **Ressourcen:** Bomben und Pfeile sind Munition (Drops, Shop). Enthüllungsglas (und ggf. Feuerstab) verbrauchen Magie aus einer **Magieleiste** im HUD (Magie-Krüge als Drop).
- Falls D2 und D3 frei wählbar sind, darf der Hauptweg eines Dungeons nur Items aus D1 und aus ihm selbst brauchen. Fremde Items öffnen dann nur Secrets und Geheimwege (Backtracking).

## Sammelobjekte (Konzept; Platzhalter-Version gebaut)
- **Arbeitstitel: „Skulltulas“.** Was es wirklich wird, ist noch offen. Platzhalter: **goldene Seelen**. Gewünscht: Design ähnlich goldener Totenköpfe (aber nicht zu nah am Vorbild) und später ein Story-Bezug.
  - Ideen: goldene Totenmasken der Mönche, die den Dämon versiegelten (je eine mit Lore); Gebetsperlen des Ordens; Seelen-Reliquiare; Knochen-Fetische.
- **Anzahl:** ca. 30 im ganzen Spiel (endgültig, wenn alles designt ist).
- **Belohnung:** Stufen-Belohnungen bei einer Figur (z. B. bei 5/10/20/…: Rubine, Herzteil, Magie-Upgrade, größerer Köcher/Bombentasche, am Ende etwas Besonderes).
- **Anzeige:** Zähler im Inventar-Menü; beim Aufheben hält der Held die Seele hoch, Meldung mit neuer Zahl.
- **Hinweis:** ein schwaches Geräusch (kommt mit dem Audio-System), wenn eins in der Nähe ist. Später gibt ein **Orden** deutlichere Signale.

## Dungeon 1 – Ideen (Sammlung, noch nicht geplant)
**Vorgehen beim Planen:** Ideen sammeln → Ablauf als Stationen → Schlüssel- und Abhängigkeitsplan → Raumkarte (Raster, Stockwerke) → Inhalt pro Raum → fehlende Bausteine bauen → Graybox (nur Wände/Türen/Schlüssel, einmal durchspielbar) → füllen.

- **Start:** Der Held wacht als Gefangener in einer Kerkerzelle auf. Die Zellentür öffnet sich durch dunkle Magie der versiegelten Dämonengottheit: Sie weiß, dass der Held sie befreien wird, und hat nach 100 Jahren gerade genug Kraft dafür gesammelt (Story-Idee, passt zur Wendung im Finale).
- **Tutorial:** zuerst ein paar sehr einfache, lineare Räume. Sie bilden ein **eigenes Stockwerk, das unterste des Dungeons**. Trotzdem sollen sie cool sein (Ideen noch offen, z. B. Gefangene in Nachbarzellen kommentieren, ein Zombie bricht durch eine Wand).
- **Shop:** mindestens einer. Ein Gefangener verkauft durch die Gitterstäbe seiner Zelle.
- **Hauptraum:** großer zentraler Raum mit einem auffälligen Designelement (wie der riesige Schädel in Dodongos Höhle). Von dort führen mehrere Wege weg. Element noch offen (Ideen: riesiges Skelett, durch dessen Brustkorb der Weg führt; Schacht mit Käfigen an Ketten; Statue mit Feuerschalen als Augen).
- **Aufbau:** erst sehr linear, dann etwas verzweigter, insgesamt aber einfach (erster Dungeon).
- **Schlüssel:** ja, kleine Schlüssel und großer Schlüssel.
- **Karte und Kompass:** ja, die Karte recht bald nach den Tutorial-Räumen.
- **Gegner:** gruselig: Zombies, Totenköpfe, Skelette, Spinnen usw.
- **Bosse:** 1–2 Zwischenbosse und ein Hauptboss. Der Zombie-König wird vielleicht ein Zwischenboss.
- **Befreundeter Insasse:** Ein Mitgefangener, mit dem sich der Held anfreundet; vielleicht führt er durchs Tutorial. Später verwandelt ihn der Boss oder ein Zwischenboss in einen Zombie: ein trauriger Moment, danach ist er ein normaler Gegner.
- **Secret:** ein Raum voller Krüge, in dem an einer Stelle statt einer Wand ein Krug steht; dahinter liegt ein geheimer Raum.
- **Deko:** Kerkerzellen, Eisenketten, ein paar Andreaskreuze, in manchen Zellen noch Gefangene.
- **Sammelobjekte:** einige „Skulltulas“ verstecken (siehe Sammelobjekte).
- **Items:** noch offen. Das **neu erfundene Item** soll möglichst schon in D1 vorkommen (eigener Vibe des Spiels).
- **Mindestens ein dunkler Raum.**

## Welt & Lore
**Entschieden**
- Die Spielwelt ist ein riesiger, nach außen geschlossener **Komplex**, gebaut nur, um die Dämonengottheit zu versiegeln. Deshalb ist die Welt so klein.
- Die **Bewohner** (z. B. der Shopbesitzer im Hub) sind Nachfahren der Menschen, die damals mit eingeschlossen wurden. Den Sinn ihrer Welt kennen sie nicht mehr.
- Nur der **Mönch** weiß noch, wozu alles da ist. Er liegt in einem ewigen Schlaf hinter der großen Tür und bewacht dort die Versiegelungsstelle selbst.

**Ideen (offen)**
- Jeder Teil des Komplexes hatte einen Zweck: Kerker (D1) für die, die der Stimme der Gottheit verfallen; Wiese & Wald (D2) als Gärten und Obsthaine zur Versorgung; Hub als alter Klosterhof.
- Der Held sitzt im Kerker, weil er die Stimme gehört hat? Zombies als tote Gefangene, die die Gottheit wieder aufstehen lässt?
- Die Kugeln sind absichtlich auf drei Teile verteilt und bewacht, damit niemand allein das Siegel bricht.
- D3-Ideen mit Zweck im Komplex: Archiv/Skriptorium, Zisternen/Wasserwerk, Schmiede/Gießerei, Glockenturm/Observatorium.
- Weiß der Held, dass er die Stimme gehört hat? Haben die Bewohner Angst vor ihm als entflohenem Gefangenen?

## Story & Figuren – Ideen für später
- Dungeon 2: ein bekiffter Hippie.
- Irgendwo im Spiel eine schwule Liebesgeschichte.
- Warum der Held im Kerker gefangen ist, wird später mit der Story geklärt.

## Karte & Kompass (entschieden, im Testbereich gebaut)
- **Karte pro Dungeon** als Fundstück (wie Schlüssel). Der Hub braucht keine.
- **Ohne Karten-Item gibt es keine Karte**, weder Vollbild noch Mini-Karte. Mit dem Item erscheint sofort der ganze Dungeon.
- **Nur Kompass, keine Karte:** Kartenbildschirm und Mini-Karte zeigen nur den Helden und die Kompass-Symbole im Dunkeln, ohne Räume.
- **Kompass** als eigenes Fundstück pro Dungeon: markiert ungeöffnete Truhen, verschlossene Schlüssel- und Bosstüren (Schloss-Symbol), Speicherstatuen und den Boss (kleine Symbole an der echten Position; Erledigtes verschwindet).
- **Anzeige:**
  - Vollbild-Karte über eine eigene Taste (z. B. M / Gamepad Select), Spiel pausiert.
  - Räume als Kästchen im Raster, automatisch aus den Raumszenen erzeugt: Jeder Raum bekommt im Inspector Rasterposition und Stockwerk.
  - Besuchte Räume hell, unbesuchte dunkel, Durchgänge als helle Lücken, Treppen als Symbol. Aktueller Raum blinkt, der Held ist ein grüner Punkt, Stockwerke (1F, B1 …) mit hoch/runter umschaltbar.
  - Zusätzlich eine kleine **Mini-Karte im HUD** unten rechts: aktueller Bildschirm und Umgebung (5×3), mit Kompass auch die Symbole.
- Große Räume zeigen ihre Innenwände (Lücken = Durchgänge). Durchgänge liegen auf beiden Seiten an derselben Stelle, Treppen auf beiden Stockwerken an derselben Stelle.
- Die Karte aktualisiert sich beim Bauen selbst; pro Raum werden nur Rasterposition und Stockwerk eingetragen.

## Spielgefühl (entschieden)
- Kurzer Trefferstopp bei Treffern, leichtes Bildschirmwackeln, wenn man getroffen wird, und beim Boss.
- Partikel: Scherben, Halme, Rauch beim Gegnertod, Funken am Kristall. Gegner blitzen weiß auf und verpuffen.

## Speichern & Tod (entschieden)
- **Speicherstatuen** stehen in einer Wasserpfütze. Wer die Pfütze betritt, speichert automatisch (kurze Meldung „Gespeichert“). Die Statue heilt nicht. Das Konzept wird später verfeinert (z. B. einzelne Pfützen in Türen).
- **Game Over:** Spiel friert ein, der Held dreht sich und sinkt zusammen, das Bild wird schwarz, „GAME OVER“ und „Continue“. Weiter mit Interaktion, Angriff oder Start.
- **Tod:** Alles wird auf den Stand der letzten Statue zurückgesetzt (Gegner, Krüge, Türen, Schalter, Rubine, Schlüssel, Inventar). Man erscheint mit vollem Leben an der Statue. Vor der ersten Statue gilt der Spielstart.
- Speichern auf Festplatte kommt später zusammen mit einem Titelmenü (Neues Spiel / Fortsetzen).

## Offene Fragen
- Kann man die Schwierigkeit während des Spiels ändern? Gibt es Belohnungen oder Achievements für hohe Stufen?
- Skaliert auch der Schaden, den der Spieler nimmt, oder nur die Gegnerwerte?
- Thema von Dungeon 3
- Enden je nach Schwierigkeit: Welche Stufen bekommen welches Ende?
- Reihenfolge von Dungeon 2 und 3 frei wählbar?
- Welche Items kommen in welchen Dungeon (außer Bogen → D2)?
- Kommen Orden und Achievements dazu?

## Umfang & Reihenfolge (gegen das Ausufern)
1. **Meilenstein 1 – Vertical Slice:** Testbereich, Held mit Bewegung und Schwert, ein Gegnertyp, Schwierigkeitssystem (Skalierung + Raumvarianten), Raumwechsel, Türen, Schalter, Schlüssel
2. **Meilenstein 2:** Dungeon 1 komplett mit Boss und Kugel, danach der Hub
3. **Meilenstein 3:** Dungeon 2, Shop, Ausrüstung, Herzcontainer, Sammelobjekte
4. **Danach:** Dungeon 3, Finale, Zwischenbosse, Secrets, optionale Systeme
5. **Grafik:** Eigene Pixel-Art ersetzt die Platzhalter schrittweise, nachdem die Mechaniken stehen
