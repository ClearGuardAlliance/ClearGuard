import 'package:clearguard/domain/models/protection_status.dart';
import 'package:clearguard/ui/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the active label when protection is active', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StatusBadge(status: ProtectionStatus.active)),
    );

    expect(find.text('Proteção ativa'), findsOneWidget);
  });

  testWidgets('shows the disabled label when protection is disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StatusBadge(status: ProtectionStatus.disabled)),
    );

    expect(find.text('Proteção desativada'), findsOneWidget);
  });
}
