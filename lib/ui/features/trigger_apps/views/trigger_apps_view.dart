import 'dart:async';

import 'package:clearguard/domain/models/trigger_app.dart';
import 'package:clearguard/domain/models/trigger_apps_report.dart';
import 'package:clearguard/domain/models/wellbeing_tip.dart';
import 'package:clearguard/l10n/domain_text.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/features/trigger_apps/view_models/trigger_apps_view_model.dart';
import 'package:flutter/material.dart';

class TriggerAppsView extends StatefulWidget {
  const TriggerAppsView({required this.viewModel, super.key});

  final TriggerAppsViewModel viewModel;

  @override
  State<TriggerAppsView> createState() => _TriggerAppsViewState();
}

class _TriggerAppsViewState extends State<TriggerAppsView> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.initialize());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final report = widget.viewModel.report;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.triggerAppsCardTitle)),
          body: widget.viewModel.isLoading || report == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: widget.viewModel.initialize,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      _RiskSummaryCard(report: report),
                      if (report.detectedApps.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text(
                          l10n.detectedAppsTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final category in TriggerAppCategory.values)
                          if (report.byCategory(category).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CategoryGroup(
                                category: category,
                                apps: report.byCategory(category),
                              ),
                            ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        l10n.tipsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      for (final tip in WellbeingTip.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TipCard(tip: tip),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _RiskSummaryCard extends StatelessWidget {
  const _RiskSummaryCard({required this.report});

  final TriggerAppsReport report;

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

    final (foreground, background, icon, subtitle) = switch (
        report.riskLevel) {
      TriggerAppsRiskLevel.none => (
          success,
          successContainer,
          Icons.check_circle_outline,
          l10n.riskNoneSubtitle,
        ),
      TriggerAppsRiskLevel.low => (
          success,
          successContainer,
          Icons.info_outline,
          l10n.riskLowSubtitle(report.detectedApps.length),
        ),
      TriggerAppsRiskLevel.medium => (
          warning,
          warningContainer,
          Icons.warning_amber,
          l10n.riskMediumSubtitle(report.detectedApps.length),
        ),
      TriggerAppsRiskLevel.high => (
          danger,
          dangerContainer,
          Icons.error_outline,
          l10n.riskHighSubtitle,
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
                  report.riskLevel.label(l10n),
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

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({required this.category, required this.apps});

  final TriggerAppCategory category;
  final List<TriggerApp> apps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label(l10n),
            style: textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final app in apps)
                Chip(
                  label: Text(app.displayName),
                  side: BorderSide.none,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final WellbeingTip tip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip.title(l10n),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            tip.body(l10n),
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
