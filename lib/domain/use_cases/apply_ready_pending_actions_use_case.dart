import '../../data/repositories/accountability_repository.dart';
import '../../data/repositories/blocklist_repository.dart';
import '../../data/repositories/protection_repository.dart';
import '../models/pending_action.dart';

class ApplyReadyPendingActionsUseCase {
  ApplyReadyPendingActionsUseCase({
    required AccountabilityRepository accountabilityRepository,
    required ProtectionRepository protectionRepository,
    required BlocklistRepository blocklistRepository,
  })  : _accountabilityRepository = accountabilityRepository,
        _protectionRepository = protectionRepository,
        _blocklistRepository = blocklistRepository;

  final AccountabilityRepository _accountabilityRepository;
  final ProtectionRepository _protectionRepository;
  final BlocklistRepository _blocklistRepository;

  Future<List<PendingAction>> call() async {
    final actions = await _accountabilityRepository.loadPendingActions();
    final ready = actions.where((action) => action.isReadyToApply).toList();

    for (final action in ready) {
      await _apply(action);
      await _accountabilityRepository.markApplied(action);
      await _commit(action);
    }

    return ready;
  }

  Future<void> _apply(PendingAction action) async {
    switch (action.type) {
      case PendingActionType.disableProtection:
        await _protectionRepository.disable();
      case PendingActionType.removeBlocklistDomain:
        break;
      case PendingActionType.changeWebhookUrl:
      case PendingActionType.increaseSensitiveActionDelay:
      case PendingActionType.decreaseSensitiveActionDelay:
      case PendingActionType.deactivateDeviceAdmin:
        break;
    }
  }

  Future<void> _commit(PendingAction action) async {
    switch (action.type) {
      case PendingActionType.removeBlocklistDomain:
        final domain = action.payload['domain'];
        if (domain != null) {
          await _blocklistRepository.approveRemoval(domain);
          final domains = await _blocklistRepository.effectiveBlockedDomains();
          await _protectionRepository.syncBlocklist(domains);
        }
      case PendingActionType.changeWebhookUrl:
        final newUrl = action.payload['newUrl'];
        if (newUrl != null) {
          await _accountabilityRepository.applyWebhookUrlChange(newUrl);
        }
      case PendingActionType.increaseSensitiveActionDelay:
      case PendingActionType.decreaseSensitiveActionDelay:
        final minutes = action.payload['newDelayMinutes'];
        if (minutes != null) {
          await _accountabilityRepository.applyDelayChange(Duration(minutes: int.parse(minutes)));
        }
      case PendingActionType.disableProtection:
      case PendingActionType.deactivateDeviceAdmin:
        break;
    }
  }
}
