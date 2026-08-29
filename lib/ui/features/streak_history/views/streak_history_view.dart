import 'dart:async';

import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/features/streak_history/view_models/streak_history_view_model.dart';
import 'package:flutter/material.dart';

class StreakHistoryView extends StatefulWidget {
  const StreakHistoryView({required this.viewModel, super.key});

  final StreakHistoryViewModel viewModel;

  @override
  State<StreakHistoryView> createState() => _StreakHistoryViewState();
}

class _StreakHistoryViewState extends State<StreakHistoryView> {
  static const _daysShown = 28;

  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.initialize());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final streak = widget.viewModel.streak;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.streakHistoryTitle)),
          body: widget.viewModel.isLoading || streak == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: l10n.streakCurrentLabel,
                            value: '${streak.current}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: l10n.streakRecordLabel,
                            value: '${streak.longest}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.streakLastDaysTitle(_daysShown),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _HistoryGrid(activeDays: widget.viewModel.activeDays),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _LegendDot(color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.streakActiveLegend,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _LegendDot(color: scheme.surfaceContainerHighest),
                        const SizedBox(width: 8),
                        Text(
                          l10n.streakInactiveLegend,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryGrid extends StatelessWidget {
  const _HistoryGrid({required this.activeDays});

  final Set<DateTime> activeDays;

  static const _daysShown = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final startDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: _daysShown - 1));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _daysShown,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final day = startDate.add(Duration(days: index));
        final isActive = activeDays.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
