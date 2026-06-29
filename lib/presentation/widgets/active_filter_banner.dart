import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';
import 'filter_sheet.dart';

class ActiveFilterBanner extends ConsumerWidget {
  const ActiveFilterBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final theme = Theme.of(context);
    final labels = filter.activeLabels;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: labels.isEmpty
                    ? Text(
                        'No filters applied',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: labels
                            .map(
                              (label) => Chip(
                                label: Text(label),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
              ),
              TextButton(
                onPressed: () => showTaskFilterSheet(context),
                child: Text(labels.isEmpty ? 'Add' : 'Edit'),
              ),
              if (filter.hasActiveFilters)
                IconButton(
                  tooltip: 'Clear filters',
                  onPressed: () =>
                      ref.read(filterProvider.notifier).clearFilters(),
                  icon: const Icon(Icons.close, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
