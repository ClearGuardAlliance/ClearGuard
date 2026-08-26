import 'package:shared_preferences/shared_preferences.dart';

import '../services/blocklist_source_service.dart';

class BlocklistRepository {
  BlocklistRepository({required BlocklistSourceService sourceService})
      : _sourceService = sourceService;

  final BlocklistSourceService _sourceService;

  static const _remoteUrlKey = 'blocklist_remote_url';
  static const _approvedRemovalsKey = 'blocklist_approved_removals';

  Future<String> remoteListUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_remoteUrlKey) ?? '';
  }

  Future<void> setRemoteListUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remoteUrlKey, url);
  }

  Future<Set<String>> _approvedRemovals() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_approvedRemovalsKey) ?? const []).toSet();
  }

  Future<void> approveRemoval(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    final removals = await _approvedRemovals();
    removals.add(domain.toLowerCase());
    await prefs.setStringList(_approvedRemovalsKey, removals.toList());
  }

  Future<List<String>> effectiveBlockedDomains() async {
    final bundled = await _sourceService.loadBundled();
    final url = await remoteListUrl();

    var remote = <String>{};
    if (url.isNotEmpty) {
      try {
        remote = await _sourceService.fetchRemote(url);
      } catch (_) {
        remote = {};
      }
    }

    final removals = await _approvedRemovals();
    final effective = {...bundled, ...remote}..removeAll(removals);
    return effective.toList()..sort();
  }
}
