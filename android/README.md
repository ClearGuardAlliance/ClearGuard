# Native Android

This is a regular Flutter-generated Android project, committed like any other
part of the app. `MainActivity.kt`, `BlockerVpnService.kt`,
`ScreenContentMonitorService.kt`, `SettingsGuardService.kt`,
`BlockOverlayActivity.kt`, `ClearGuardDeviceAdminReceiver.kt`,
`BootReceiver.kt`, `NativeWebhookNotifier.kt`, and `Packets.kt` under
`app/src/main/kotlin/com/clearguardalliance/clearguard/` hold the
ClearGuard-specific native code; everything else is standard Gradle/AGP
boilerplate. Run `flutter pub get` from the project root, then run on a real
device or emulator (the DNS-filter VPN needs Android's networking stack; it
will not do anything meaningful on a headless CI runner, which is why
`.github/workflows/build.yml` only builds the APK rather than running it).

## Why DNS-only, not a full-tunnel VPN

`BlockerVpnService` routes only traffic addressed to its own fake DNS
resolver into the tunnel (`addRoute("10.111.222.2", 32)`), not
`0.0.0.0/0`. That means it never has to implement a full IP router/NAT for
ordinary web traffic. It only ever has to parse a DNS query, decide, and
answer. The trade-off is explicit: this blocks resolution of a domain, not
traffic to an IP address that's already resolved or hardcoded. It's the same
technique used by DNS66 and most non-root Android DNS-filtering apps.

## Resilience and tamper visibility

Beyond the accountability delay in `lib/domain`, a few things happen purely
on the native side, independent of whether the Flutter engine is even
running, matching what apps like Qustodio, Bark, and BlockerX do:

- `BootReceiver` restarts `BlockerVpnService` after the device reboots, if
  protection was active before shutdown. `BlockerVpnService` persists its
  own active/domains state to a dedicated `SharedPreferences` file on every
  start/stop/update, which `BootReceiver` reads back directly, so this
  works even if the Dart side never gets a chance to run.
- `NativeWebhookNotifier` sends a best-effort, single-attempt webhook post
  (reading the webhook URL straight out of the `shared_preferences` plugin's
  own storage file) whenever something happens outside the app's own gated
  flow: `ClearGuardDeviceAdminReceiver.onDisableRequested`/`onDisabled`
  (someone is trying to remove device admin), `BlockerVpnService.onRevoke`
  (VPN permission pulled from system settings), and
  `ScreenContentMonitorService.onUnbind` (accessibility service turned off).
  This is separate from, and does not replace, the queued/retried
  notifications the Dart-side `NotificationOutbox` sends for actions taken
  through the app itself.
- Settings has a battery-optimization exemption prompt
  (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`), since Android killing a
  backgrounded VPN service to save battery is one of the most common ways
  this kind of app silently stops working without anyone touching it.

None of this makes the app impossible to remove: Android always lets the
device owner revoke device admin, disable accessibility, revoke VPN
permission, or uninstall outright from system settings, and no non-MDM app
can prevent that. What this buys is the same thing the delay does: the
attempt is slow and it is seen, not silent.

## Known gaps (see also the top-level README's Limitations section)

- `PendingActionType.deactivateDeviceAdmin` has no corresponding UI action,
  and it never will: Android does not let a non-MDM app intercept or delay
  the system's own "remove device admin" flow, so there is nothing for the
  app to gate. Activating device admin (the useful half) is wired up in
  Settings, via an `ACTION_ADD_DEVICE_ADMIN` intent from `MainActivity`.
- The DNS packet parsing/building in `Packets.kt` is unit-testable in
  isolation (pure functions over `ByteArray`) but has not been exercised
  against a real device. Checksum and offset bugs in hand-rolled packet code
  are exactly the kind of thing that looks right on inspection and breaks on
  a real network stack. Test on a device before trusting it.
- `NativeWebhookNotifier` reads the webhook URL out of the
  `shared_preferences` plugin's Jetpack DataStore file
  (`FlutterSharedPreferences`, key `flutter.accountability_webhook_url`),
  reusing that plugin's own `sharedPreferencesDataStore` extension property
  rather than opening a second DataStore instance for the same file (which
  throws at runtime: DataStore only allows one open instance per file per
  process). This compiles, and the approach is the standard workaround for
  reading Flutter's preferences from a native callback that runs without
  the Flutter engine, but the actual read has not been exercised on a
  device.
- `ScreenContentMonitorService.onUnbind` fires on any unbind, not only a
  deliberate "turn this off in Settings" action, so its tamper notification
  can have false positives (e.g. the OS rebinding the service). Better than
  no signal, but treat it as a hint, not proof.
