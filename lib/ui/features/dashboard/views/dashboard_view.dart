import 'dart:async';

import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/domain/models/protection_status.dart';
import 'package:clearguard/ui/core/widgets/status_badge.dart';
import 'package:clearguard/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    required this.viewModel,
    required this.onOpenSettings,
    super.key,
  });

  final DashboardViewModel viewModel;
  final VoidCallback onOpenSettings;

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
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ClearGuard'),
            actions: [
              IconButton(
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.viewModel.initialize,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: StatusBadge(status: widget.viewModel.status)),
                const SizedBox(height: 16),
                if (widget.viewModel.blockedDomainCount != null)
                  Center(
                    child: Text(
                      '${widget.viewModel.blockedDomainCount} domínios na '
                      'lista de bloqueio',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 32),
                ...widget.viewModel.pendingActions
                    .where((a) => a.state == PendingActionState.pending)
                    .map(
                      (action) => _PendingActionCard(
                        action: action,
                        onCancel: () =>
                            widget.viewModel.cancelPendingAction(action.id),
                      ),
                    ),
                const SizedBox(height: 24),
                _buildPrimaryAction(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    final hasPendingDisable = widget.viewModel.pendingActions.any(
      (a) =>
          a.type == PendingActionType.disableProtection &&
          a.state == PendingActionState.pending,
    );

    if (widget.viewModel.status == ProtectionStatus.disabled) {
      return FilledButton.icon(
        onPressed: widget.viewModel.reEnableProtection,
        icon: const Icon(Icons.shield),
        label: const Text('Reativar proteção agora'),
      );
    }

    return OutlinedButton.icon(
      onPressed:
          hasPendingDisable ? null : () => _promptDisableProtection(context),
      icon: const Icon(Icons.shield_outlined),
      label: Text(
        hasPendingDisable
            ? 'Desativação já solicitada'
            : 'Solicitar desativação da proteção',
      ),
    );
  }

  Future<void> _promptDisableProtection(BuildContext context) async {
    final pinController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar com PIN'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'PIN de accountability'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Solicitar'),
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

class _PendingActionCard extends StatelessWidget {
  const _PendingActionCard({required this.action, required this.onCancel});

  final PendingAction action;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
                    ? 'Mudança pendente: passa a valer em $minutesLeft min. '
                        'Seu parceiro já foi avisado.'
                    : 'Mudança pendente: passa a valer a qualquer momento.',
              ),
            ),
            TextButton(onPressed: onCancel, child: const Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}
