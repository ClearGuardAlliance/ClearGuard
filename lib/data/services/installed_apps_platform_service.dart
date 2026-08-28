import 'package:flutter/services.dart';

class InstalledAppsPlatformService {
  InstalledAppsPlatformService({MethodChannel? methodChannel})
      : _method = methodChannel ??
            const MethodChannel('com.clearguard.app/installed_apps');

  final MethodChannel _method;

  Future<List<String>> installedFrom(List<String> candidatePackages) async {
    final result = await _method.invokeListMethod<String>(
      'installedFrom',
      {'packages': candidatePackages},
    );
    return result ?? const [];
  }
}
