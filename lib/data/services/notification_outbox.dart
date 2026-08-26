import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'webhook_notifier_service.dart';

/// Every accountability notification goes through here instead of calling
/// [WebhookNotifierService] directly, so that having no network never
/// breaks a local state change (saving a PIN, creating a pending action,
/// cancelling one). [enqueue] persists the message and returns
/// immediately; delivery is attempted right away as a best effort, and
/// [flush] retries whatever is still queued. The accountability model only
/// works if the partner actually gets notified, so a failed send is kept
/// and retried, not dropped.
class NotificationOutbox {
  NotificationOutbox({required WebhookNotifierService webhookService})
      : _webhookService = webhookService;

  final WebhookNotifierService _webhookService;

  static const _key = 'notification_outbox_v1';
  static const _maxQueued = 30;

  Future<void> enqueue({required String webhookUrl, required String message}) async {
    final queued = await _load();
    queued.add({'webhookUrl': webhookUrl, 'message': message});
    // Drop the oldest first if the queue grows unbounded (e.g. the webhook
    // URL is permanently broken) — a backlog of stale "this happened 3 days
    // ago" notifications stops being useful past a point.
    while (queued.length > _maxQueued) {
      queued.removeAt(0);
    }
    await _save(queued);

    await flush();
  }

  /// Attempts to deliver everything queued. Safe to call opportunistically
  /// (e.g. on a timer or app resume) — entries that still fail stay queued
  /// for the next attempt, entries that succeed are removed.
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
    } catch (_) {
      // No network, DNS failure, webhook host down, etc. — leave it queued.
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
