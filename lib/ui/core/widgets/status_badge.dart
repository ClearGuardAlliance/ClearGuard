import 'package:flutter/material.dart';

import '../../../domain/models/protection_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ProtectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      ProtectionStatus.active => (Colors.green, 'Proteção ativa', Icons.shield),
      ProtectionStatus.starting => (Colors.orange, 'Ativando…', Icons.hourglass_top),
      ProtectionStatus.disabled => (Colors.red, 'Proteção desativada', Icons.shield_outlined),
      ProtectionStatus.error => (Colors.grey, 'Erro ao verificar status', Icons.error_outline),
    };

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }
}
