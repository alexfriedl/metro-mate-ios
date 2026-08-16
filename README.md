<div align="center">

# Metro Mate

**A metronome that doesn't sell you anything.**

No ads. No subscription. No account. No tracking.
Free forever, and you can read every line of code that makes it tick.

[**→ Download free on the App Store**](https://apps.apple.com/app/id6747667519)

![Metro Mate on iPhone](https://github.com/user-attachments/assets/8299c602-f101-4803-8370-584af814efa8)

</div>

---

## Why another metronome?

Open the App Store and search for "metronome". You'll find a wall of free apps
that show you a video ad between practice sessions, or ask €6.99 a year for a
click track — technology that was invented in 1815.

Metro Mate is the metronome I wanted for my own practice: it starts instantly,
it keeps perfect time, and it gets out of the way. It is open source, which
means the "no tracking" promise above isn't something you have to take on
faith. You can check.

## What it does

**Keeps time you can trust.** Audio is driven by a high-precision timer, not by
the animation loop, so the click doesn't drift when your phone gets busy. It
keeps clicking even when your ringer is on silent.

**Tap tempo.** Don't know the BPM? Tap along with the track and Metro Mate
works it out for you. Range is 40–200 BPM, adjustable by 1 BPM at a time.

**Counts the way you count.** Switch the display between `1 & 2 &` and
`1 e & a`, and it counts triplets as `1 trip let`. Useful when you're teaching
subdivision and the student needs to *see* where "&" falls.

**Subdivisions.** Quarters, eighths, sixteenths, and triplet versions of each
(♩ ♪ ♬ ♩₃ ♪₃ ♬₃).

**Accents where you want them.** Tap any beat to accent it. Practice a 7/8 with
the accent on 1 and 5, or move the accent around a 4/4 to work on your
internal pulse.

**A beat grid, not just a click.** Build patterns across up to four rows and
sixteen steps — a click layer, a backbeat, a subdivision layer. Handy for
practising a groove rather than a pulse.

**Save your setups.** Store a beat as a named preset and pull it back up next
lesson — presets persist between sessions. No account needed; they stay on
your device and are never uploaded.

**Hands-free with Siri.** "Start Metro Mate at 90 BPM" works from across the
room — useful when your hands are already on the instrument. Works in English
and German.

**Haptics.** The phone taps along in your pocket or on the music stand.

## Get it

[**→ Metro Mate on the App Store**](https://apps.apple.com/app/id6747667519) —
free, no in-app purchases, no ads.

Requires an iPhone running **iOS 18 or later**.

If Metro Mate is useful to you, **please leave a rating**. It's a free app with
no marketing budget, and App Store ratings are essentially the only way other
musicians will ever find it. Thirty seconds of your time does more than
anything else you could do for this project.

## For teachers

If you teach, a few things here were built with you in mind:

- The **counting display** matches how you say it out loud, so students connect
  the sound to the syllables.
- **Presets** mean you can set up "student's tempo this week" once and recall it
  next lesson, instead of dialling in numbers while they wait.
- **Accent patterns** let you isolate a metric problem — put the click only on
  beat 2 and 4, or only on 1, and let the student hold the rest.
- No ads means nothing inappropriate appears mid-lesson, and no login means
  students under 13 can use it without a parent setting up an account.

Free to recommend to your whole studio. If it's missing something you need for
teaching, [tell me](https://github.com/alexfriedl/metro-mate-ios/issues/new/choose)
— that feedback is the most useful thing I get.

## Feedback and bugs

Found something broken, or missing a feature you rely on?
**[Open an issue](https://github.com/alexfriedl/metro-mate-ios/issues/new/choose)** —
you don't need to be a programmer, and you don't need to know any technical
terms. "The click drifts when I switch apps" is a perfect bug report.

If GitHub isn't your thing, an App Store review works too — I read all of them.

## Privacy

Metro Mate collects nothing. No analytics, no crash reporting, no advertising
identifiers, no network requests at all. Your presets live on your device and
nowhere else. See [PRIVACY.md](PRIVACY.md) for the long version — it's short.

## Contributing

Contributions are welcome, and **not just code**. Bug reports, feature ideas
from real practice rooms, translations, and better click sounds are all
genuinely useful. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Building from source

<details>
<summary>Developer instructions</summary>

**Requirements:** Xcode 16+, iOS 18.0+ deployment target, Swift 5.9+

```bash
git clone https://github.com/alexfriedl/metro-mate-ios.git
cd metro-mate-ios
open Metronome.xcodeproj
```

**Project structure**

| File | Purpose |
| --- | --- |
| `MetronomeApp.swift` | App entry point |
| `ContentView.swift` | Main UI and beat grid |
| `MetronomeManager.swift` | Timing engine and audio (`AVAudioEngine` + `DispatchSourceTimer`) |
| `BeatTile.swift` | Individual grid cell |
| `NoteValuePicker.swift` | Subdivision selector |
| `AppIntents.swift` | Siri Shortcuts |
| `StarFieldView.swift` | Background visual |
| `ColorExtension.swift` | UI utilities |

Audio assets are `normal_click.wav` (standard beat) and `accent_click.wav`
(accented beat), loaded into an `AVAudioPlayerNode`.

</details>

## License

[MIT](LICENSE) — use it, fork it, ship it, teach with it.

---

<div align="center">
Built by <a href="https://github.com/alexfriedl">Alexander Friedl</a>.
If Metro Mate is useful to you, a ⭐ helps other musicians find it.
</div>
