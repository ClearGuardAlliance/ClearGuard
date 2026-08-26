import 'package:clearguard/data/services/notification_outbox.dart';
import 'package:clearguard/data/services/pending_action_store.dart';
import 'package:clearguard/data/services/secure_credentials_service.dart';
import 'package:clearguard/domain/models/accountability_config.dart';
import 'package:clearguard/domain/models/pending_action.dart';
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

    await _notificationOutbox.enqueue(
      webhookUrl: webhookUrl,
      message: 'ClearGuard configurado. $partnerLabel agora recebe um aviso '
          'sempre que uma mudança de proteção for solicitada neste '
          'dispositivo, com ${delay.inMinutes} min de antecedência antes de '
          'ela valer.',
    );
  }

  Future<AccountabilityConfig?> loadConfig() async {
    if (!await isConfigured()) return null;
    final prefs = await SharedPreferences.getInstance();
    return AccountabilityConfig(
      pinHash: '',
      webhookUrl: prefs.getString(_webhookUrlKey) ?? '',
      partnerLabel: prefs.getString(_partnerLabelKey) ?? 'seu parceiro',
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
      await _notificationOutbox.enqueue(
        webhookUrl: config.webhookUrl,
        message: _describeRequested(action, delay),
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
      await _notificationOutbox.enqueue(
        webhookUrl: config.webhookUrl,
        message: 'Pedido de "${_describeType(cancelled.type)}" foi cancelado '
            'antes de entrar em vigor.',
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
      await _notificationOutbox.enqueue(
        webhookUrl: config.webhookUrl,
        message: '"${_describeType(action.type)}" agora está em vigor neste '
            'dispositivo.',
      );
    }
  }

  Future<void> flushPendingNotifications() => _notificationOutbox.flush();

  String _describeRequested(PendingAction action, Duration delay) {
    final readyAtLabel = _formatTime(action.readyAt);
    return 'Pedido: "${_describeType(action.type)}" neste dispositivo. '
        'Passa a valer às $readyAtLabel (em ${delay.inMinutes} min) se '
        'ninguém cancelar.';
  }

  String _describeType(PendingActionType type) {
    switch (type) {
      case PendingActionType.disableProtection:
        return 'desativar a proteção';
      case PendingActionType.removeBlocklistDomain:
        return 'remover domínio da lista de bloqueio';
      case PendingActionType.changeWebhookUrl:
        return 'trocar o webhook de notificação';
      case PendingActionType.increaseSensitiveActionDelay:
        return 'aumentar o tempo de espera de mudanças';
      case PendingActionType.decreaseSensitiveActionDelay:
        return 'diminuir o tempo de espera de mudanças';
      case PendingActionType.deactivateDeviceAdmin:
        return 'desativar o administrador do dispositivo (permite desinstalar)';
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
