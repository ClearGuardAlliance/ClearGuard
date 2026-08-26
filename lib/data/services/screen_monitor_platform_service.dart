import 'package:flutter/services.dart';

class ScreenMonitorPlatformService {
  ScreenMonitorPlatformService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('com.clearguard.app/screen_monitor');

  final MethodChannel _channel;

  Future<bool> isAccessibilityPermissionGranted() async {
    final granted = await _channel.invokeMethod<bool>('isPermissionGranted');
    return granted ?? false;
  }

  Future<void> openAccessibilitySettings() {
    return _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> updateKeywords(List<String> keywords) {
    return _channel.invokeMethod('updateKeywords', {'keywords': keywords});
  }
}
