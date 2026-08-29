import 'dart:async';

import 'package:clearguard/domain/models/accountability_config.dart';
import 'package:clearguard/domain/models/pending_action.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/features/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    required this.viewModel,
    required this.onOpenBlocklist,
    super.key,
  });

  final SettingsViewModel viewModel;
  final void Function(BuildContext) onOpenBlocklist;

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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    ...widget.viewModel.pendingActions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PendingSettingCard(
                          action: action,
                          onCancel: () =>
                              widget.viewModel.cancelPendingAction(action.id),
                        ),
                      ),
                    ),
                    _SectionCard(
                      icon: Icons.shield_moon_outlined,
                      title: l10n.accountabilitySectionTitle,
                      children: [
                        TextField(
                          controller: _webhookController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l10n.webhookSettingsLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _requestWebhookChange(context),
                          child: Text(l10n.requestChangeButton),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(l10n.waitTimeLabel),
                            const SizedBox(width: 12),
                            _DelayDropdown(
                              value: _delayMinutes,
                              onChanged: (value) => setState(
                                () => _delayMinutes = value ?? _delayMinutes,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _requestDelayChange(context),
                          child: Text(l10n.requestChangeButton),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.block_outlined,
                      title: l10n.blocklistSectionTitle,
                      children: [
                        TextField(
                          controller: _remoteBlocklistController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l10n.remoteBlocklistUrlLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () =>
                              _requestRemoteBlocklistChange(context),
                          child: Text(l10n.requestChangeButton),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => widget.onOpenBlocklist(context),
                          child: Text(l10n.viewBlocklistButton),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: l10n.deviceAdminSectionTitle,
                      children: [
                        if (widget.viewModel.isDeviceAdminActive)
                          Text(l10n.deviceAdminActiveText)
                        else
                          FilledButton(
                            onPressed: () =>
                                widget.viewModel.activateDeviceAdmin(),
                            child: Text(l10n.activateButton),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.battery_charging_full_outlined,
                      title: l10n.batterySectionTitle,
                      children: [
                        if (widget.viewModel.isIgnoringBatteryOptimizations)
                          Text(l10n.batteryExemptText)
                        else
                          FilledButton(
                            onPressed: () => widget.viewModel
                                .requestIgnoreBatteryOptimizations(),
                            child: Text(l10n.batteryExemptButton),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.schedule_outlined,
                      title: l10n.blockWindowSectionTitle,
                      children: [
                        Text(
                          l10n.blockWindowDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.blockWindowSwitchLabel),
                          value: widget.viewModel.blockWindow.enabled,
                          onChanged: (enabled) =>
                              widget.viewModel.setBlockWindow(
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
                                child: Text(
                                  l10n.blockWindowEndLabel(windowEnd),
                                ),
                              ),
                            ),
                          ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

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
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DelayDropdown extends StatelessWidget {
  const _DelayDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          items: const [15, 30, 60, 120]
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(l10n.minutesShort(m)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
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
