import 'dart:async';

import 'package:clearguard/data/repositories/accountability_repository.dart';
import 'package:clearguard/data/repositories/protection_repository.dart';
import 'package:clearguard/data/repositories/protection_streak_repository.dart';
import 'package:clearguard/data/services/local_notification_service.dart';
import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/domain/models/protection_status.dart';
import 'package:clearguard/domain/models/protection_streak.dart';
import 'package:clearguard/domain/models/wellbeing_tip.dart';
import 'package:clearguard/domain/use_cases/apply_ready_pending_actions_use_case.dart';
import 'package:clearguard/domain/use_cases/cancel_pending_action_use_case.dart';
import 'package:clearguard/domain/use_cases/enable_protection_use_case.dart';
import 'package:clearguard/domain/use_cases/request_sensitive_action_use_case.dart';
import 'package:clearguard/domain/use_cases/sync_trigger_guard_use_case.dart';
import 'package:clearguard/domain/use_cases/update_blocklist_use_case.dart';
import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required ProtectionRepository protectionRepository,
    required AccountabilityRepository accountabilityRepository,
    required EnableProtectionUseCase enableProtectionUseCase,
    required RequestSensitiveActionUseCase requestSensitiveActionUseCase,
    required ApplyReadyPendingActionsUseCase applyReadyPendingActionsUseCase,
    required CancelPendingActionUseCase cancelPendingActionUseCase,
    required UpdateBlocklistUseCase updateBlocklistUseCase,
    required ProtectionStreakRepository protectionStreakRepository,
    required LocalNotificationService notificationService,
    required SyncTriggerGuardUseCase syncTriggerGuardUseCase,
  })  : _protectionRepository = protectionRepository,
        _accountabilityRepository = accountabilityRepository,
        _enableProtectionUseCase = enableProtectionUseCase,
        _requestSensitiveActionUseCase = requestSensitiveActionUseCase,
        _applyReadyPendingActionsUseCase = applyReadyPendingActionsUseCase,
        _cancelPendingActionUseCase = cancelPendingActionUseCase,
        _updateBlocklistUseCase = updateBlocklistUseCase,
        _protectionStreakRepository = protectionStreakRepository,
        _notificationService = notificationService,
        _syncTriggerGuardUseCase = syncTriggerGuardUseCase;

  final ProtectionRepository _protectionRepository;
  final AccountabilityRepository _accountabilityRepository;
  final EnableProtectionUseCase _enableProtectionUseCase;
  final RequestSensitiveActionUseCase _requestSensitiveActionUseCase;
  final ApplyReadyPendingActionsUseCase _applyReadyPendingActionsUseCase;
  final CancelPendingActionUseCase _cancelPendingActionUseCase;
  final UpdateBlocklistUseCase _updateBlocklistUseCase;
  final ProtectionStreakRepository _protectionStreakRepository;
  final LocalNotificationService _notificationService;
  final SyncTriggerGuardUseCase _syncTriggerGuardUseCase;

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

  ProtectionStreak? _streak;
  ProtectionStreak? get streak => _streak;

  Future<void> initialize() async {
    try {
      await _protectionRepository.initialize();
    } on Exception {
      _status = ProtectionStatus.error;
    }
    _statusSubscription = _protectionRepository.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
    await _tick();

    try {
      _blockedDomainCount = await _updateBlocklistUseCase();
    } on Exception {
      // Keep showing the dashboard even if the blocklist sync fails.
    }

    _streak = await _protectionStreakRepository.recordDay(
      isProtectionActive: _status == ProtectionStatus.active,
    );
    unawaited(_refreshDailyReminder());
    unawaited(_syncTriggerGuardUseCase().catchError((_) {}));
    notifyListeners();
  }

  Future<void> _refreshDailyReminder() async {
    final streak = _streak;
    if (streak == null) return;

    final tip = WellbeingTip.forDay(DateTime.now());
    final title = streak.current > 0
        ? '🔥 ${streak.current} dia(s) seguido(s) protegido'
        : 'Hora de retomar sua proteção';

    try {
      await _notificationService.requestPermission();
      await _notificationService.scheduleDailyReminder(
        title: title,
        body: tip.title,
      );
    } on Exception {
      return;
    }
  }

  Future<void> _tick() async {
    unawaited(_accountabilityRepository.flushPendingNotifications());

    await _applyReadyPendingActionsUseCase();
    _pendingActions = await _accountabilityRepository.loadPendingActions();
    try {
      _status = await _protectionRepository.refreshStatus();
    } on Exception {
      // Keep the last known status if the platform check fails; the next
      // tick will retry instead of leaving the UI stuck.
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
    unawaited(_statusSubscription?.cancel());
    _ticker?.cancel();
    super.dispose();
  }
}
