# Logo-Brief: neues App-Icon für Metro Mate

Empfänger: Grafiker-Agent. Ergebnis: SVG-Entwürfe je Konzept-Richtung plus gerenderte PNG-Vorschauen. Grundlage ist `docs/BRAND.md`. Nichts davon kommt in den Asset-Katalog, bevor Alex einen Entwurf freigegeben hat.

## Worum es geht

Metro Mate ist ein freies Open-Source-Metronom für Drummer. Die App ist dunkel, ruhig und präzise. Im Zentrum steht der Takt: ein Punkt-Raster und eine Wellenfläche aus Punkten, die im Tempo fließt und auf dem Schlag springt. Nur der aktuelle Schlag leuchtet in Signal-Orange. Das Icon soll genau dieses Gefühl auf den Homescreen bringen und dort sofort als Metro Mate erkennbar sein.

## Markenkern

Ein ruhiges, dunkles Instrument, in dem nur der Schlag leuchtet.

## Ist-Analyse des alten Icons

Das alte Icon ist ein großes "M" aus gefalteten Bändern in Rot, mittig auf dunklem, bräunlichem Grund (`metro-beat-1024.jpg`).

Was trägt
- Dunkler, warmer Grund passt zur App.
- Eine einzige Akzentfarbe, eine einzige Form, kein Text außer dem Buchstaben.
- Hoher Kontrast, bei 29 pt als rote Form erkennbar.

Was nicht trägt
- Der Buchstabe sagt nichts über Takt, Tempo oder Schlagzeug. Ein "M" auf dunklem Grund ist austauschbar und erinnert an bekannte Mail- und Markenlogos.
- Die Farbe ist ein reines Rot (etwa `#FF1000`) statt Signal-Orange `#F54206`. Auf dem Homescreen wirkt das wie eine fremde Marke neben der App.
- Die Faltung arbeitet mit Verläufen und Schattierungen. Das widerspricht der flachen Bildsprache der App und matscht bei kleinen Größen zu einer Fläche.
- Die Form nutzt nur gut ein Drittel der Fläche, bei 29 pt bleibt wenig übrig.
- Der Grund ist brauner als `#1C1C1B` und passt nicht exakt zur App.
- Punkt-Raster und Wellenfläche, das Erkennungszeichen der App, kommen gar nicht vor.

## Pflichtfarben

| Rolle | Wert |
|---|---|
| Grund | `#1C1C1B` (Fläche darf bis `#242424` gehen, flach, ohne Verlauf) |
| Signal | `#F54206`, genau eine orange Form oder ein oranger Punkt |
| Nebenfarbe | `#DDDDDD`, auch abgestuft über Deckkraft (0.25 bis 0.7 auf dem Grund vorberechnet als Volltonfarbe) |

Keine weiteren Farben.

## Konzept-Richtungen

Bitte jede Richtung als eigenen, sauberen Entwurf bauen. Die Richtungen sollen sich klar unterscheiden, nicht nur in Details.

### A. Der Schlag im Raster

- **Idee:** Ein Takt als Punkt-Raster, ein Punkt ist gerade dran. Genau das, was die App beim Spielen zeigt.
- **Form:** Ein Raster aus 4 mal 4 runden Punkten (oder 4 Punkte in einer Reihe, wenn das Raster bei 29 pt zerfällt). Ein Punkt ist deutlich größer, etwa doppelter Durchmesser, und sitzt auf der ersten Zählzeit oder leicht aus der Mitte versetzt. Raster füllt etwa 60 Prozent der Fläche.
- **Farbe:** Rasterpunkte `#DDDDDD` gedämpft, der große Punkt `#F54206`. Grund `#1C1C1B`.

### B. Die Welle springt

- **Idee:** Die Wellenfläche der App im Moment des Schlags: eine ruhige Fläche, die an einer Stelle hochspringt.
- **Form:** Drei bis fünf horizontale Punktlinien in leichter Perspektive (nach hinten enger), in der Mitte zu einer klaren Spitze ausgelenkt. Auf der Spitze sitzt ein großer Punkt. Wenige, kräftige Punkte statt vieler feiner, damit es bei 29 pt nicht zu Rauschen wird.
- **Farbe:** Punktlinien `#DDDDDD` gedämpft, nach hinten dunkler, Spitzenpunkt `#F54206`.

### C. Zählzeit-Kacheln

- **Idee:** Die Beat-Kacheln aus dem Hauptscreen ("1 & 2 &"), eine davon leuchtet. Wer die App kennt, sieht sofort den Takt.
- **Form:** Vier abgerundete Quadrate, entweder in einer Reihe oder als 2 mal 2. Eine Kachel ist orange gefüllt, die anderen flach in `#303030`. Optional unter jeder Kachel ein Akzentpunkt wie in der App. Keine Ziffern im Icon.
- **Farbe:** Grund `#1C1C1B`, Kacheln `#303030`, aktive Kachel und ihr Akzentpunkt `#F54206`.

### D. M aus Schlägen

- **Idee:** Den Wiedererkennungswert des alten "M" mitnehmen, aber aus der Taktsprache bauen: ein "M" als Ausschlag einer Pulskurve.
- **Form:** Fünf Punkte, verbunden durch eine kräftige, flache Linie im Zickzack (unten, oben, Mitte, oben, unten), die zusammen ein "M" ergeben. Linienstärke mindestens so, dass sie bei 60 pt über 2 px liegt. Ein Punkt, bevorzugt eine der Spitzen, ist größer und orange.
- **Farbe:** Linie und Punkte `#DDDDDD`, ein Punkt `#F54206`. Alternativ Linie in `#F54206` und alles andere ruhig, aber nie beides orange.

## Verbote

- Kein Text, keine Ziffern, kein App-Name im Icon.
- Keine Galaxie- oder Sternenoptik, kein Funkeln, kein Weltraum.
- Keine Verläufe, Schatten, Glanzlichter, 3D-Effekte oder Glas.
- Kein Pendel-Metronom aus Holz, keine Trommel, keine Sticks, keine Notenschlüssel, keine Stock-Motive.
- Kein reines Schwarz, kein Weiß als Fläche, keine weitere Akzentfarbe.
- Nicht mehr als eine orange Form.
- Keine Linien oder Punktabstände unter 2 px bei 60 pt.
- Keine eigenen gerundeten Ecken am Icon-Rand, keine Transparenz im Master.

## Formate

- **Master:** 1024 mal 1024 px, quadratisch, randlos gefüllt, ohne Transparenz, ohne gerundete Ecken (iOS rundet selbst). Motiv innerhalb eines Sicherheitsbereichs von etwa 80 Prozent der Fläche halten, damit nichts in die Rundung läuft.
- **Dark-Variante:** gleiches Motiv, Grund `#1C1C1B`, Orange und `#DDDDDD` unverändert oder minimal angepasst für Kontrast. Da die App nur dunkel ist, dürfen Standard- und Dark-Variante nahezu gleich sein.
- **Tinted-Variante:** Graustufen. Grund schwarz, Motiv in Weiß und Grautönen, wobei der Schlag-Punkt der hellste Wert ist, damit er auch eingefärbt das Zentrum bleibt.
- **Ebenen:** Grund und Motiv zusätzlich als getrennte SVG-Ebenen liefern, damit das Icon später mit dem Icon Composer als Ebenen-Icon aufgebaut werden kann.
- **Dateien je Richtung:** `icon-<richtung>.svg`, `icon-<richtung>-dark.svg`, `icon-<richtung>-tinted.svg`, dazu PNG-Renderings in allen Prüfgrößen. Ablage in `docs/brand/icon-drafts/`.

## Lesbarkeitsprüfung

Jeden Entwurf aus dem SVG in diesen Größen rendern und nebeneinander auf `#1C1C1B` und auf einem hellen Homescreen-Hintergrund zeigen:

| Größe | Einsatz | Prüffrage |
|---|---|---|
| 1024 px | App Store | Sauber gebaut, Abstände gleichmäßig, Formen exakt rund? |
| 180 px | Homescreen iPhone 60 pt @3x | Wirkt es ruhig, ist der orange Schlag das Erste, was man sieht? |
| 120 px | Homescreen iPhone 60 pt @2x, Spotlight | Bleiben Punkte und Linien getrennt, kein Grauschleier? |
| 60 px | Spotlight und Einstellungen klein | Ist die Grundidee noch erkennbar (Raster, Welle, Kacheln oder M)? |
| 29 px | Einstellungen 29 pt @1x | Bleibt eine klare Form mit einem orangen Punkt, kein Rauschen? |

Ein Entwurf gilt als lesbar, wenn er bei 29 px noch als eigene Form mit einem orangen Schlag erkennbar ist und bei 60 px keine Linie oder Lücke unter 2 px liegt. Wo ein Motiv bei kleinen Größen zerfällt, die Zahl der Punkte reduzieren statt die Punkte zu verkleinern.

## Abgabe

Pro Richtung eine Vorschau-Tafel mit Master, Dark, Tinted und den fünf Prüfgrößen, dazu ein Satz zur Idee. Die Tafeln gehen an Alex zur Auswahl.
