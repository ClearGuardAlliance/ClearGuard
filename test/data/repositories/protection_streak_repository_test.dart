import 'package:clearguard/data/repositories/protection_streak_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProtectionStreakRepository', () {
    test('first active day starts a streak of 1', () async {
      final repository = ProtectionStreakRepository();

      final streak = await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );

      expect(streak.current, 1);
      expect(streak.longest, 1);
    });

    test('consecutive active days extend the streak', () async {
      final repository = ProtectionStreakRepository();

      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );
      final streak = await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026, 1, 2),
      );

      expect(streak.current, 2);
      expect(streak.longest, 2);
    });

    test('recording the same day twice does not double-count', () async {
      final repository = ProtectionStreakRepository();

      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );
      final streak = await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );

      expect(streak.current, 1);
    });

    test('a day with protection off resets the streak', () async {
      final repository = ProtectionStreakRepository();

      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );
      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026, 1, 2),
      );
      final streak = await repository.recordDay(
        isProtectionActive: false,
        now: DateTime(2026, 1, 3),
      );

      expect(streak.current, 0);
    });

    test('a skipped day breaks the streak even if active again', () async {
      final repository = ProtectionStreakRepository();

      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );
      final streak = await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026, 1, 3),
      );

      expect(streak.current, 1);
    });

    test('longest streak persists after the current streak resets', () async {
      final repository = ProtectionStreakRepository();

      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );
      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026, 1, 2),
      );
      final streak = await repository.recordDay(
        isProtectionActive: false,
        now: DateTime(2026, 1, 3),
      );

      expect(streak.current, 0);
      expect(streak.longest, 2);
    });

    test('activeDays records only days protection was active', () async {
      final repository = ProtectionStreakRepository();

      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026),
      );
      await repository.recordDay(
        isProtectionActive: false,
        now: DateTime(2026, 1, 2),
      );
      await repository.recordDay(
        isProtectionActive: true,
        now: DateTime(2026, 1, 3),
      );

      final activeDays = await repository.activeDays();

      expect(activeDays, {DateTime(2026), DateTime(2026, 1, 3)});
    });
  });
}
