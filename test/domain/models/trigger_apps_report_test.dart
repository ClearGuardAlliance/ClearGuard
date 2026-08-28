import 'package:clearguard/domain/models/trigger_app.dart';
import 'package:clearguard/domain/models/trigger_apps_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TriggerAppsReport', () {
    const social = TriggerApp(
      packageName: 'com.example.social',
      displayName: 'Social',
      category: TriggerAppCategory.socialMedia,
      weight: 2,
    );
    const vpn = TriggerApp(
      packageName: 'com.example.vpn',
      displayName: 'VPN',
      category: TriggerAppCategory.circumvention,
      weight: 4,
    );

    test('riskLevel is none when no apps detected', () {
      const report = TriggerAppsReport(detectedApps: [], score: 0);

      expect(report.riskLevel, TriggerAppsRiskLevel.none);
    });

    test('riskLevel is low for a small score', () {
      const report = TriggerAppsReport(detectedApps: [social], score: 2);

      expect(report.riskLevel, TriggerAppsRiskLevel.low);
    });

    test('riskLevel is medium for a moderate score', () {
      const report = TriggerAppsReport(detectedApps: [social, vpn], score: 6);

      expect(report.riskLevel, TriggerAppsRiskLevel.medium);
    });

    test('riskLevel is high once the score passes the medium threshold', () {
      const report = TriggerAppsReport(
        detectedApps: [social, vpn, vpn],
        score: 10,
      );

      expect(report.riskLevel, TriggerAppsRiskLevel.high);
    });

    test('byCategory filters detected apps by category', () {
      const report = TriggerAppsReport(detectedApps: [social, vpn], score: 6);

      expect(report.byCategory(TriggerAppCategory.socialMedia), [social]);
      expect(report.byCategory(TriggerAppCategory.circumvention), [vpn]);
      expect(report.byCategory(TriggerAppCategory.dating), isEmpty);
    });
  });
}
