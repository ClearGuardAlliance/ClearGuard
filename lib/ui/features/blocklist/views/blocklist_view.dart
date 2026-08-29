import 'dart:async';

import 'package:clearguard/l10n/generated/app_localizations.dart';
import 'package:clearguard/ui/features/blocklist/view_models/blocklist_view_model.dart';
import 'package:flutter/material.dart';

class BlocklistView extends StatefulWidget {
  const BlocklistView({required this.viewModel, super.key});

  final BlocklistViewModel viewModel;

  @override
  State<BlocklistView> createState() => _BlocklistViewState();
}

class _BlocklistViewState extends State<BlocklistView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.initialize());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestRemoval(BuildContext context, String domain) async {
    final pin = await _promptPin(context);
    if (pin == null || !context.mounted) return;
    final success = await widget.viewModel.requestRemoval(pin, domain);
    if (!context.mounted || success) return;
    final message = widget.viewModel.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final domains = widget.viewModel.filteredDomains;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.blocklistViewerTitle),
          ),
          body: widget.viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.blockedDomainCount(
                              widget.viewModel.totalCount,
                            ),
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: widget.viewModel.setQuery,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: l10n.searchDomainsHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: domains.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noDomainsFound,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: domains.length,
                              itemBuilder: (context, index) {
                                final domain = domains[index];
                                final pendingId = widget.viewModel
                                    .pendingRemovalIdFor(domain);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          domain,
                                          style: textTheme.bodyMedium,
                                        ),
                                      ),
                                      if (pendingId != null)
                                        TextButton(
                                          onPressed: () => widget.viewModel
                                              .cancelRemoval(pendingId),
                                          child: Text(
                                            l10n.removalPendingLabel,
                                          ),
                                        )
                                      else
                                        IconButton(
                                          tooltip: l10n.requestRemovalTooltip,
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () => _requestRemoval(
                                            context,
                                            domain,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
