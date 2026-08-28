import 'dart:async';

import 'package:clearguard/data/repositories/accountability_repository.dart';
import 'package:clearguard/data/repositories/blocklist_repository.dart';
import 'package:clearguard/data/repositories/protection_repository.dart';
import 'package:clearguard/data/repositories/protection_streak_repository.dart';
import 'package:clearguard/data/repositories/trigger_apps_repository.dart';
import 'package:clearguard/data/services/blocklist_source_service.dart';
import 'package:clearguard/data/services/device_admin_platform_service.dart';
import 'package:clearguard/data/services/installed_apps_platform_service.dart';
import 'package:clearguard/data/services/notification_outbox.dart';
import 'package:clearguard/data/services/pending_action_store.dart';
import 'package:clearguard/data/services/screen_monitor_platform_service.dart';
import 'package:clearguard/data/services/secure_credentials_service.dart';
import 'package:clearguard/data/services/vpn_platform_service.dart';
import 'package:clearguard/data/services/webhook_notifier_service.dart';
import 'package:clearguard/domain/use_cases/apply_ready_pending_actions_use_case.dart';
import 'package:clearguard/domain/use_cases/cancel_pending_action_use_case.dart';
import 'package:clearguard/domain/use_cases/detect_trigger_apps_use_case.dart';
import 'package:clearguard/domain/use_cases/enable_protection_use_case.dart';
import 'package:clearguard/domain/use_cases/request_sensitive_action_use_case.dart';
import 'package:clearguard/domain/use_cases/update_blocklist_use_case.dart';
import 'package:clearguard/ui/core/theme/app_theme.dart';
import 'package:clearguard/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:clearguard/ui/features/dashboard/views/dashboard_view.dart';
import 'package:clearguard/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:clearguard/ui/features/onboarding/views/onboarding_view.dart';
import 'package:clearguard/ui/features/settings/view_models/settings_view_model.dart';
import 'package:clearguard/ui/features/settings/views/settings_view.dart';
import 'package:clearguard/ui/features/trigger_apps/view_models/trigger_apps_view_model.dart';
import 'package:clearguard/ui/features/trigger_apps/views/trigger_apps_view.dart';
import 'package:flutter/material.dart';

class ClearGuardApp extends StatefulWidget {
  const ClearGuardApp({super.key});

  @override
  State<ClearGuardApp> createState() => _ClearGuardAppState();
}

class _ClearGuardAppState extends State<ClearGuardApp> {
  late final _credentialsService = SecureCredentialsService();
  late final _vpnService = VpnPlatformService();
  late final _screenMonitorService = ScreenMonitorPlatformService();
  late final _webhookService = WebhookNotifierService();
  late final _notificationOutbox = NotificationOutbox(
    webhookService: _webhookService,
  );
  late final _blocklistSourceService = BlocklistSourceService();
  late final _pendingActionStore = PendingActionStore();
  late final _deviceAdminService = DeviceAdminPlatformService();
  late final _installedAppsService = InstalledAppsPlatformService();

  late final _protectionRepository = ProtectionRepository(
    vpnService: _vpnService,
    screenMonitorService: _screenMonitorService,
  );
  late final _accountabilityRepository = AccountabilityRepository(
    credentialsService: _credentialsService,
    notificationOutbox: _notificationOutbox,
    pendingActionStore: _pendingActionStore,
  );
  late final _blocklistRepository = BlocklistRepository(
    sourceService: _blocklistSourceService,
  );
  late final _triggerAppsRepository = TriggerAppsRepository(
    installedAppsService: _installedAppsService,
  );
  late final _protectionStreakRepository = ProtectionStreakRepository();

  late final _enableProtectionUseCase = EnableProtectionUseCase(
    protectionRepository: _protectionRepository,
    blocklistRepository: _blocklistRepository,
  );
  late final _requestSensitiveActionUseCase = RequestSensitiveActionUseCase(
    repository: _accountabilityRepository,
  );
  late final _applyReadyPendingActionsUseCase = ApplyReadyPendingActionsUseCase(
    accountabilityRepository: _accountabilityRepository,
    protectionRepository: _protectionRepository,
    blocklistRepository: _blocklistRepository,
  );
  late final _cancelPendingActionUseCase = CancelPendingActionUseCase(
    repository: _accountabilityRepository,
  );
  late final _updateBlocklistUseCase = UpdateBlocklistUseCase(
    protectionRepository: _protectionRepository,
    blocklistRepository: _blocklistRepository,
  );
  late final _detectTriggerAppsUseCase = DetectTriggerAppsUseCase(
    repository: _triggerAppsRepository,
  );

  bool? _isConfigured;

  @override
  void initState() {
    super.initState();
    unawaited(
      _accountabilityRepository.isConfigured().then((configured) {
        if (!mounted) return;
        setState(() => _isConfigured = configured);
      }),
    );
  }

  @override
  void dispose() {
    _protectionRepository.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsView(
          viewModel: SettingsViewModel(
            accountabilityRepository: _accountabilityRepository,
            blocklistRepository: _blocklistRepository,
            protectionRepository: _protectionRepository,
            deviceAdminService: _deviceAdminService,
            requestSensitiveActionUseCase: _requestSensitiveActionUseCase,
            cancelPendingActionUseCase: _cancelPendingActionUseCase,
          ),
        ),
      ),
    );
  }

  void _openTriggerApps(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TriggerAppsView(
          viewModel: TriggerAppsViewModel(
            detectTriggerApps: _detectTriggerAppsUseCase,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearGuard',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: switch (_isConfigured) {
        null => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        false => OnboardingView(
            viewModel: OnboardingViewModel(
              accountabilityRepository: _accountabilityRepository,
              protectionRepository: _protectionRepository,
              enableProtectionUseCase: _enableProtectionUseCase,
            ),
            onFinished: () => setState(() => _isConfigured = true),
          ),
        true => DashboardView(
            viewModel: DashboardViewModel(
              protectionRepository: _protectionRepository,
              accountabilityRepository: _accountabilityRepository,
              enableProtectionUseCase: _enableProtectionUseCase,
              requestSensitiveActionUseCase: _requestSensitiveActionUseCase,
              applyReadyPendingActionsUseCase: _applyReadyPendingActionsUseCase,
              cancelPendingActionUseCase: _cancelPendingActionUseCase,
              updateBlocklistUseCase: _updateBlocklistUseCase,
              protectionStreakRepository: _protectionStreakRepository,
            ),
            onOpenSettings: () => _openSettings(context),
            onOpenTriggerApps: () => _openTriggerApps(context),
          ),
      },
    );
  }
}
