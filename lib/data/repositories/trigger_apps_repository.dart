import 'package:clearguard/data/services/installed_apps_platform_service.dart';
import 'package:clearguard/domain/models/trigger_app.dart';
import 'package:clearguard/domain/models/trigger_apps_report.dart';

class TriggerAppsRepository {
  TriggerAppsRepository({
    required InstalledAppsPlatformService installedAppsService,
  }) : _installedAppsService = installedAppsService;

  final InstalledAppsPlatformService _installedAppsService;

  Future<TriggerAppsReport> scan() async {
    final candidates = TriggerApp.catalog.map((app) => app.packageName);
    List<String> installedPackages;
    try {
      installedPackages = await _installedAppsService.installedFrom(
        candidates.toList(),
      );
    } on Exception {
      installedPackages = const [];
    }

    final detected = TriggerApp.catalog
        .where((app) => installedPackages.contains(app.packageName))
        .toList();
    final score = detected.fold<int>(0, (sum, app) => sum + app.weight);

    return TriggerAppsReport(detectedApps: detected, score: score);
  }
}
