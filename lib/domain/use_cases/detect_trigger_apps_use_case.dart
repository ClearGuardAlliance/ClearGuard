import 'package:clearguard/data/repositories/trigger_apps_repository.dart';
import 'package:clearguard/domain/models/trigger_apps_report.dart';

class DetectTriggerAppsUseCase {
  DetectTriggerAppsUseCase({required TriggerAppsRepository repository})
      : _repository = repository;

  final TriggerAppsRepository _repository;

  Future<TriggerAppsReport> call() => _repository.scan();
}
