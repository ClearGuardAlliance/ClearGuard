import 'package:flutter/services.dart';

class InstalledAppsPlatformService {
  InstalledAppsPlatformService({MethodChannel? methodChannel})
      : _method = methodChannel ??
            const MethodChannel('com.clearguard.app/installed_apps');

  final MethodChannel _method;

  /// Returns the subset of [candidatePackages] that are installed on the
  /// device. Uses a package presence check rather than enumerating every
  /// installed app, so it needs no special installed-apps permission.
  Future<List<String>> installedFrom(List<String> candidatePackages) async {
    final result = await _method.invokeListMethod<String>(
      'installedFrom',
      {'packages': candidatePackages},
    );
    return result ?? const [];
  }
}
