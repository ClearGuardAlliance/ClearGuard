import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
