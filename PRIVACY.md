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

## During the TestFlight beta

While Metro Mate is distributed through TestFlight, **Apple** — not this app —
collects standard beta metrics such as installs, sessions, and crash logs, and
shows them to me in aggregate. That is a function of TestFlight itself and
applies to every beta app on the platform. See
[Apple's TestFlight terms](https://www.apple.com/legal/internet-services/itunes/testflight/).
If you send feedback through TestFlight, I see what you wrote, the screenshot
you attached, and your device model and iOS version.

## Children

Metro Mate is safe for students of any age. It has no ads, no purchases, no
chat, no user-generated content, no links out to the web, and no way to create
an account.

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
