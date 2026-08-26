import 'package:flutter/material.dart';

import '../view_models/onboarding_view_model.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.viewModel, required this.onFinished});

  final OnboardingViewModel viewModel;
  final VoidCallback onFinished;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  final _webhookController = TextEditingController();
  final _partnerController = TextEditingController();
  int _delayMinutes = 30;

  @override
  void dispose() {
    _pinController.dispose();
    _pinConfirmController.dispose();
    _webhookController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.step == OnboardingStep.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinished());
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Configurar ClearGuard')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (widget.viewModel.step) {
                OnboardingStep.accountabilitySetup => _buildAccountabilityStep(),
                OnboardingStep.vpnPermission => _buildVpnPermissionStep(),
                OnboardingStep.screenMonitorPermission => _buildScreenMonitorStep(),
                OnboardingStep.done => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountabilityStep() {
    return ListView(
      children: [
        Text(
          'Configuração de confiança',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'O ideal é que quem digita o PIN e o webhook abaixo seja o seu '
          'parceiro de confiança, não você. Toda tentativa de desativar a '
          'proteção vai gerar um aviso nesse webhook antes de valer.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN (mín. 6 dígitos)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinConfirmController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar PIN'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _webhookController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Webhook do parceiro (Discord/Slack/Telegram)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _partnerController,
          decoration: const InputDecoration(labelText: 'Como chamar o parceiro (ex: "Ana")'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Tempo de espera antes de qualquer mudança valer:'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _delayMinutes,
              items: const [15, 30, 60, 120]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                  .toList(),
              onChanged: (value) => setState(() => _delayMinutes = value ?? _delayMinutes),
            ),
          ],
        ),
        if (widget.viewModel.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.viewModel.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.viewModel.isSubmitting ? null : _submitAccountability,
          child: widget.viewModel.isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Continuar'),
        ),
      ],
    );
  }

  Future<void> _submitAccountability() async {
    await widget.viewModel.submitAccountabilitySetup(
      pin: _pinController.text,
      pinConfirmation: _pinConfirmController.text,
      webhookUrl: _webhookController.text,
      partnerLabel: _partnerController.text.isEmpty ? 'seu parceiro' : _partnerController.text,
      delay: Duration(minutes: _delayMinutes),
    );
  }

  Widget _buildVpnPermissionStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.vpn_lock, size: 64),
        const SizedBox(height: 16),
        const Text(
          'O Android vai pedir permissão de VPN local — é assim que o '
          'ClearGuard filtra os domínios bloqueados, sem enviar seu tráfego '
          'para nenhum servidor externo.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => widget.viewModel.requestVpnPermission(),
          child: const Text('Conceder permissão de VPN'),
        ),
      ],
    );
  }

  Widget _buildScreenMonitorStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.accessibility_new, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Agora ative o serviço de Acessibilidade do ClearGuard nas '
          'configurações do Android. Ele complementa o bloqueio por DNS '
          'detectando conteúdo explícito em páginas que já carregaram.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => widget.viewModel.openScreenMonitorSettings(),
          child: const Text('Abrir configurações de Acessibilidade'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => widget.viewModel.confirmScreenMonitorPermission(),
          child: const Text('Já ativei, continuar'),
        ),
      ],
    );
  }
}
