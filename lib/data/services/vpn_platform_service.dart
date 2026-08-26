import 'package:flutter/services.dart';

import '../../domain/models/protection_status.dart';

/// Bridges to `BlockerVpnService` on Android (see
/// native_android/kotlin/BlockerVpnService.kt) through a MethodChannel for
/// commands and an EventChannel for status updates. The native side owns
/// the actual TUN interface and DNS filtering; this class only ever sends
/// it instructions and listens for what it reports back — it does not
/// trust the Dart side to know the real state.
class VpnPlatformService {
  VpnPlatformService({
    MethodChannel? methodChannel,
    EventChannel? statusChannel,
  })  : _method = methodChannel ??
            const MethodChannel('com.clearguard.app/vpn'),
        _status =
            statusChannel ?? const EventChannel('com.clearguard.app/vpn/status');

  final MethodChannel _method;
  final EventChannel _status;

  /// Triggers the Android VPN consent dialog if not already granted.
  /// Must be called before [start] the first time.
  Future<bool> requestPermission() async {
    final granted = await _method.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  }

  Future<void> start(List<String> blockedDomains) {
    return _method.invokeMethod('start', {'domains': blockedDomains});
  }

  Future<void> stop() {
    return _method.invokeMethod('stop');
  }

  Future<void> updateBlocklist(List<String> blockedDomains) {
    return _method.invokeMethod('updateBlocklist', {'domains': blockedDomains});
  }

  Future<ProtectionStatus> currentStatus() async {
    final raw = await _method.invokeMethod<String>('currentStatus');
    return _parse(raw);
  }

  /// Live status stream driven by the native service (e.g. the OS killed
  /// the VPN, or the user revoked the VPN permission from system settings).
  Stream<ProtectionStatus> statusStream() {
    return _status.receiveBroadcastStream().map((event) => _parse(event as String?));
  }

  ProtectionStatus _parse(String? raw) {
    switch (raw) {
      case 'active':
        return ProtectionStatus.active;
      case 'starting':
        return ProtectionStatus.starting;
      case 'disabled':
        return ProtectionStatus.disabled;
      default:
        return ProtectionStatus.error;
    }
  }
}
