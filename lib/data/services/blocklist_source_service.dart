import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

Set<String> parseDomainList(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim().toLowerCase())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

class BlocklistSourceService {
  BlocklistSourceService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<Set<String>> loadBundled() async {
    final raw = await rootBundle.loadString('assets/blocklist/domains.txt');
    return compute(parseDomainList, raw);
  }

  Future<Set<String>> fetchRemote(String url) async {
    if (url.isEmpty) return {};

    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch remote blocklist. Status: ${response.statusCode}',
      );
    }

    return compute(parseDomainList, response.body);
  }
}
