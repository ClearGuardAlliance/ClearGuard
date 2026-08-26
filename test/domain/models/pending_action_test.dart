import 'package:clearguard/domain/models/pending_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingAction', () {
    test('isReadyToApply is false before readyAt', () {
      final action = PendingAction(
        id: '1',
        type: PendingActionType.disableProtection,
        requestedAt: DateTime.now(),
        readyAt: DateTime.now().add(const Duration(minutes: 30)),
        state: PendingActionState.pending,
      );

      expect(action.isReadyToApply, isFalse);
    });

    test('isReadyToApply is true once readyAt has passed', () {
      final action = PendingAction(
        id: '1',
        type: PendingActionType.disableProtection,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 31)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 1)),
        state: PendingActionState.pending,
      );

      expect(action.isReadyToApply, isTrue);
    });

    test(
      'isReadyToApply is false when already applied, even if readyAt passed',
      () {
        final action = PendingAction(
          id: '1',
          type: PendingActionType.disableProtection,
          requestedAt: DateTime.now().subtract(const Duration(minutes: 31)),
          readyAt: DateTime.now().subtract(const Duration(minutes: 1)),
          state: PendingActionState.applied,
        );

        expect(action.isReadyToApply, isFalse);
      },
    );

    test('timeRemaining never goes negative', () {
      final action = PendingAction(
        id: '1',
        type: PendingActionType.disableProtection,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 31)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 1)),
        state: PendingActionState.pending,
      );

      expect(action.timeRemaining, Duration.zero);
    });

    test('round-trips through JSON', () {
      final action = PendingAction(
        id: 'abc',
        type: PendingActionType.removeBlocklistDomain,
        requestedAt: DateTime.utc(2026, 1, 1, 10),
        readyAt: DateTime.utc(2026, 1, 1, 10, 30),
        state: PendingActionState.pending,
        payload: const {'domain': 'example.com'},
      );

      final restored = PendingAction.fromJson(action.toJson());

      expect(restored.id, action.id);
      expect(restored.type, action.type);
      expect(restored.requestedAt, action.requestedAt);
      expect(restored.readyAt, action.readyAt);
      expect(restored.state, action.state);
      expect(restored.payload, action.payload);
    });
  });
}
