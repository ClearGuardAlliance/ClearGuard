import 'package:clearguard/domain/models/protection_status.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final ProtectionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final success = isDark ? const Color(0xFFA6F1C8) : const Color(0xFF0B5F3C);
    final successContainer =
        isDark ? const Color(0xFF0B4A30) : const Color(0xFFD4F5E2);
    final warning = isDark ? const Color(0xFFFFD9A6) : const Color(0xFF8A4B00);
    final warningContainer =
        isDark ? const Color(0xFF5C3600) : const Color(0xFFFFE7C2);

    final (foreground, background, label, icon) = switch (status) {
      ProtectionStatus.active => (
          success,
          successContainer,
          'Proteção ativa',
          Icons.shield,
        ),
      ProtectionStatus.starting => (
          warning,
          warningContainer,
          'Ativando…',
          Icons.hourglass_top,
        ),
      ProtectionStatus.disabled => (
          scheme.onErrorContainer,
          scheme.errorContainer,
          'Proteção desativada',
          Icons.shield_outlined,
        ),
      ProtectionStatus.error => (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
          'Erro ao verificar status',
          Icons.error_outline,
        ),
    };

    return Chip(
      avatar: Icon(icon, color: foreground, size: 18),
      label: Text(label, style: TextStyle(color: foreground)),
      backgroundColor: background,
      side: BorderSide.none,
    );
  }
}
