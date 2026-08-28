import 'dart:async';

import 'package:clearguard/domain/models/accountability_config.dart';
import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/features/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({required this.viewModel, super.key});

  final SettingsViewModel viewModel;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _webhookController = TextEditingController();
  final _remoteBlocklistController = TextEditingController();
  int _delayMinutes = AccountabilityConfig.defaultDelay.inMinutes;
  bool _initializedFields = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.initialize());
  }

  @override
  void dispose() {
    _webhookController.dispose();
    _remoteBlocklistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final config = widget.viewModel.config;
        final windowStart = _formatMinutes(
          widget.viewModel.blockWindow.startMinutes,
        );
        final windowEnd = _formatMinutes(
          widget.viewModel.blockWindow.endMinutes,
        );
        if (config != null && !_initializedFields) {
          _webhookController.text = config.webhookUrl;
          _remoteBlocklistController.text = widget.viewModel.remoteBlocklistUrl;
          _delayMinutes = config.sensitiveActionDelay.inMinutes;
          _initializedFields = true;
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsAppBarTitle)),
          body: config == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    ...widget.viewModel.pendingActions.map(
                      (action) => _PendingSettingCard(
                        action: action,
                        onCancel: () =>
                            widget.viewModel.cancelPendingAction(action.id),
                      ),
                    ),
                    if (widget.viewModel.pendingActions.isNotEmpty)
                      const SizedBox(height: 16),
                    Text(
                      l10n.accountabilitySectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _webhookController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: l10n.webhookSettingsLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _requestWebhookChange(context),
                        child: Text(l10n.requestChangeButton),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(l10n.waitTimeLabel),
                        const SizedBox(width: 12),
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
                          onChanged: (value) => setState(
                            () => _delayMinutes = value ?? _delayMinutes,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _requestDelayChange(context),
                        child: Text(l10n.requestChangeButton),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.blocklistSectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remoteBlocklistController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: l10n.remoteBlocklistUrlLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _requestRemoteBlocklistChange(context),
                        child: Text(l10n.requestChangeButton),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.deviceAdminSectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (widget.viewModel.isDeviceAdminActive)
                      Text(l10n.deviceAdminActiveText)
                    else
                      FilledButton(
                        onPressed: () => widget.viewModel.activateDeviceAdmin(),
                        child: Text(l10n.activateButton),
                      ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.batterySectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (widget.viewModel.isIgnoringBatteryOptimizations)
                      Text(l10n.batteryExemptText)
                    else
                      FilledButton(
                        onPressed: () => widget.viewModel
                            .requestIgnoreBatteryOptimizations(),
                        child: Text(l10n.batteryExemptButton),
                      ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.blockWindowSectionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.blockWindowDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.blockWindowSwitchLabel),
                      value: widget.viewModel.blockWindow.enabled,
                      onChanged: (enabled) => widget.viewModel.setBlockWindow(
                        widget.viewModel.blockWindow.copyWith(
                          enabled: enabled,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _pickWindowTime(context, isStart: true),
                            child: Text(
                              l10n.blockWindowStartLabel(windowStart),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _pickWindowTime(context, isStart: false),
                            child: Text(l10n.blockWindowEndLabel(windowEnd)),
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

  Future<void> _requestWebhookChange(BuildContext context) async {
    final pin = await _promptPin(context);
    if (pin == null || !context.mounted) return;
    final success = await widget.viewModel.requestWebhookChange(
      pin,
      _webhookController.text,
    );
    if (!context.mounted) return;
    _showErrorIfAny(context, success);
  }

  Future<void> _requestRemoteBlocklistChange(BuildContext context) async {
    final pin = await _promptPin(context);
    if (pin == null || !context.mounted) return;
    final success = await widget.viewModel.requestRemoteBlocklistUrlChange(
      pin,
      _remoteBlocklistController.text,
    );
    if (!context.mounted) return;
    _showErrorIfAny(context, success);
  }

  Future<void> _requestDelayChange(BuildContext context) async {
    final pin = await _promptPin(context);
    if (pin == null || !context.mounted) return;
    final success = await widget.viewModel.requestDelayChange(
      pin,
      _delayMinutes,
    );
    if (!context.mounted) return;
    _showErrorIfAny(context, success);
  }

  void _showErrorIfAny(BuildContext context, bool success) {
    if (!context.mounted || success || widget.viewModel.errorMessage == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.viewModel.errorMessage!)));
  }

  Future<void> _pickWindowTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final window = widget.viewModel.blockWindow;
    final currentMinutes = isStart ? window.startMinutes : window.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      ),
    );
    if (picked == null || !context.mounted) return;

    final minutes = picked.hour * 60 + picked.minute;
    await widget.viewModel.setBlockWindow(
      isStart
          ? window.copyWith(startMinutes: minutes)
          : window.copyWith(endMinutes: minutes),
    );
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<String?> _promptPin(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();
    return showDialog<String>(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(pinController.text),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
  }
}

class _PendingSettingCard extends StatelessWidget {
  const _PendingSettingCard({required this.action, required this.onCancel});

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
                    ? l10n.pendingChangeMinutesOnly(minutesLeft)
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
