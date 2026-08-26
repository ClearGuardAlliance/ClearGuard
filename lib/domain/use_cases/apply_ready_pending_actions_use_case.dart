import '../../data/repositories/accountability_repository.dart';
import '../../data/repositories/blocklist_repository.dart';
import '../../data/repositories/protection_repository.dart';
import '../models/pending_action.dart';

/// Runs on every app launch/resume and drains the pending-action queue:
/// anything whose delay has elapsed gets applied and its outcome announced
/// to the accountability partner. Nothing here should require user
/// interaction — a request that clears its delay while the app is closed
/// still needs to take effect the next time the app is opened, not wait
/// for the user to re-confirm it.
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
      // markApplied notifies via the config as it stood before this
      // action's own effect (e.g. a webhook change) takes hold.
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
        break; // committed in _commit, after the notification is sent
      case PendingActionType.changeWebhookUrl:
      case PendingActionType.increaseSensitiveActionDelay:
      case PendingActionType.decreaseSensitiveActionDelay:
      case PendingActionType.deactivateDeviceAdmin:
        break; // no-op here; see _commit
    }
  }

  /// Persists the config-level side effects after the "applied" webhook
  /// notification has already gone out on the pre-change configuration.
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
        break; // disableProtection already applied in _apply; device admin
        // deactivation is confirmed by the OS dialog itself, not here.
    }
  }
}
