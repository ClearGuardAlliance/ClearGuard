import 'package:clearguard/domain/models/protection_streak.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProtectionStreakRepository {
  static const _currentKey = 'streak_current';
  static const _longestKey = 'streak_longest';
  static const _lastRecordedDateKey = 'streak_last_recorded_date';

  Future<ProtectionStreak> current() async {
    final prefs = await SharedPreferences.getInstance();
    return ProtectionStreak(
      current: prefs.getInt(_currentKey) ?? 0,
      longest: prefs.getInt(_longestKey) ?? 0,
    );
  }

  Future<ProtectionStreak> recordDay({
    required bool isProtectionActive,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(now ?? DateTime.now());

    final lastRecordedRaw = prefs.getString(_lastRecordedDateKey);
    final lastRecorded = lastRecordedRaw != null
        ? DateTime.tryParse(lastRecordedRaw)
        : null;

    var current = prefs.getInt(_currentKey) ?? 0;
    var longest = prefs.getInt(_longestKey) ?? 0;

    if (lastRecorded != null && _isSameDay(lastRecorded, today)) {
      return ProtectionStreak(current: current, longest: longest);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (!isProtectionActive) {
      current = 0;
    } else if (lastRecorded != null && _isSameDay(lastRecorded, yesterday)) {
      current += 1;
    } else {
      current = 1;
    }

    if (current > longest) longest = current;

    await prefs.setInt(_currentKey, current);
    await prefs.setInt(_longestKey, longest);
    await prefs.setString(_lastRecordedDateKey, today.toIso8601String());

    return ProtectionStreak(current: current, longest: longest);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
