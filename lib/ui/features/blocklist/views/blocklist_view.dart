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
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  domains[index],
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
