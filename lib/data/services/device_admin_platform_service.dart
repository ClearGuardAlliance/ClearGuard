import 'package:flutter/services.dart';

class DeviceAdminPlatformService {
  DeviceAdminPlatformService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('com.clearguard.app/device_admin');

  final MethodChannel _channel;

  Future<bool> isActive() async {
    final active = await _channel.invokeMethod<bool>('isActive');
    return active ?? false;
  }

  Future<bool> requestActivation() async {
    final granted = await _channel.invokeMethod<bool>('requestActivation');
    return granted ?? false;
  }
}
