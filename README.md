<!-- Languages: English | [Português](README.pt.md) | [עברית](README.he.md) | [Русский](README.ru.md) | [中文](README.zh.md) | [日本語](README.ja.md) | [العربية](README.ar.md) -->

# ClearGuard

ClearGuard is an Android app that blocks pornography through local DNS filtering and, as a backup, by reading on-screen text. The core difference is that disabling protection is never instant: every request to weaken protection goes through a waiting period and notifies a trusted partner before it takes effect.

## How it works

The main blocking runs on a local VPN that filters DNS queries against the blocked domain list. An accessibility service reads visible on-screen text as an extra layer, to catch content that got past the DNS filter. Any action that weakens protection, such as disabling blocking or removing a domain, creates a pending request with a PIN, a delay, and a notification to the partner. Strengthening protection is always immediate.

## Architecture

The Flutter code lives in `lib`, split into `data` (services and repositories), `domain` (models and business rules), and `ui` (screens and view models). The native Android code lives in `native_android`, with the VPN service, the screen monitor, and instructions for integrating it into a generated Flutter project. The visual identity (`lib/ui/core/theme/app_theme.dart`) is a Material 3 theme built from a deep jade seed color, with Manrope for headings and Inter for body text; both fonts are bundled as local assets so the app never depends on network access to render correctly.

## Limitations

DNS blocking does not stop direct access by IP. The VPN permission and the accessibility service can be revoked by the device owner from system settings, and no non-MDM app can prevent that.

## Running

```bash
flutter pub get
flutter test
```

For the Android side, follow `native_android/README.md`. To build an APK without setting anything up locally, run the `Build Android app` workflow from the Actions tab. Every push and pull request also runs formatting, static analysis (`very_good_analysis`), and tests through the `CI` workflow, and Dependabot keeps dependencies up to date automatically.
