# Metronome

A simple metronome app for iOS, built with SwiftUI.

## Features

- BPM settings from 40 to 200
- Various note values (quarter, eighth, sixteenth, triplets)
- Grid-based beat patterns
- Tap tempo
- Beat presets and saving
- Accent patterns
- Haptic feedback

## Development

### Requirements

- Xcode 15+
- iOS 16+
- Swift 5.9+

### Setup

```bash
git clone https://github.com/alexfriedl/metro-mate-ios.git
cd metro-mate-ios
open Metronome.xcodeproj
```

### Project Structure

- `MetronomeApp.swift` - App entry point
- `ContentView.swift` - Main UI and beat grid
- `MetronomeManager.swift` - Core logic and audio
- `ColorExtension.swift` - UI utilities

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

### Code Style

- Swift standard conventions
- SwiftUI best practices
- Meaningful commit messages

## License

GPL v3 with additional terms - see [LICENSE](LICENSE)

**Important:** This project is intended for open source use, learning, and inspiration only. Commercial use is not permitted.

## Audio

The project uses standard click sounds:
- `normal_click.wav` - Standard beat
- `accent_click.wav` - Accented beat