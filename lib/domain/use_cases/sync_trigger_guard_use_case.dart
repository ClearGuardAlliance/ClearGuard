import 'package:clearguard/data/repositories/block_window_repository.dart';
import 'package:clearguard/data/services/trigger_guard_platform_service.dart';
import 'package:clearguard/domain/models/trigger_app.dart';

class SyncTriggerGuardUseCase {
  SyncTriggerGuardUseCase({
    required BlockWindowRepository blockWindowRepository,
    required TriggerGuardPlatformService platformService,
  })  : _blockWindowRepository = blockWindowRepository,
        _platformService = platformService;

  final BlockWindowRepository _blockWindowRepository;
  final TriggerGuardPlatformService _platformService;

  Future<void> call() async {
    final window = await _blockWindowRepository.current();
    await _platformService.syncConfig(
      packages: TriggerApp.catalog.map((app) => app.packageName).toList(),
      window: window,
    );
  }
}
