import 'package:clearguard/data/repositories/accountability_repository.dart';
import 'package:clearguard/data/repositories/blocklist_repository.dart';
import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/domain/use_cases/cancel_pending_action_use_case.dart';
import 'package:clearguard/domain/use_cases/request_sensitive_action_use_case.dart';
import 'package:clearguard/l10n/l10n_util.dart';
import 'package:flutter/foundation.dart';

class BlocklistViewModel extends ChangeNotifier {
  BlocklistViewModel({
    required BlocklistRepository blocklistRepository,
    required AccountabilityRepository accountabilityRepository,
    required RequestSensitiveActionUseCase requestSensitiveActionUseCase,
    required CancelPendingActionUseCase cancelPendingActionUseCase,
  })  : _blocklistRepository = blocklistRepository,
        _accountabilityRepository = accountabilityRepository,
        _requestSensitiveActionUseCase = requestSensitiveActionUseCase,
        _cancelPendingActionUseCase = cancelPendingActionUseCase;

  final BlocklistRepository _blocklistRepository;
  final AccountabilityRepository _accountabilityRepository;
  final RequestSensitiveActionUseCase _requestSensitiveActionUseCase;
  final CancelPendingActionUseCase _cancelPendingActionUseCase;

  List<String> _domains = const [];
  List<PendingAction> _pendingRemovals = const [];
  bool _isLoading = false;
  String _query = '';
  String? _errorMessage;

  bool get isLoading => _isLoading;
  int get totalCount => _domains.length;
  String? get errorMessage => _errorMessage;

  List<String> get filteredDomains {
    if (_query.isEmpty) return _domains;
    final needle = _query.toLowerCase();
    return _domains.where((d) => d.contains(needle)).toList();
  }

  String? pendingRemovalIdFor(String domain) {
    for (final action in _pendingRemovals) {
      if (action.payload['domain'] == domain) return action.id;
    }
    return null;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _domains = await _blocklistRepository.effectiveBlockedDomains();
    await _refreshPendingRemovals();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshPendingRemovals() async {
    final all = await _accountabilityRepository.loadPendingActions();
    _pendingRemovals = all
        .where(
          (action) => action.type == PendingActionType.removeBlocklistDomain,
        )
        .where((action) => action.state == PendingActionState.pending)
        .toList();
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  Future<bool> requestRemoval(String pin, String domain) async {
    try {
      await _requestSensitiveActionUseCase(
        pin: pin,
        type: PendingActionType.removeBlocklistDomain,
        payload: {'domain': domain},
      );
      _errorMessage = null;
      await _refreshPendingRemovals();
      notifyListeners();
      return true;
    } on PinRejectedException {
      _errorMessage = (await loadCurrentLocalizations()).pinIncorrectError;
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelRemoval(String id) async {
    await _cancelPendingActionUseCase(id);
    await _refreshPendingRemovals();
    notifyListeners();
  }
}
