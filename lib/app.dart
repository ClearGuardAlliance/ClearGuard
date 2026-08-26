import 'package:flutter/material.dart';

import 'data/repositories/accountability_repository.dart';
import 'data/repositories/blocklist_repository.dart';
import 'data/repositories/protection_repository.dart';
import 'data/services/blocklist_source_service.dart';
import 'data/services/notification_outbox.dart';
import 'data/services/pending_action_store.dart';
import 'data/services/screen_monitor_platform_service.dart';
import 'data/services/secure_credentials_service.dart';
import 'data/services/vpn_platform_service.dart';
import 'data/services/webhook_notifier_service.dart';
import 'domain/use_cases/apply_ready_pending_actions_use_case.dart';
import 'domain/use_cases/cancel_pending_action_use_case.dart';
import 'domain/use_cases/enable_protection_use_case.dart';
import 'domain/use_cases/request_sensitive_action_use_case.dart';
import 'domain/use_cases/update_blocklist_use_case.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'ui/features/dashboard/views/dashboard_view.dart';
import 'ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'ui/features/onboarding/views/onboarding_view.dart';

/// Composition root. The dependency graph is small enough (a handful of
/// services/repositories/use cases) that a manual wiring here is clearer
/// than pulling in a DI container — see
/// flutter-apply-architecture-best-practices for when that trade-off
/// should flip.
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
  late final _notificationOutbox = NotificationOutbox(webhookService: _webhookService);
  late final _blocklistSourceService = BlocklistSourceService();
  late final _pendingActionStore = PendingActionStore();

  late final _protectionRepository = ProtectionRepository(
    vpnService: _vpnService,
    screenMonitorService: _screenMonitorService,
  );
  late final _accountabilityRepository = AccountabilityRepository(
    credentialsService: _credentialsService,
    notificationOutbox: _notificationOutbox,
    pendingActionStore: _pendingActionStore,
  );
  late final _blocklistRepository = BlocklistRepository(sourceService: _blocklistSourceService);

  late final _enableProtectionUseCase = EnableProtectionUseCase(
    protectionRepository: _protectionRepository,
    blocklistRepository: _blocklistRepository,
  );
  late final _requestSensitiveActionUseCase =
      RequestSensitiveActionUseCase(repository: _accountabilityRepository);
  late final _applyReadyPendingActionsUseCase = ApplyReadyPendingActionsUseCase(
    accountabilityRepository: _accountabilityRepository,
    protectionRepository: _protectionRepository,
    blocklistRepository: _blocklistRepository,
  );
  late final _cancelPendingActionUseCase =
      CancelPendingActionUseCase(repository: _accountabilityRepository);
  late final _updateBlocklistUseCase = UpdateBlocklistUseCase(
    protectionRepository: _protectionRepository,
    blocklistRepository: _blocklistRepository,
  );

  bool? _isConfigured;

  @override
  void initState() {
    super.initState();
    _accountabilityRepository.isConfigured().then((configured) {
      if (!mounted) return;
      setState(() => _isConfigured = configured);
    });
  }

  @override
  void dispose() {
    _protectionRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearGuard',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: switch (_isConfigured) {
        null => const Scaffold(body: Center(child: CircularProgressIndicator())),
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
            ),
          ),
      },
    );
  }
}
