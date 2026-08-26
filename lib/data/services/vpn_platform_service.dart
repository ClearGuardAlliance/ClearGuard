import 'package:flutter/services.dart';

import '../../domain/models/protection_status.dart';

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
