import 'package:clearguard/domain/models/block_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockWindowRepository {
  static const _enabledKey = 'block_window_enabled';
  static const _startKey = 'block_window_start_minutes';
  static const _endKey = 'block_window_end_minutes';

  Future<BlockWindow> current() async {
    final prefs = await SharedPreferences.getInstance();
    return BlockWindow(
      enabled: prefs.getBool(_enabledKey) ?? BlockWindow.defaultWindow.enabled,
      startMinutes:
          prefs.getInt(_startKey) ?? BlockWindow.defaultWindow.startMinutes,
      endMinutes:
          prefs.getInt(_endKey) ?? BlockWindow.defaultWindow.endMinutes,
    );
  }

  Future<void> save(BlockWindow window) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, window.enabled);
    await prefs.setInt(_startKey, window.startMinutes);
    await prefs.setInt(_endKey, window.endMinutes);
  }
}
