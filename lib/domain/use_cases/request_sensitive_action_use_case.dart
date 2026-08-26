import '../../data/repositories/accountability_repository.dart';
import '../models/pending_action.dart';

class PinRejectedException implements Exception {
  const PinRejectedException();
}

/// Entry point for every action that would weaken protection. The PIN gate
/// exists mainly to stop an accidental tap, not to stop a determined
/// technical user — the real barrier is that the action does not take
/// effect until [PendingAction.readyAt], and the accountability partner is
/// notified the instant the request is made. See
/// AccountabilityRepository.createPendingAction.
class RequestSensitiveActionUseCase {
  RequestSensitiveActionUseCase({required AccountabilityRepository repository})
      : _repository = repository;

  final AccountabilityRepository _repository;

  Future<PendingAction> call({
    required String pin,
    required PendingActionType type,
    Map<String, String> payload = const {},
  }) async {
    final isValid = await _repository.verifyPin(pin);
    if (!isValid) throw const PinRejectedException();

    return _repository.createPendingAction(type: type, payload: payload);
  }
}
