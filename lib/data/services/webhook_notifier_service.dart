import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Sends accountability notifications to the partner's webhook (Discord,
/// Slack, or a generic endpoint that accepts `{"content": "..."}` or
/// `{"text": "..."}`). This is the visibility half of the accountability
/// model: a request to weaken protection is announced the moment it is
/// made, not after the fact, so the partner has the full delay window to
/// react — see RequestSensitiveActionUseCase.
class WebhookNotifierService {
  WebhookNotifierService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> send({required String webhookUrl, required String message}) async {
    if (webhookUrl.isEmpty) return false;

    final response = await _client.post(
      Uri.parse(webhookUrl),
      headers: {HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8'},
      body: jsonEncode({'content': message, 'text': message}),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
