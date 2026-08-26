import 'dart:convert';

import 'package:clearguard/data/services/webhook_notifier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationOutbox {
  NotificationOutbox({required WebhookNotifierService webhookService})
      : _webhookService = webhookService;

  final WebhookNotifierService _webhookService;

  static const _key = 'notification_outbox_v1';
  static const _maxQueued = 30;

  Future<void> enqueue({
    required String webhookUrl,
    required String message,
  }) async {
    final queued = await _load();
    queued.add({'webhookUrl': webhookUrl, 'message': message});
    while (queued.length > _maxQueued) {
      queued.removeAt(0);
    }
    await _save(queued);

    await flush();
  }

  Future<void> flush() async {
    final queued = await _load();
    if (queued.isEmpty) return;

    final stillPending = <Map<String, String>>[];
    for (final entry in queued) {
      final delivered = await _tryDeliver(entry);
      if (!delivered) stillPending.add(entry);
    }

    await _save(stillPending);
  }

  Future<bool> _tryDeliver(Map<String, String> entry) async {
    try {
      return await _webhookService.send(
        webhookUrl: entry['webhookUrl'] ?? '',
        message: entry['message'] ?? '',
      );
    } on Exception {
      return false;
    }
  }

  Future<List<Map<String, String>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((entry) => Map<String, String>.from(jsonDecode(entry) as Map))
        .toList();
  }

  Future<void> _save(List<Map<String, String>> queued) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, queued.map(jsonEncode).toList());
  }
}
