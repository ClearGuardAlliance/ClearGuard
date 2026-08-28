import 'package:clearguard/domain/models/protection_status.dart';
import 'package:flutter/material.dart';

class ProtectionStatusCard extends StatelessWidget {
  const ProtectionStatusCard({
    required this.status,
    this.blockedDomainCount,
    super.key,
  });

  final ProtectionStatus status;
  final int? blockedDomainCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final success = isDark ? const Color(0xFF7EE0A8) : const Color(0xFF0E8F4F);
    final successContainer =
        isDark ? const Color(0xFF123322) : const Color(0xFFDEF7E6);
    final warning = isDark ? const Color(0xFFFFCA7A) : const Color(0xFFB2650A);
    final warningContainer =
        isDark ? const Color(0xFF3D2C0E) : const Color(0xFFFCECD1);
    final danger = isDark ? const Color(0xFFFFB0A6) : const Color(0xFFC0342C);
    final dangerContainer =
        isDark ? const Color(0xFF3D1613) : const Color(0xFFFBDFDC);

    final domainCopy = blockedDomainCount != null
        ? '$blockedDomainCount domínios na lista de bloqueio.'
        : 'Sincronizando lista de bloqueio…';

    final (foreground, background, title, subtitle, icon) = switch (status) {
      ProtectionStatus.active => (
          success,
          successContainer,
          'Proteção ativa',
          domainCopy,
          Icons.verified_user,
        ),
      ProtectionStatus.starting => (
          warning,
          warningContainer,
          'Ativando proteção…',
          'Isso leva só alguns segundos.',
          Icons.hourglass_top,
        ),
      ProtectionStatus.disabled => (
          danger,
          dangerContainer,
          'Proteção desativada',
          'Seu tráfego não está sendo filtrado agora.',
          Icons.gpp_bad,
        ),
      ProtectionStatus.error => (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
          'Não foi possível verificar o status',
          'Confira sua conexão e tente novamente.',
          Icons.error_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: foreground, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
