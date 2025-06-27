# Metronome

Ein einfaches Metronom für iOS, entwickelt in SwiftUI.

## Features

- BPM-Einstellung von 40 bis 200
- Verschiedene Notenwerte (Viertel, Achtel, Sechzehntel, Triolen)
- Grid-basierte Beat-Patterns
- Tap Tempo
- Beat-Presets und -Speicherung
- Accent-Pattern
- Haptic Feedback

## Entwicklung

### Voraussetzungen

- Xcode 15+
- iOS 16+
- Swift 5.9+

### Setup

```bash
git clone https://github.com/[username]/Metronome.git
cd Metronome
open Metronome.xcodeproj
```

### Projekt-Struktur

- `MetronomeApp.swift` - App Entry Point
- `ContentView.swift` - Haupt-UI und Beat-Grid
- `MetronomeManager.swift` - Core Logic und Audio
- `ColorExtension.swift` - UI Utilities

## Beitragen

Contributions sind willkommen! Bitte:

1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/neue-funktion`)
3. Committe deine Änderungen (`git commit -m 'Neue Funktion hinzugefügt'`)
4. Push zum Branch (`git push origin feature/neue-funktion`)
5. Öffne eine Pull Request

### Code Style

- Swift Standard Conventions
- SwiftUI best practices
- Aussagekräftige Commit Messages

## Lizenz

GPL v3 mit zusätzlichen Bedingungen - siehe [LICENSE](LICENSE)

**Wichtig:** Dieses Projekt ist ausschließlich für Open Source Nutzung, Lernen und Inspiration gedacht. Kommerzielle Nutzung ist nicht gestattet.

## Audio

Das Projekt verwendet Standard-Click-Sounds:
- `normal_click.wav` - Standard Beat
- `accent_click.wav` - Akzentuierter Beat