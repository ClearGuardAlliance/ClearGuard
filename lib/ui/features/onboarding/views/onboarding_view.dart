import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:flutter/material.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({
    required this.viewModel,
    required this.onFinished,
    super.key,
  });

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
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.step == OnboardingStep.done) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onFinished(),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.onboardingAppBarTitle)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: switch (widget.viewModel.step) {
                OnboardingStep.accountabilitySetup =>
                  _buildAccountabilityStep(l10n),
                OnboardingStep.vpnPermission => _buildVpnPermissionStep(l10n),
                OnboardingStep.screenMonitorPermission =>
                  _buildScreenMonitorStep(l10n),
                OnboardingStep.done => const Center(
                    child: CircularProgressIndicator(),
                  ),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountabilityStep(AppLocalizations l10n) {
    return ListView(
      children: [
        Text(
          l10n.onboardingTrustTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(l10n.onboardingTrustBody),
        const SizedBox(height: 24),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.pinLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinConfirmController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.pinConfirmLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _webhookController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.webhookOnboardingLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _partnerController,
          decoration: InputDecoration(labelText: l10n.partnerNameLabel),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.delayBeforeChangeLabel),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _delayMinutes,
              items: const [15, 30, 60, 120]
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(l10n.minutesShort(m)),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _delayMinutes = value ?? _delayMinutes),
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
          onPressed:
              widget.viewModel.isSubmitting ? null : _submitAccountability,
          child: widget.viewModel.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.continueButton),
        ),
      ],
    );
  }

  Future<void> _submitAccountability() async {
    final l10n = AppLocalizations.of(context)!;
    await widget.viewModel.submitAccountabilitySetup(
      pin: _pinController.text,
      pinConfirmation: _pinConfirmController.text,
      webhookUrl: _webhookController.text,
      partnerLabel: _partnerController.text.isEmpty
          ? l10n.defaultPartnerLabel
          : _partnerController.text,
      delay: Duration(minutes: _delayMinutes),
    );
  }

  Widget _buildVpnPermissionStep(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.vpn_lock, size: 64),
        const SizedBox(height: 16),
        Text(l10n.vpnPermissionBody, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => widget.viewModel.requestVpnPermission(),
          child: Text(l10n.grantVpnButton),
        ),
      ],
    );
  }

  Widget _buildScreenMonitorStep(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.accessibility_new, size: 64),
        const SizedBox(height: 16),
        Text(l10n.screenMonitorBody, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => widget.viewModel.openScreenMonitorSettings(),
          child: Text(l10n.openAccessibilitySettingsButton),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => widget.viewModel.confirmScreenMonitorPermission(),
          child: Text(l10n.confirmScreenMonitorButton),
        ),
      ],
    );
  }
}
