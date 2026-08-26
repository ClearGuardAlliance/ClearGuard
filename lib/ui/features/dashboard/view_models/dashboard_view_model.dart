import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/accountability_repository.dart';
import '../../../../data/repositories/protection_repository.dart';
import '../../../../domain/models/pending_action.dart';
import '../../../../domain/models/protection_status.dart';
import '../../../../domain/use_cases/apply_ready_pending_actions_use_case.dart';
import '../../../../domain/use_cases/cancel_pending_action_use_case.dart';
import '../../../../domain/use_cases/enable_protection_use_case.dart';
import '../../../../domain/use_cases/request_sensitive_action_use_case.dart';
import '../../../../domain/use_cases/update_blocklist_use_case.dart';

/// Backs the main screen: current protection status, any pending
/// weakening request with its live countdown, and the actions the user can
/// take. A periodic tick both refreshes the countdown display and drains
/// any pending action whose delay has just elapsed, so a disable request
/// takes effect on schedule even if the user is just staring at the
/// dashboard when it happens.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required ProtectionRepository protectionRepository,
    required AccountabilityRepository accountabilityRepository,
    required EnableProtectionUseCase enableProtectionUseCase,
    required RequestSensitiveActionUseCase requestSensitiveActionUseCase,
    required ApplyReadyPendingActionsUseCase applyReadyPendingActionsUseCase,
    required CancelPendingActionUseCase cancelPendingActionUseCase,
    required UpdateBlocklistUseCase updateBlocklistUseCase,
  })  : _protectionRepository = protectionRepository,
        _accountabilityRepository = accountabilityRepository,
        _enableProtectionUseCase = enableProtectionUseCase,
        _requestSensitiveActionUseCase = requestSensitiveActionUseCase,
        _applyReadyPendingActionsUseCase = applyReadyPendingActionsUseCase,
        _cancelPendingActionUseCase = cancelPendingActionUseCase,
        _updateBlocklistUseCase = updateBlocklistUseCase;

  final ProtectionRepository _protectionRepository;
  final AccountabilityRepository _accountabilityRepository;
  final EnableProtectionUseCase _enableProtectionUseCase;
  final RequestSensitiveActionUseCase _requestSensitiveActionUseCase;
  final ApplyReadyPendingActionsUseCase _applyReadyPendingActionsUseCase;
  final CancelPendingActionUseCase _cancelPendingActionUseCase;
  final UpdateBlocklistUseCase _updateBlocklistUseCase;

  StreamSubscription<ProtectionStatus>? _statusSubscription;
  Timer? _ticker;

  ProtectionStatus _status = ProtectionStatus.starting;
  ProtectionStatus get status => _status;

  List<PendingAction> _pendingActions = const [];
  List<PendingAction> get pendingActions => _pendingActions;

  int? _blockedDomainCount;
  int? get blockedDomainCount => _blockedDomainCount;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await _protectionRepository.initialize();
    _statusSubscription = _protectionRepository.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
    await _tick();

    try {
      _blockedDomainCount = await _updateBlocklistUseCase();
    } catch (_) {
      // Keep whatever count we already had; the VPN keeps running on the
      // last successfully synced list.
    }
    notifyListeners();
  }

  Future<void> _tick() async {
    // Best-effort retry of any accountability notification that couldn't
    // be delivered earlier (e.g. the device was offline at the time).
    unawaited(_accountabilityRepository.flushPendingNotifications());

    final justApplied = await _applyReadyPendingActionsUseCase();
    _pendingActions = await _accountabilityRepository.loadPendingActions();
    if (justApplied.isNotEmpty) {
      // Status stream will also reflect this, but refresh eagerly so the
      // UI doesn't wait for the next native event.
      _status = await _protectionRepository.refreshStatus();
    }
    notifyListeners();
  }

  Future<void> reEnableProtection() async {
    await _enableProtectionUseCase();
  }

  Future<bool> requestDisableProtection(String pin) async {
    try {
      final action = await _requestSensitiveActionUseCase(
        pin: pin,
        type: PendingActionType.disableProtection,
      );
      _pendingActions = [..._pendingActions, action];
      _errorMessage = null;
      notifyListeners();
      return true;
    } on PinRejectedException {
      _errorMessage = 'PIN incorreto.';
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelPendingAction(String id) async {
    await _cancelPendingActionUseCase(id);
    _pendingActions = await _accountabilityRepository.loadPendingActions();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
