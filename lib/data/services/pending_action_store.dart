import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/pending_action.dart';

class PendingActionStore {
  static const _key = 'pending_actions_v1';

  Future<List<PendingAction>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((entry) => PendingAction.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<PendingAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = actions.map((action) => jsonEncode(action.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }
}
