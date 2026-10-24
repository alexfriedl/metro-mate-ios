# Icon-Abnahme: Entwürfe A bis D

Grundlage: `docs/brand/icon-brief.md` und `docs/BRAND.md`. Bewertet wurden `icon-drafts/overview.png`, die SVGs und die PNGs in 1024 und 29 px.

## Ergebnis

- **Empfehlung: D, M aus Schlägen.** Überarbeiten nach den Punkten unten, dann als Vorschau an Alex.
- **Alternative: A, Schlag im Raster.** Nur in der vereinfachten Form unten.
- **Verworfen: B und C.**

## Bewertung je Entwurf

### A. Schlag im Raster

Trägt
- Am nächsten an der App: Punkte, ein oranger Schlag, ruhiger Grund.
- Farben korrekt, nur eine orange Form, keine Effekte.

Trägt nicht
- Bei 29 px wird das 4 mal 4 Raster zur grauen Punktfläche. Lücken und Punkte liegen bei etwa 3 px, der orange Punkt bleibt, das Raster nicht.
- Der orange Punkt sitzt mit Mitte bei 218 px und Rand bei 122 px sehr nah an der iOS-Rundung. Auf dem Homescreen wirkt er in die Ecke gedrückt.
- 16 gleiche Punkte erinnern an Würfel, Braille oder eine LED-Matrix. Allein erzählt das noch nicht "Metronom".

### B. Die Welle springt

- Die Idee stimmt, die Umsetzung ist zu voll: 14 Punkte, 3 Linien, 3 Grautöne.
- Bei 60 und 29 px wird daraus eine unruhige Pyramide, die eher wie ein Tannenbaum oder ein Pfeil nach oben wirkt.
- Der orange Punkt in der Mitte verliert sich zwischen den Linien.
- Verworfen. Die Wellenfläche bleibt Motiv für Store-Bilder und die App, nicht fürs Icon.

### C. Zählzeit-Kacheln

- Bei 29 px am klarsten lesbar, aber generisch. Vier Quadrate im 2 mal 2 kennt man von Betriebssystem-, Widget- und Launcher-Logos.
- Die orange Kachel deckt rund ein Zehntel des Icons in Vollton ab. Das ist zu viel Orange für eine Marke, in der Orange nur der Schlag ist.
- Ohne Punkte und ohne Bewegung fehlt das Taktgefühl.
- Verworfen.

### D. M aus Schlägen

Trägt
- Eigene Silhouette, die bei 29 px als "M mit orangem Punkt" erkennbar bleibt.
- Voller Kontrast `#DDDDDD` auf `#1C1C1B`, genau ein oranger Punkt, flach, ohne Verlauf.
- Nimmt den Wiedererkennungswert des alten M mit, ersetzt aber die Bänder durch Schläge und eine Pulslinie. Das ist der Schritt vom austauschbaren Buchstaben zur Marke.
- Der Akzent liegt auf der linken Spitze, also auf dem Ausschlag. Das passt zur App, in der der Akzent springt.
- Tinted funktioniert, weil der Schlag-Punkt der hellste Wert ist.

Trägt noch nicht
- Die fünf Punkte liegen in ungleichen Abständen (120, 170, 170, 120 px). So liest man eher ein Liniendiagramm als gleichmäßige Schläge.
- Gelenkpunkte mit Durchmesser 124 px auf einer 64 px starken Linie ergeben ein Verhältnis von fast 2 zu 1. Das sieht nach Molekül oder Netzwerkgrafik aus.
- Der orange Punkt verschmilzt bei 29 px mit dem grauen Strich an seiner rechten Seite.
- Die Linie ist bei 29 px knapp unter 2 px stark (64 von 1024).
- Das Motiv sitzt optisch leicht zu hoch, weil der große orange Punkt oben links Gewicht zieht.

## Verbesserungen für D (Empfehlung)

Maße beziehen sich auf den 1024er Master.

1. **Gleichmäßiger Takt:** Alle fünf Punkte auf gleiche horizontale Abstände von 160 px setzen: x = 192, 352, 512, 672, 832. Höhen bleiben: Füße y 760, Spitzen y 290, Tal y 600. So sieht man fünf Schläge im Raster und keine Kurve.
2. **Gewichtung Linie zu Punkt:** Linienstärke von 64 auf 72 px, damit sie bei 29 px über 2 px bleibt. Graue Gelenkpunkte von Radius 62 auf 60 px. Das Verhältnis Punkt zu Linie liegt dann bei etwa 1,7 und wirkt weniger wie eine Netzwerkgrafik.
3. **Schlag freistellen:** Den orangen Punkt von Radius 104 auf 112 px. Darum einen Freiraum-Ring in Grundfarbe `#1C1C1B` mit 16 px Breite legen (eigener Kreis mit Radius 128 px unter dem orangen Punkt, über der Linie). Flach, kein Schatten. Damit bleibt der Punkt bei 29 px ein eigener Schlag und klebt nicht an der Linie.
4. **Optische Mitte:** Das ganze Motiv um 16 px nach unten schieben. Oberkante liegt dann bei etwa 194 px, Unterkante bei 836 px. Seitlich bleibt es symmetrisch (Außenkanten 132 und 892 px, innerhalb des Sicherheitsbereichs von 102 bis 922 px).
5. **Farben:** Grund `#1C1C1B`, Linie und graue Punkte `#DDDDDD`, Schlag `#F54206`. Nichts anderes.
6. **Tinted:** Grau von `#B4B4B4` auf `#9A9A9A` absenken, Schlag-Punkt bleibt `#FFFFFF`, Grund `#000000`. So bleibt der Abstand zwischen Linie und Schlag auch eingefärbt deutlich.
7. **Dark:** identisch mit dem Standard-Master, der Freiraum-Ring nimmt die Grundfarbe mit.
8. **Ebenen:** Grund, Linie mit grauen Punkten, Freiraum-Ring und oranger Punkt als getrennte SVG-Ebenen. Später lässt sich der Schlag im Icon Composer als eigene Ebene animieren oder hervorheben.
9. **Zusatzprüfung:** Das Icon auf einem dunklen und einem hellen Homescreen neben Mail-, Gmail- und Medium-Icons zeigen. Das alte M hatte genau dort ein Verwechslungsproblem, das neue darf es nicht haben.

Danach bitte erneut: Master, Dark, Tinted, 180, 120, 60, 29 px und 29 px gezoomt, auf dunklem und hellem Homescreen.

## Verbesserungen für A (Alternative)

1. **Weniger Punkte:** Statt 4 mal 4 ein Raster aus 3 mal 3 Punkten, Abstand 232 px von Mitte zu Mitte, Raster mittig (Mitten bei x und y = 280, 512, 744).
2. **Gewichtung:** Graue Punkte mit Radius 64 px, oranger Schlag mit Radius 112 px auf der ersten Position oben links (Mitte 280, 280). Der Abstand zur iOS-Rundung wächst damit deutlich.
3. **Farbe:** Graue Punkte von `#90908F` auf `#7A7A79` absenken, damit der orange Schlag noch klarer führt. Grund `#1C1C1B`.
4. **Tinted:** Grau `#6A6A6A`, Schlag `#FFFFFF`, Grund `#000000`.
5. **Prüfung:** Bei 29 px müssen die neun Punkte einzeln erkennbar sein. Gelingt das nicht, auf 3 Punkte in einer Reihe plus Schlag reduzieren, statt die Punkte kleiner zu machen.

## Nächster Schritt

Der Grafiker überarbeitet D und A und legt neue Vorschau-Tafeln in `docs/brand/icon-drafts/` ab. Danach gehen beide an Alex zur Auswahl. Erst nach seinem Ja kommt ein Icon in den Asset-Katalog.
