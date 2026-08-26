import 'dart:async';

import '../../domain/models/protection_status.dart';
import '../services/screen_monitor_platform_service.dart';
import '../services/vpn_platform_service.dart';

/// Single source of truth for whether blocking is actually running on the
/// device. UI code should read status from here, never poll the platform
/// services directly, so the dashboard and the accountability flow always
/// agree on the current state.
class ProtectionRepository {
  ProtectionRepository({
    required VpnPlatformService vpnService,
    required ScreenMonitorPlatformService screenMonitorService,
  })  : _vpnService = vpnService,
        _screenMonitorService = screenMonitorService;

  final VpnPlatformService _vpnService;
  final ScreenMonitorPlatformService _screenMonitorService;

  final _statusController = StreamController<ProtectionStatus>.broadcast();
  StreamSubscription<ProtectionStatus>? _vpnStatusSubscription;

  Stream<ProtectionStatus> get statusStream => _statusController.stream;

  Future<void> initialize() async {
    _vpnStatusSubscription ??= _vpnService.statusStream().listen(_statusController.add);
    _statusController.add(await _vpnService.currentStatus());
  }

  Future<ProtectionStatus> refreshStatus() async {
    final status = await _vpnService.currentStatus();
    _statusController.add(status);
    return status;
  }

  Future<bool> requestVpnPermission() => _vpnService.requestPermission();

  Future<bool> isScreenMonitorPermissionGranted() =>
      _screenMonitorService.isAccessibilityPermissionGranted();

  Future<void> openScreenMonitorSettings() =>
      _screenMonitorService.openAccessibilitySettings();

  /// Turns blocking on. Never gated behind a delay — strengthening
  /// protection should always be instant and frictionless.
  Future<void> enable(List<String> blockedDomains) async {
    await _vpnService.start(blockedDomains);
    _statusController.add(await _vpnService.currentStatus());
  }

  /// Turns blocking off. Only ever called by
  /// ApplyReadyPendingActionsUseCase once a [PendingAction] for it has
  /// cleared its delay — never call this directly from the UI.
  Future<void> disable() async {
    await _vpnService.stop();
    _statusController.add(await _vpnService.currentStatus());
  }

  Future<void> syncBlocklist(List<String> blockedDomains) {
    return _vpnService.updateBlocklist(blockedDomains);
  }

  Future<void> syncScreenMonitorKeywords(List<String> keywords) {
    return _screenMonitorService.updateKeywords(keywords);
  }

  void dispose() {
    _vpnStatusSubscription?.cancel();
    _statusController.close();
  }
}
