import 'package:clearguard/data/repositories/accountability_repository.dart';
import 'package:clearguard/data/repositories/block_window_repository.dart';
import 'package:clearguard/data/repositories/blocklist_repository.dart';
import 'package:clearguard/data/repositories/protection_repository.dart';
import 'package:clearguard/data/services/device_admin_platform_service.dart';
import 'package:clearguard/domain/models/accountability_config.dart';
import 'package:clearguard/domain/models/block_window.dart';
import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/domain/use_cases/cancel_pending_action_use_case.dart';
import 'package:clearguard/domain/use_cases/request_sensitive_action_use_case.dart';
import 'package:clearguard/domain/use_cases/sync_trigger_guard_use_case.dart';
import 'package:clearguard/l10n/l10n_util.dart';
import 'package:flutter/foundation.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required AccountabilityRepository accountabilityRepository,
    required BlocklistRepository blocklistRepository,
    required ProtectionRepository protectionRepository,
    required DeviceAdminPlatformService deviceAdminService,
    required RequestSensitiveActionUseCase requestSensitiveActionUseCase,
    required CancelPendingActionUseCase cancelPendingActionUseCase,
    required BlockWindowRepository blockWindowRepository,
    required SyncTriggerGuardUseCase syncTriggerGuardUseCase,
  })  : _accountabilityRepository = accountabilityRepository,
        _blocklistRepository = blocklistRepository,
        _protectionRepository = protectionRepository,
        _deviceAdminService = deviceAdminService,
        _requestSensitiveActionUseCase = requestSensitiveActionUseCase,
        _cancelPendingActionUseCase = cancelPendingActionUseCase,
        _blockWindowRepository = blockWindowRepository,
        _syncTriggerGuardUseCase = syncTriggerGuardUseCase;

  final AccountabilityRepository _accountabilityRepository;
  final BlocklistRepository _blocklistRepository;
  final ProtectionRepository _protectionRepository;
  final DeviceAdminPlatformService _deviceAdminService;
  final RequestSensitiveActionUseCase _requestSensitiveActionUseCase;
  final CancelPendingActionUseCase _cancelPendingActionUseCase;
  final BlockWindowRepository _blockWindowRepository;
  final SyncTriggerGuardUseCase _syncTriggerGuardUseCase;

  AccountabilityConfig? _config;
  AccountabilityConfig? get config => _config;

  String _remoteBlocklistUrl = '';
  String get remoteBlocklistUrl => _remoteBlocklistUrl;

  bool _isDeviceAdminActive = false;
  bool get isDeviceAdminActive => _isDeviceAdminActive;

  bool _isIgnoringBatteryOptimizations = false;
  bool get isIgnoringBatteryOptimizations => _isIgnoringBatteryOptimizations;

  List<PendingAction> _pendingActions = const [];
  List<PendingAction> get pendingActions => _pendingActions;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BlockWindow _blockWindow = BlockWindow.defaultWindow;
  BlockWindow get blockWindow => _blockWindow;

  Future<void> initialize() async {
    _config = await _accountabilityRepository.loadConfig();
    _remoteBlocklistUrl = await _blocklistRepository.remoteListUrl();
    try {
      _isDeviceAdminActive = await _deviceAdminService.isActive();
    } on Exception {
      _isDeviceAdminActive = false;
    }
    try {
      _isIgnoringBatteryOptimizations =
          await _protectionRepository.isIgnoringBatteryOptimizations();
    } on Exception {
      _isIgnoringBatteryOptimizations = false;
    }
    _blockWindow = await _blockWindowRepository.current();
    await _refreshPendingActions();
    notifyListeners();
  }

  Future<void> setBlockWindow(BlockWindow window) async {
    await _blockWindowRepository.save(window);
    _blockWindow = window;
    await _syncTriggerGuardUseCase().catchError((_) {});
    notifyListeners();
  }

  Future<void> _refreshPendingActions() async {
    final all = await _accountabilityRepository.loadPendingActions();
    _pendingActions = all
        .where((action) => action.state == PendingActionState.pending)
        .where(
          (action) => const {
            PendingActionType.changeWebhookUrl,
            PendingActionType.changeRemoteBlocklistUrl,
            PendingActionType.increaseSensitiveActionDelay,
            PendingActionType.decreaseSensitiveActionDelay,
          }.contains(action.type),
        )
        .toList();
  }

  Future<bool> requestWebhookChange(String pin, String newUrl) {
    return _request(
      pin: pin,
      type: PendingActionType.changeWebhookUrl,
      payload: {'newUrl': newUrl},
    );
  }

  Future<bool> requestRemoteBlocklistUrlChange(String pin, String newUrl) {
    return _request(
      pin: pin,
      type: PendingActionType.changeRemoteBlocklistUrl,
      payload: {'newUrl': newUrl},
    );
  }

  Future<bool> requestDelayChange(String pin, int newMinutes) {
    final currentMinutes = _config?.sensitiveActionDelay.inMinutes ?? 0;
    final type = newMinutes >= currentMinutes
        ? PendingActionType.increaseSensitiveActionDelay
        : PendingActionType.decreaseSensitiveActionDelay;
    return _request(
      pin: pin,
      type: type,
      payload: {'newDelayMinutes': newMinutes.toString()},
    );
  }

  Future<bool> _request({
    required String pin,
    required PendingActionType type,
    required Map<String, String> payload,
  }) async {
    try {
      await _requestSensitiveActionUseCase(
        pin: pin,
        type: type,
        payload: payload,
      );
      _errorMessage = null;
      await _refreshPendingActions();
      notifyListeners();
      return true;
    } on PinRejectedException {
      _errorMessage = (await loadCurrentLocalizations()).pinIncorrectError;
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelPendingAction(String id) async {
    await _cancelPendingActionUseCase(id);
    await _refreshPendingActions();
    notifyListeners();
  }

  Future<bool> activateDeviceAdmin() async {
    final granted = await _deviceAdminService.requestActivation();
    _isDeviceAdminActive = granted;
    notifyListeners();
    return granted;
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    _isIgnoringBatteryOptimizations =
        await _protectionRepository.requestIgnoreBatteryOptimizations();
    notifyListeners();
  }
}
