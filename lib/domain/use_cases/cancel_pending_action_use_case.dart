import '../../data/repositories/accountability_repository.dart';

/// Cancelling a pending weakening of protection is intentionally
/// frictionless — no PIN required. Making it easy to back out of a request
/// costs nothing security-wise (it can only make protection stronger) and
/// gives the requester a low-cost off-ramp during the cooling-off window.
class CancelPendingActionUseCase {
  CancelPendingActionUseCase({required AccountabilityRepository repository})
      : _repository = repository;

  final AccountabilityRepository _repository;

  Future<void> call(String pendingActionId) {
    return _repository.cancelPendingAction(pendingActionId);
  }
}
