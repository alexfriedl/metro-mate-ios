# Privacy Policy

**Last updated: 30 December 2025**

Metro Mate collects no data about you. None.

That's the whole policy, but here is the detail, because "we value your
privacy" is a sentence that has been ruined by everyone who has ever written
it.

## What Metro Mate does not do

- **No analytics.** No Firebase, no Google Analytics, no Mixpanel, no
  home-grown event tracking.
- **No crash reporting.** No Sentry, no Crashlytics.
- **No advertising.** No ad SDKs, no advertising identifier (IDFA), no
  App Tracking Transparency prompt, because there is nothing to ask about.
- **No account.** There is no sign-up, no login, no email address collected.
- **No network access.** Metro Mate makes no network requests of any kind. It
  works identically in airplane mode.
- **No third-party code.** The app has zero external dependencies. Everything
  it runs is in this repository.

## What stays on your device

Your tempo, subdivision, accent pattern, beat grid and saved presets exist only
in the app on your phone. They are never transmitted anywhere. If you delete
the app, they are gone.

## Permissions

Metro Mate requests one capability: **Siri**, so that "Start Metro Mate at 90
BPM" works. Siri requests are handled by Apple under
[Apple's privacy policy](https://www.apple.com/legal/privacy/); Metro Mate
receives only the tempo number you said. It does not request microphone,
contacts, location, photos, or notifications.

## What Apple sees

Metro Mate is distributed through the App Store, and **Apple** — not this app —
collects the standard platform metrics that apply to every app on iOS:
downloads, and, *only if you switched on "Share With App Developers"* in
Settings → Privacy & Security → Analytics & Improvements, aggregate usage and
crash statistics. I see those as anonymised totals in App Store Connect; they
are not linked to you and I could not identify you from them if I wanted to.

That is a function of the App Store, not of anything in this app's code. See
[Apple's privacy policy](https://www.apple.com/legal/privacy/).

If you leave an App Store review, I see whatever name and text you chose to
publish there.

## Children

Metro Mate is safe for students of any age, and is rated 4+ on the App Store.
It has no ads, no purchases, no chat, no user-generated content, no links out
to the web, and no way to create an account.

## Verifying this

You do not have to believe any of the above. The complete source code is in
this repository under the MIT licence. Search it for `URLSession`, `http`,
`Analytics` or `IDFA` and you will find nothing, because there is nothing to
find.

## Changes

If this ever changes — for example, if a future version adds an optional
sync feature — this file will be updated before that version ships, and the
change will be visible in this repository's history.

## Contact

Questions: [open an issue](https://github.com/alexfriedl/metro-mate-ios/issues)
or contact [@alexfriedl](https://github.com/alexfriedl).
