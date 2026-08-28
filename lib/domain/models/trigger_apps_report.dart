import 'package:clearguard/domain/models/trigger_app.dart';

enum TriggerAppsRiskLevel { none, low, medium, high }

class TriggerAppsReport {
  const TriggerAppsReport({required this.detectedApps, required this.score});

  final List<TriggerApp> detectedApps;
  final int score;

  TriggerAppsRiskLevel get riskLevel {
    if (score <= 0) return TriggerAppsRiskLevel.none;
    if (score <= 3) return TriggerAppsRiskLevel.low;
    if (score <= 7) return TriggerAppsRiskLevel.medium;
    return TriggerAppsRiskLevel.high;
  }

  List<TriggerApp> byCategory(TriggerAppCategory category) =>
      detectedApps.where((app) => app.category == category).toList();
}
