# Native Android integration

This folder is staging area, not a real `android/` project — this machine
has no Flutter SDK or Android SDK installed, so `flutter create` couldn't be
run to generate the real native shell (Gradle wrapper, `build.gradle.kts`,
the Flutter-embedding boilerplate in `AndroidManifest.xml`, etc.). Hand-writing
that boilerplate from memory risks silently mismatching whatever Flutter/AGP
version ends up being used. Instead, this folder holds the pieces that are
specific to ClearGuard and don't come from a template, ready to drop in once
the shell exists.

## Setup steps (run these where Flutter is actually installed)

1. From the project root, generate the native shell:
   ```bash
   flutter create --platforms=android --org com.clearguard -a kotlin .
   ```
   This only touches `android/` (and `ios/`, `web/`, etc. if you pass more
   platforms) — it will not overwrite `lib/`, `pubspec.yaml`, or `test/`.

2. Copy the Kotlin sources:
   ```bash
   cp native_android/kotlin/*.kt android/app/src/main/kotlin/com/clearguard/app/
   ```

3. Copy the resources:
   ```bash
   cp native_android/res/xml/*.xml android/app/src/main/res/xml/
   cp native_android/res/values/strings.xml android/app/src/main/res/values/strings.xml
   ```
   (Merge `strings.xml` by hand if `flutter create` already generated one with
   other keys in it.)

4. Merge `native_android/AndroidManifest_additions.xml` into
   `android/app/src/main/AndroidManifest.xml` — see the comments inside that
   file for exactly where each block goes.

5. `flutter pub get`, then run on a real device or emulator (the DNS-filter
   VPN needs Android's networking stack; it will not do anything meaningful
   on a headless CI runner).

## Why DNS-only, not a full-tunnel VPN

`BlockerVpnService` routes only traffic addressed to its own fake DNS
resolver into the tunnel (`addRoute("10.111.222.2", 32)`), not
`0.0.0.0/0`. That means it never has to implement a full IP router/NAT for
ordinary web traffic — it only ever has to parse a DNS query, decide, and
answer. The trade-off is explicit: this blocks resolution of a domain, not
traffic to an IP address that's already resolved or hardcoded. It's the same
technique used by DNS66 and most non-root Android DNS-filtering apps.

## Known gaps (see also the top-level README's Limitations section)

- `PendingActionType.deactivateDeviceAdmin`, `changeWebhookUrl`, and the
  delay-change types exist end-to-end in `lib/domain` and
  `AccountabilityRepository`, but nothing in the Dart UI currently triggers
  them — only `disableProtection` is wired into `DashboardView`. Wiring
  device-admin activation needs an `ACTION_ADD_DEVICE_ADMIN` intent call from
  `MainActivity`, not yet added.
- The DNS packet parsing/building in `Packets.kt` is unit-testable in
  isolation (pure functions over `ByteArray`) but has not been exercised
  against a real device — checksum and offset bugs in hand-rolled packet code
  are exactly the kind of thing that looks right on inspection and breaks on
  a real network stack. Test on a device before trusting it.
