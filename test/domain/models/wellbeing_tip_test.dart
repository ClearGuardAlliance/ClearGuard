import 'package:clearguard/domain/models/wellbeing_tip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WellbeingTip.forDay', () {
    test('is deterministic for the same date', () {
      final date = DateTime(2026, 3, 10);

      expect(WellbeingTip.forDay(date), WellbeingTip.forDay(date));
    });

    test('rotates through the catalog across consecutive days', () {
      final first = WellbeingTip.forDay(DateTime(2026));
      final second = WellbeingTip.forDay(DateTime(2026, 1, 2));

      expect(first, isNot(second));
    });

    test('wraps around after the catalog length', () {
      final day0 = WellbeingTip.forDay(DateTime(2026));
      final wrapped = WellbeingTip.forDay(
        DateTime(2026).add(Duration(days: WellbeingTip.all.length)),
      );

      expect(day0, wrapped);
    });
  });
}
