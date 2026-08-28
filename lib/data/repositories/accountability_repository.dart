import 'package:clearguard/data/services/notification_outbox.dart';
import 'package:clearguard/data/services/pending_action_store.dart';
import 'package:clearguard/data/services/secure_credentials_service.dart';
import 'package:clearguard/domain/models/accountability_config.dart';
import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/l10n/l10n_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AccountabilityRepository {
  AccountabilityRepository({
    required SecureCredentialsService credentialsService,
    required NotificationOutbox notificationOutbox,
    required PendingActionStore pendingActionStore,
    Uuid? uuid,
  })  : _credentialsService = credentialsService,
        _notificationOutbox = notificationOutbox,
        _pendingActionStore = pendingActionStore,
        _uuid = uuid ?? const Uuid();

  final SecureCredentialsService _credentialsService;
  final NotificationOutbox _notificationOutbox;
  final PendingActionStore _pendingActionStore;
  final Uuid _uuid;

  static const _webhookUrlKey = 'accountability_webhook_url';
  static const _partnerLabelKey = 'accountability_partner_label';
  static const _delayMinutesKey = 'accountability_delay_minutes';

  Future<bool> isConfigured() => _credentialsService.hasPin();

  Future<void> setUpAccountability({
    required String pin,
    required String webhookUrl,
    required String partnerLabel,
    Duration delay = AccountabilityConfig.defaultDelay,
  }) async {
    await _credentialsService.setPin(pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webhookUrlKey, webhookUrl);
    await prefs.setString(_partnerLabelKey, partnerLabel);
    await prefs.setInt(_delayMinutesKey, delay.inMinutes);

    final l10n = await loadCurrentLocalizations();
    await _notificationOutbox.enqueue(
      webhookUrl: webhookUrl,
      message: l10n.webhookConfiguredMessage(partnerLabel, delay.inMinutes),
    );
  }

  Future<AccountabilityConfig?> loadConfig() async {
    if (!await isConfigured()) return null;
    final prefs = await SharedPreferences.getInstance();
    final l10n = await loadCurrentLocalizations();
    return AccountabilityConfig(
      pinHash: '',
      webhookUrl: prefs.getString(_webhookUrlKey) ?? '',
      partnerLabel:
          prefs.getString(_partnerLabelKey) ?? l10n.defaultPartnerLabel,
      sensitiveActionDelay: Duration(
        minutes: prefs.getInt(_delayMinutesKey) ??
            AccountabilityConfig.defaultDelay.inMinutes,
      ),
    );
  }

  Future<bool> verifyPin(String pin) => _credentialsService.verifyPin(pin);

  Future<List<PendingAction>> loadPendingActions() =>
      _pendingActionStore.loadAll();

  Future<PendingAction> createPendingAction({
    required PendingActionType type,
    Map<String, String> payload = const {},
  }) async {
    final config = await loadConfig();
    final delay =
        config?.sensitiveActionDelay ?? AccountabilityConfig.defaultDelay;
    final now = DateTime.now();

    final action = PendingAction(
      id: _uuid.v4(),
      type: type,
      requestedAt: now,
      readyAt: now.add(delay),
      state: PendingActionState.pending,
      payload: payload,
    );

    final actions = await _pendingActionStore.loadAll();
    await _pendingActionStore.saveAll([...actions, action]);

    if (config != null) {
      final l10n = await loadCurrentLocalizations();
      await _notificationOutbox.enqueue(
        webhookUrl: config.webhookUrl,
        message: _describeRequested(l10n, action, delay),
      );
    }

    return action;
  }

  Future<void> cancelPendingAction(String id) async {
    final actions = await _pendingActionStore.loadAll();
    final updated = actions.where((action) => action.id != id).toList();
    await _pendingActionStore.saveAll(updated);

    final config = await loadConfig();
    final cancelled = actions.where((action) => action.id == id).firstOrNull;
    if (config != null && cancelled != null) {
      final l10n = await loadCurrentLocalizations();
      await _notificationOutbox.enqueue(
        webhookUrl: config.webhookUrl,
        message: l10n.webhookCancelledMessage(
          _describeType(l10n, cancelled.type),
        ),
      );
    }
  }

  Future<void> applyWebhookUrlChange(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webhookUrlKey, newUrl);
  }

  Future<void> applyDelayChange(Duration newDelay) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_delayMinutesKey, newDelay.inMinutes);
  }

  Future<void> markApplied(PendingAction action) async {
    final actions = await _pendingActionStore.loadAll();
    final updated = [
      for (final existing in actions)
        if (existing.id == action.id)
          existing.copyWith(state: PendingActionState.applied)
        else
          existing,
    ];
    await _pendingActionStore.saveAll(updated);

    final config = await loadConfig();
    if (config != null) {
      final l10n = await loadCurrentLocalizations();
      await _notificationOutbox.enqueue(
        webhookUrl: config.webhookUrl,
        message: l10n.webhookAppliedMessage(_describeType(l10n, action.type)),
      );
    }
  }

  Future<void> flushPendingNotifications() => _notificationOutbox.flush();

  String _describeRequested(
    AppLocalizations l10n,
    PendingAction action,
    Duration delay,
  ) {
    final readyAtLabel = _formatTime(action.readyAt);
    return l10n.webhookRequestedMessage(
      _describeType(l10n, action.type),
      readyAtLabel,
      delay.inMinutes,
    );
  }

  String _describeType(AppLocalizations l10n, PendingActionType type) {
    switch (type) {
      case PendingActionType.disableProtection:
        return l10n.actionDisableProtection;
      case PendingActionType.removeBlocklistDomain:
        return l10n.actionRemoveBlocklistDomain;
      case PendingActionType.changeWebhookUrl:
        return l10n.actionChangeWebhookUrl;
      case PendingActionType.changeRemoteBlocklistUrl:
        return l10n.actionChangeRemoteBlocklistUrl;
      case PendingActionType.increaseSensitiveActionDelay:
        return l10n.actionIncreaseDelay;
      case PendingActionType.decreaseSensitiveActionDelay:
        return l10n.actionDecreaseDelay;
      case PendingActionType.deactivateDeviceAdmin:
        return l10n.actionDeactivateDeviceAdmin;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
