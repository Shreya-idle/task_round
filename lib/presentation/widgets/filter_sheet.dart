import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/task_filter.dart';
import '../providers/settings_providers.dart';

void showTaskFilterSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const TaskFilterSheet(),
  );
}

class TaskFilterSheet extends ConsumerWidget {
  const TaskFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter Tasks', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Narrow your list by category, status, or due date.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OptionChip(
                  label: 'All',
                  selected: filter.category == null,
                  onTap: () =>
                      ref.read(filterProvider.notifier).setCategory(null),
                ),
                ...AppConstants.categories.map(
                  (category) => _OptionChip(
                    label: category,
                    selected: filter.category == category,
                    onTap: () =>
                        ref.read(filterProvider.notifier).setCategory(category),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Status'),
            const SizedBox(height: 10),
            SegmentedButton<TaskStatusFilter>(
              segments: const [
                ButtonSegment(
                  value: TaskStatusFilter.all,
                  label: Text('All'),
                  icon: Icon(Icons.list_alt, size: 18),
                ),
                ButtonSegment(
                  value: TaskStatusFilter.pending,
                  label: Text('Pending'),
                  icon: Icon(Icons.pending_actions, size: 18),
                ),
                ButtonSegment(
                  value: TaskStatusFilter.done,
                  label: Text('Done'),
                  icon: Icon(Icons.check_circle_outline, size: 18),
                ),
              ],
              selected: {filter.status},
              onSelectionChanged: (selection) {
                ref.read(filterProvider.notifier).setStatus(selection.first);
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Due date'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DueDateFilter.values.map((dueFilter) {
                return _OptionChip(
                  label: _dueDateLabel(dueFilter),
                  selected: filter.dueDateFilter == dueFilter,
                  onTap: () => ref
                      .read(filterProvider.notifier)
                      .setDueDateFilter(dueFilter),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: filter.hasActiveFilters
                        ? () {
                            ref.read(filterProvider.notifier).clearFilters();
                          }
                        : null,
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dueDateLabel(DueDateFilter filter) {
    return switch (filter) {
      DueDateFilter.all => 'Any date',
      DueDateFilter.today => 'Due today',
      DueDateFilter.overdue => 'Overdue',
      DueDateFilter.thisWeek => 'This week',
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: (_) => onTap(),
    );
  }
}
