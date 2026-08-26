import '../../data/repositories/accountability_repository.dart';
import '../models/pending_action.dart';

class PinRejectedException implements Exception {
  const PinRejectedException();
}

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
