import 'package:flutter/services.dart';

/// Bridges to `ScreenContentMonitorService`, the AccessibilityService-based
/// fallback layer on Android (see
/// native_android/kotlin/ScreenContentMonitorService.kt). This catches
/// content that DNS blocking misses — text on already-resolved pages,
/// search results, in-app browsers — by scanning visible text nodes for
/// explicit-content keywords and covering the screen when matched.
///
/// This is a keyword heuristic, not an image classifier: it does not
/// analyze photos or video frames. Real on-device NSFW image detection
/// needs a bundled vision model (e.g. a TFLite classifier) and is left as
/// a documented follow-up in README.md rather than faked here.
class ScreenMonitorPlatformService {
  ScreenMonitorPlatformService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.clearguard.app/screen_monitor');

  final MethodChannel _channel;

  Future<bool> isAccessibilityPermissionGranted() async {
    final granted = await _channel.invokeMethod<bool>('isPermissionGranted');
    return granted ?? false;
  }

  /// Opens system Accessibility settings so the user can grant the
  /// permission manually — Android does not allow apps to request this
  /// permission through a normal runtime prompt.
  Future<void> openAccessibilitySettings() {
    return _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> updateKeywords(List<String> keywords) {
    return _channel.invokeMethod('updateKeywords', {'keywords': keywords});
  }
}
