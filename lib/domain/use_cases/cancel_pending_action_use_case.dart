import 'package:clearguard/data/repositories/accountability_repository.dart';

class CancelPendingActionUseCase {
  CancelPendingActionUseCase({required AccountabilityRepository repository})
      : _repository = repository;

  final AccountabilityRepository _repository;

  Future<void> call(String pendingActionId) {
    return _repository.cancelPendingAction(pendingActionId);
  }
}
