import 'dart:async';

import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/domain/models/protection_status.dart';
import 'package:clearguard/ui/core/widgets/protection_status_card.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ProtectionStatusCard(
                  status: widget.viewModel.status,
                  blockedDomainCount: widget.viewModel.blockedDomainCount,
                ),
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
                const SizedBox(height: 28),
                Text('Como a proteção funciona', style: _sectionTitle(context)),
                const SizedBox(height: 12),
                const _InfoRow(
                  icon: Icons.dns_outlined,
                  title: 'Filtro por DNS',
                  description:
                      'Um túnel VPN local recusa domínios da lista de '
                      'bloqueio antes que a página chegue a carregar, sem '
                      'enviar seu tráfego para nenhum servidor externo.',
                ),
                const SizedBox(height: 16),
                const _InfoRow(
                  icon: Icons.visibility_outlined,
                  title: 'Monitoramento de tela',
                  description:
                      'Um serviço de acessibilidade detecta conteúdo '
                      'explícito em páginas que já carregaram, como reforço '
                      'ao filtro de DNS.',
                ),
                const SizedBox(height: 16),
                const _InfoRow(
                  icon: Icons.shield_moon_outlined,
                  title: 'Accountability',
                  description:
                      'Qualquer tentativa de mexer nessas proteções passa '
                      'por um PIN e um período de espera, com aviso para o '
                      'seu parceiro de confiança.',
                ),
                const SizedBox(height: 32),
                _buildPrimaryAction(context),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle? _sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge;

  Widget _buildPrimaryAction(BuildContext context) {
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
          label: const Text('Reativar proteção agora'),
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
              ? 'Desativação já solicitada'
              : 'Solicitar desativação da proteção',
        ),
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
