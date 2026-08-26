# ClearGuard

An Android app that blocks pornographic content at the DNS level and, as a
fallback, by scanning on-screen text — and that makes disabling protection
slow and visible instead of a single silent toggle.

## Why it's built this way

Against someone who understands the device well enough to just turn a
blocker back off, a blocklist alone is not a real barrier — it buys seconds,
not minutes. ClearGuard's actual design goal is the same one physical
security uses for a server rack: make tampering slow (a delay before any
weakening change takes effect), visible (an accountability partner is
notified the moment a change is *requested*, not after it happens), and
reversible only through friction, not through no barrier at all. See
`lib/domain/use_cases/request_sensitive_action_use_case.dart` and
`accountability_repository.dart` for where that's implemented — every action
that weakens protection goes through a `PendingAction` with a delay and a
webhook notification; nothing that weakens protection is ever instant.

Strengthening protection (re-enabling, adding a blocked domain) is always
instant and ungated — friction is asymmetric on purpose.

## Architecture

Follows the layered MVVM structure from the `flutter-apply-architecture-best-practices`
skill:

```
lib/
├── data/            # Services (platform channels, HTTP, secure storage)
│                     and Repositories (single source of truth per concern)
├── domain/          # Pure models + use cases (the accountability/business rules)
└── ui/
    ├── core/         # Shared theme/widgets
    └── features/
        ├── onboarding/   # First-run setup: PIN, webhook, permissions
        └── dashboard/    # Status, pending-action countdown, disable request
```

Three platform channels bridge to Android-native code (not yet copied into a
real `android/` project — see `native_android/README.md`):

- `com.clearguard.app/vpn` (+ `.../vpn/status`) — controls `BlockerVpnService`,
  a local VPN that filters DNS queries against the blocklist.
- `com.clearguard.app/screen_monitor` — controls `ScreenContentMonitorService`,
  an AccessibilityService that scans visible text for explicit-content
  keywords as a fallback layer.

## What's implemented

- Full onboarding → dashboard flow with PIN + webhook + delay setup.
- `PendingAction` accountability queue: request → webhook notification →
  countdown → auto-apply → confirmation webhook, fully wired for
  **disabling protection**.
- Bundled + remote blocklist merging (`BlocklistRepository`), synced into the
  native VPN.
- Native DNS-filtering VPN service and AccessibilityService-based screen
  monitor, written but not yet build-verified (see Limitations).
- Widget test for `StatusBadge`, unit tests for `PendingAction`.

## What's scaffolded but not wired into the UI yet

- Removing a domain from the blocklist, changing the webhook URL, and
  changing the delay all exist as `PendingActionType`s with full repository
  and use-case support, but no dashboard/settings screen currently triggers
  them — only the disable-protection flow is exposed today.
- Device Admin registration (`ClearGuardDeviceAdminReceiver`) exists to add
  friction to uninstalling the app, but the activation intent is not yet
  called from onboarding.
- Content analysis is a keyword heuristic over on-screen text, not an image
  classifier — a bundled on-device NSFW vision model (e.g. TFLite) is the
  natural v2 for this and was left out rather than faked.

## Limitations, stated plainly

- **DNS-only blocking.** `BlockerVpnService` blocks domain resolution, not
  traffic to an already-known IP address or a hardcoded IP in an app. See
  `native_android/README.md` for why it's scoped this way.
- **The VPN permission is user-revocable at the OS level.** Android always
  lets the device owner pull VPN permission or disable the Accessibility
  service from system settings — no non-MDM app can prevent that. The
  accountability layer's job is to make that path slow/visible, not to make
  it impossible.
- **This machine had no Flutter/Android SDK**, so nothing here has been
  compiled or run. `lib/` is plain Dart/Flutter and should build cleanly
  once `flutter pub get` is run; the native Kotlin in `native_android/` needs
  the setup steps in its own README and real-device testing, especially the
  hand-rolled IPv4/UDP/DNS packet code in `Packets.kt`.
- **iOS is not implemented.** A content-filtering Network Extension on iOS
  needs a special entitlement from Apple and a different permission model —
  worth scoping separately if/when needed.

## Running

```bash
flutter pub get
flutter test          # StatusBadge widget test + PendingAction unit tests
```

For the Android app itself, follow `native_android/README.md` first.
