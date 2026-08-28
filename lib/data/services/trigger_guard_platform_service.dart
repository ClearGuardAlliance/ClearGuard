import 'package:clearguard/domain/models/block_window.dart';
import 'package:flutter/services.dart';

class TriggerGuardPlatformService {
  TriggerGuardPlatformService({MethodChannel? methodChannel})
      : _method = methodChannel ??
            const MethodChannel('com.clearguard.app/trigger_guard');

  final MethodChannel _method;

  Future<void> syncConfig({
    required List<String> packages,
    required BlockWindow window,
  }) {
    return _method.invokeMethod('syncConfig', {
      'packages': packages,
      'windowEnabled': window.enabled,
      'windowStartMinutes': window.startMinutes,
      'windowEndMinutes': window.endMinutes,
    });
  }
}
