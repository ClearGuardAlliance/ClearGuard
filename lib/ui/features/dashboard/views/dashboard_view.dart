import 'dart:async';

import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/domain/models/protection_status.dart';
import 'package:clearguard/domain/models/protection_streak.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/core/widgets/protection_status_card.dart';
import 'package:clearguard/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    required this.viewModel,
    required this.onOpenSettings,
    required this.onOpenTriggerApps,
    super.key,
  });

  final DashboardViewModel viewModel;
  final void Function(BuildContext) onOpenSettings;
  final void Function(BuildContext) onOpenTriggerApps;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
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
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              IconButton(
                onPressed: () => widget.onOpenSettings(context),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.viewModel.initialize,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ProtectionStatusCard(
                  status: widget.viewModel.status,
                  blockedDomainCount: widget.viewModel.blockedDomainCount,
                ),
                if ((widget.viewModel.streak?.current ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  _StreakBadge(streak: widget.viewModel.streak!),
                ],
                ...widget.viewModel.pendingActions
                    .where((a) => a.state == PendingActionState.pending)
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _PendingActionCard(
                          action: action,
                          onCancel: () => widget.viewModel
                              .cancelPendingAction(action.id),
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                _TriggerAppsEntryCard(
                  onTap: () => widget.onOpenTriggerApps(context),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.howProtectionWorksTitle,
                  style: _sectionTitle(context),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.dns_outlined,
                  title: l10n.dnsFilterTitle,
                  description: l10n.dnsFilterBody,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.visibility_outlined,
                  title: l10n.screenMonitorInfoTitle,
                  description: l10n.screenMonitorInfoBody,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.shield_moon_outlined,
                  title: l10n.accountabilityInfoTitle,
                  description: l10n.accountabilityInfoBody,
                ),
                const SizedBox(height: 32),
                _buildPrimaryAction(context, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle? _sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge;

  Widget _buildPrimaryAction(BuildContext context, AppLocalizations l10n) {
    final hasPendingDisable = widget.viewModel.pendingActions.any(
      (a) =>
          a.type == PendingActionType.disableProtection &&
          a.state == PendingActionState.pending,
    );

    if (widget.viewModel.status == ProtectionStatus.disabled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: widget.viewModel.reEnableProtection,
          icon: const Icon(Icons.shield),
          label: Text(l10n.reactivateProtectionButton),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed:
            hasPendingDisable ? null : () => _promptDisableProtection(context),
        icon: const Icon(Icons.shield_outlined),
        label: Text(
          hasPendingDisable
              ? l10n.disableAlreadyRequestedButton
              : l10n.requestDisableProtectionButton,
        ),
      ),
    );
  }

  Future<void> _promptDisableProtection(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmWithPinTitle),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.pinAccountabilityLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.requestButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await widget.viewModel.requestDisableProtection(
      pinController.text,
    );
    if (!context.mounted) return;

    if (!success && widget.viewModel.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.viewModel.errorMessage!)));
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 14),
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
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TriggerAppsEntryCard extends StatelessWidget {
  const _TriggerAppsEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.apps_outlined,
                  color: scheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.triggerAppsCardTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.triggerAppsCardBody,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingActionCard extends StatelessWidget {
  const _PendingActionCard({required this.action, required this.onCancel});

  final PendingAction action;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final minutesLeft = action.timeRemaining.inMinutes;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                minutesLeft > 0
                    ? l10n.pendingChangeWithPartner(minutesLeft)
                    : l10n.pendingChangeAnyMoment,
              ),
            ),
            TextButton(onPressed: onCancel, child: Text(l10n.cancelButton)),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final ProtectionStreak streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.streakDays(streak.current),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (streak.longest > streak.current)
            Text(
              l10n.streakRecord(streak.longest),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
