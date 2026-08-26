import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// Top-level so it can run in a background isolate via [compute] — parsing
/// a multi-thousand-line hosts file on the UI isolate would jank the
/// dashboard on every sync.
Set<String> parseDomainList(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim().toLowerCase())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

/// Provides the raw domain sets that feed BlocklistRepository: the bundled
/// seed list shipped in the app, and an optional remote list the user (or,
/// ideally, the accountability partner) points at a maintained source.
class BlocklistSourceService {
  BlocklistSourceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Set<String>> loadBundled() async {
    final raw = await rootBundle.loadString('assets/blocklist/domains.txt');
    return compute(parseDomainList, raw);
  }

  Future<Set<String>> fetchRemote(String url) async {
    if (url.isEmpty) return {};

    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch remote blocklist. Status: ${response.statusCode}');
    }

    return compute(parseDomainList, response.body);
  }
}
