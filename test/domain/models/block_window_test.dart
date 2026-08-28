import 'package:clearguard/domain/models/block_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlockWindow.contains', () {
    test('is false when disabled regardless of time', () {
      const window = BlockWindow.defaultWindow;

      expect(window.contains(DateTime(2026, 1, 1, 23, 30)), isFalse);
    });

    test('handles a same-day window', () {
      const window = BlockWindow(
        enabled: true,
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
      );

      expect(window.contains(DateTime(2026, 1, 1, 10)), isTrue);
      expect(window.contains(DateTime(2026, 1, 1, 8)), isFalse);
      expect(window.contains(DateTime(2026, 1, 1, 18)), isFalse);
    });

    test('handles a window that wraps past midnight', () {
      const window = BlockWindow(
        enabled: true,
        startMinutes: 23 * 60,
        endMinutes: 6 * 60,
      );

      expect(window.contains(DateTime(2026, 1, 1, 23, 30)), isTrue);
      expect(window.contains(DateTime(2026, 1, 1, 2)), isTrue);
      expect(window.contains(DateTime(2026, 1, 1, 12)), isFalse);
    });
  });
}
