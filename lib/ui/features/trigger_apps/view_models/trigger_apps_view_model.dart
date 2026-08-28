import 'package:clearguard/domain/models/trigger_apps_report.dart';
import 'package:clearguard/domain/use_cases/detect_trigger_apps_use_case.dart';
import 'package:flutter/foundation.dart';

class TriggerAppsViewModel extends ChangeNotifier {
  TriggerAppsViewModel({required DetectTriggerAppsUseCase detectTriggerApps})
      : _detectTriggerApps = detectTriggerApps;

  final DetectTriggerAppsUseCase _detectTriggerApps;

  TriggerAppsReport? _report;
  TriggerAppsReport? get report => _report;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _report = await _detectTriggerApps();

    _isLoading = false;
    notifyListeners();
  }
}
