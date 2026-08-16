# Contributing to Metro Mate

Most projects open this file with "thanks for your interest in contributing"
and then immediately start talking about pull requests. So, to be clear:

**You do not need to be a programmer to contribute here, and the most valuable
contributions to Metro Mate are not code.**

I can write Swift. I cannot tell what it's like to teach a ten-year-old
sixteenth notes on a Tuesday afternoon. That's the part I need help with.

---

## If you play or teach music

### Tell me when something is wrong

The single most useful thing you can do.
**[Report a problem →](https://github.com/alexfriedl/metro-mate-ios/issues/new/choose)**

You don't need technical vocabulary. All of these are excellent bug reports:

- "The click sounds late when I switch to triplets."
- "It stopped when a phone call came in and didn't start again."
- "I can't read the numbers in bright sunlight at an outdoor gig."
- "My students keep tapping the wrong thing to change the tempo."

Write it the way you'd say it to a friend. If I need something technical, I'll
ask.

### Tell me what's missing for your instrument

Metro Mate was shaped by one person's practice habits, which means it is
probably subtly wrong for yours. Drummers, singers, string players and pianists
all want different things from a metronome, and I only actually know what one
of them wants.

Particularly useful: **what do you currently do with a different app or a
physical metronome that Metro Mate can't do?**

### Tell me what breaks in a lesson

If you teach, you see this app used by people who didn't choose it and aren't
patient with it. That's the most honest usability testing that exists. If a
student got confused, that's a bug in the app, not in the student — please
tell me about it.

### Better click sounds

The current sounds are two plain `.wav` files. If you have a better click — a
woodblock, a rimshot, a cowbell, something that cuts through a loud room — and
you own the rights to it or it's public domain, open an issue. Please say where
the sound came from so the licensing stays clean.

### Translations

The app currently speaks English and German. If you'd like it in your language,
say so in an issue — including whether your language counts subdivisions
differently, which matters more than the translation itself.

### Just tell people about it

Genuinely. If Metro Mate is useful in your studio, telling three colleagues
does more for this project than most code changes. A ⭐ on the repository helps
other musicians find it.

---

## If you write code

The usual flow:

1. Fork the repository
2. Create a branch (`git checkout -b feature/your-thing`)
3. Commit your changes
4. Push and open a pull request

**Before starting something big, open an issue first.** I'd rather talk about
an idea for ten minutes than have you spend a weekend on something I have to
turn down.

### Requirements

Xcode 16+, iOS 18.0+ deployment target, Swift 5.9+. No package manager, no
external dependencies — clone it and open `Metronome.xcodeproj`.

### Where things live

| File | Purpose |
| --- | --- |
| `MetronomeApp.swift` | App entry point |
| `ContentView.swift` | Main UI and beat grid |
| `MetronomeManager.swift` | Timing engine and audio |
| `BeatTile.swift` | Individual grid cell |
| `NoteValuePicker.swift` | Subdivision selector |
| `AppIntents.swift` | Siri Shortcuts |
| `StarFieldView.swift` | Background visual |
| `ColorExtension.swift` | UI utilities |

### Two rules that matter more than style

**Timing is the product.** Audio scheduling runs on a `DispatchSourceTimer`
feeding an `AVAudioEngine`, deliberately decoupled from SwiftUI's render loop.
If you touch the timing path, please check the click against a known-good
reference at a few tempos before opening the PR. A metronome that drifts is
worse than no metronome, and drift is easy to introduce and hard to notice.

**Nothing phones home.** Metro Mate has no network code, no analytics, and no
third-party dependencies, and the [privacy policy](PRIVACY.md) promises it
stays that way. PRs that add a dependency, a network call, or any form of
tracking won't be merged. If you think there's a genuine exception, open an
issue and make the case first.

### Style

Standard Swift conventions and SwiftUI best practice. Match the surrounding
code. Meaningful commit messages.

### Licensing of contributions

Metro Mate is [MIT licensed](LICENSE). By opening a pull request you agree
your contribution is released under the same licence, so the app can be
distributed freely — including on the App Store.

---

## Code of conduct

Be decent to people. The full version is in
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Not sure where to start?

Look for issues labelled
[`good first issue`](https://github.com/alexfriedl/metro-mate-ios/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
— or just open an issue and ask.
