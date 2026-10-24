# Metro Mate Brand

Metro Mate ist ein freies Open-Source-Metronom für Drummer. Es soll sich anfühlen wie ein präzises Instrument, das man beim Üben gern neben sich liegen hat: ruhig zwischen den Schlägen, deutlich auf dem Schlag. Keine Werbung, kein Abo, kein Konto.

## Markenkern

Ein ruhiges, dunkles Instrument, in dem nur der Schlag leuchtet.

## Farben

| Rolle | Wert | Einsatz |
|---|---|---|
| Grund | `#1C1C1B` | Hintergrund aller Screens und Sheets |
| Fläche | `#242424` | Runde Tasten, Karten, Kacheln |
| Fläche erhöht | `#303030` | Tempo-Feld, Listenzeilen, Ränder der Kopf-Tasten |
| Taste gedrückt | `#3A3A3A` | Druckzustand runder Tasten |
| Text | `#DDDDDD` | Alle Texte und Symbole, Abstufung nur über Deckkraft (0.7, 0.6, 0.5, 0.45) |
| Signal-Orange | `#F54206` | Aktueller Schlag, Akzent, laufende Wiedergabe, die eine Primäraktion |

Orange hat immer eine Bedeutung. Wenn etwas orange ist, passiert dort gerade der Takt, oder dort ist die eine Sache, die man jetzt tun soll.

Do
- Orange für den gerade klingenden Schlag, den Akzentpunkt, die Play-Taste während der Wiedergabe, Auswahl (Häkchen, gewählter Notenwert) und den aktuellen Schritt im Groove.
- Orange abgeschwächt (Deckkraft 0.12 bis 0.25) für Hintergründe hinter orangem Inhalt, zum Beispiel die Kategorie-Kapsel oder die aktuelle Spalte im Groove-Raster.
- Hierarchie über Deckkraft von `#DDDDDD` bauen, nicht über neue Grautöne.

Don't
- Kein reines Schwarz, kein Weiß als Fläche, kein Light-Theme.
- Keine zweite Akzentfarbe, keine Verläufe als Dekoration, kein Glitzer.
- Keine zwei orangen Primärflächen nebeneinander.
- Orange nicht als Schmuck, etwa für alle Symbole einer Liste, wenn keines davon einen Zustand zeigt.
- Keine Systemgrau-Listen (`#2C2C2E` und ähnlich), Listenzeilen nehmen `#242424` oder `#303030`.

## Bildsprache: Taktgefühl

Die Marke zeigt den Takt, nicht ein Musikinstrument. Zwei Motive tragen sie:

- **Punkt-Raster:** gleichmäßige Punkte, wie Zählzeiten auf einem Raster. Im Hauptscreen die Akzentpunkte unter den Kacheln, im Notenwert-Wähler die Punktreihe unter jedem Wert.
- **Wellenfläche:** eine perspektivische Fläche aus verbundenen Punkten, die im Tempo nach vorn fließt und auf dem Schlag springt. Akzente schlagen kräftig aus, Unterteilungen leiser, je dichter sie sind. Nach dem Stopp friert sie an Ort und Stelle ein.

Do
- Punkte und feine Linien in `#DDDDDD` mit niedriger Deckkraft, Ausschlag auf dem Schlag.
- Bewegung nur im Tempo der App, schneller Anstieg, kurzes Ausklingen.

Don't
- Keine Galaxie- oder Sternenoptik, kein Weltraum, kein Funkeln.
- Kein Pendel-Metronom aus Holz als Illustration, keine Stock-Grafiken von Schlagzeugen.
- Keine Bewegung, die nicht an den Takt gebunden ist.

## Typografie

- Zahlen und Zählzeiten in Monospace: Tempo (48 pt light, monospaced, monospacedDigit), Zählung "1 e & a", Zeiten, Zähler wie "2 of 10".
- Alles andere in SF Pro.
- Titel fett, Labels über Titeln klein in Versalien mit Deckkraft 0.6 (zum Beispiel "PRESET" über dem Preset-Namen).
- Meta-Zeilen klein mit reduzierter Deckkraft, getrennt durch Mittelpunkt: "Beginner · 88 BPM · Sixteenths".

Don't
- Keine proportionalen Ziffern für Tempo oder Zeiten.
- Keine dekorativen Schriften.

## Bedienung

- Runde Tasten, mindestens 44 pt. Kopf-Tasten 44 pt mit 1 pt Rand `#303030`, Tempo-Tasten 60 pt, Nebenaktionen (Tap, Zufall) 64 pt, Hauptaktion Play 96 pt.
- Eine Hauptaktion im Daumenbereich unten, mittig. Sie wird orange, solange die Wiedergabe läuft.
- Das Tempo-Rad zeigt Nachbarwerte darüber und darunter, abgeblendet über Deckkraft.
- Haptik mit Bedeutung: Rasttick pro BPM, kräftiger auf Zehnern, Anschlag an den Grenzen, leichter Impuls auf Tasten, mittlerer auf Play und Tap.

Do
- Ecken: Kacheln und Felder 12 pt, Kapseln für Wähler.

Don't
- Keine zweite gleich starke Aktion neben Play.
- Keine Haptik ohne Bedeutung.

## Klang

- Echte, klare Aufnahmen (CC0), Quellen stehen in `Metronome/Sounds/SOURCES.md`.
- Cowbell ist Standard (Alex' Wahl, 2026-10-24). Weitere Klänge: Classic (Woodblock), Clean, Claves, Pocket, Punch, Deep.
- Akzent und Zwischenschlag klingen hörbar verschieden.

Don't
- Keine billig synthetischen Piepser als Standard.

## Sprache

- In der App Englisch, Du-Ton, knapp.
- Drummer-Vokabular: Groove, Pocket, Ghost Notes, Backbeat, Sticking, Kick, Hi-Hat.
- Ehrlich statt Hype. Beispiel aus der App: "Start slow, speed up only when it feels effortless."
- README und Store-Text dürfen das Versprechen nennen: kostenlos, ohne Werbung, ohne Abo, ohne Konto, offener Code.

Don't
- Keine Gedankenstriche (Geviert- und Halbgeviertstrich), stattdessen Punkt, Komma oder Mittelpunkt.
- Keine Emojis in der UI, SF Symbols statt dessen.
- Keine Floskeln, keine Sie-Form, keine Superlative ohne Beleg.
- Keine Inhalte aus geschützten Lehrwerken (zum Beispiel Notenbeispiele aus Büchern).

## App-Icon

- Eine Form, ein Gedanke, kein Text. Bei 29 pt auf dem Homescreen lesbar.
- Grund in Warmgrau aus der App (`#1C1C1B` bis `#242424`), Signal-Orange `#F54206` als einziger Akzent, `#DDDDDD` als Nebenfarbe.
- Keine Linien unter 2 px bei 60 pt.
- Master 1024 px ohne Transparenz und ohne gerundete Ecken, dazu Dark- und Tinted-Variante.
- Neue Icons entstehen als SVG nach dem Brief in `docs/brand/icon-brief.md` und gehen als Vorschau an Alex, bevor sie in den Asset-Katalog kommen.

## Store-Bilder und Grafik

- Nur aus echten Screens der App, nie nachgebaute UI.
- Grafiken als Vektor (SVG), daraus gerendert.
- Dunkler Grund wie in der App, Orange nur dort, wo es auch in der App leuchtet.
