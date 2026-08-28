import 'package:clearguard/domain/models/protection_status.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
        ? l10n.statusActiveWithDomains(blockedDomainCount!)
        : l10n.statusSyncingBlocklist;

    final (foreground, background, title, subtitle, icon) = switch (status) {
      ProtectionStatus.active => (
          success,
          successContainer,
          l10n.statusActiveTitle,
          domainCopy,
          Icons.verified_user,
        ),
      ProtectionStatus.starting => (
          warning,
          warningContainer,
          l10n.statusStartingTitle,
          l10n.statusStartingBody,
          Icons.hourglass_top,
        ),
      ProtectionStatus.disabled => (
          danger,
          dangerContainer,
          l10n.statusDisabledTitle,
          l10n.statusDisabledBody,
          Icons.gpp_bad,
        ),
      ProtectionStatus.error => (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
          l10n.statusErrorTitle,
          l10n.statusErrorBody,
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
