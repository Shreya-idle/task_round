import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/page_transitions.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter.dart';
import '../providers/settings_providers.dart';
import '../providers/task_list_provider.dart';
import '../widgets/active_filter_banner.dart';
import '../widgets/animated_fab.dart';
import '../widgets/progress_ring.dart';
import '../widgets/swipeable_task_tile.dart';
import '../widgets/undo_delete_snackbar.dart';
import 'task_form_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(filterProvider).searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openTaskForm({Task? task}) async {
    _searchFocusNode.unfocus();
    await Navigator.of(context).push(
      SlideFadePageRoute(
        page: TaskFormPage(task: task),
        settings: RouteSettings(name: task == null ? '/task/new' : '/task/edit'),
      ),
    );
  }

  Future<void> _handleDismiss(Task task, int index) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    await ref.read(taskListProvider.notifier).deleteWithUndo(task, index);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        duration: Duration(seconds: AppConstants.undoDeleteSeconds + 1),
        content: UndoDeleteSnackBar(
          taskTitle: task.title,
          initialSeconds: AppConstants.undoDeleteSeconds,
          onUndo: () async {
            messenger.hideCurrentSnackBar();
            await ref.read(taskListProvider.notifier).undoDelete();
          },
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(taskListProvider.notifier).onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(filterProvider, (previous, next) {
      if (previous == null) return;
      if (previous.category != next.category ||
          previous.status != next.status ||
          previous.dueDateFilter != next.dueDateFilter) {
        ref.read(taskListProvider.notifier).refresh();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager Pro'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProgressHeaderSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _TaskSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: ref.read(taskListProvider.notifier).onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            const ActiveFilterBanner(),
            Expanded(
              child: _TaskListSection(
                onOpenTask: (task) => _openTaskForm(task: task),
                onDismiss: _handleDismiss,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onAddTask: () => _openTaskForm(),
      ),
    );
  }
}

class _TaskSearchField extends StatelessWidget {
  const _TaskSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search title or description...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _ProgressHeaderSection extends ConsumerWidget {
  const _ProgressHeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskListProvider);

    return taskState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) => _ProgressHeader(state: state),
    );
  }
}

class _TaskListSection extends ConsumerWidget {
  const _TaskListSection({
    required this.onOpenTask,
    required this.onDismiss,
  });

  final ValueChanged<Task> onOpenTask;
  final Future<void> Function(Task task, int index) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskListProvider);
    final filter = ref.watch(filterProvider);

    return taskState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.tasks.isEmpty) {
          return _EmptyState(filter: filter);
        }

        return SlidableAutoCloseBehavior(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            cacheExtent: 500,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: state.tasks.length,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 4 * animation.value,
                borderRadius: BorderRadius.circular(16),
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              ref.read(taskListProvider.notifier).reorder(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              return SwipeableTaskTile(
                key: ValueKey(task.id),
                task: task,
                index: index,
                onTap: () => onOpenTask(task),
                onToggleComplete: () =>
                    ref.read(taskListProvider.notifier).toggleComplete(task),
                onDelete: () => onDismiss(task, index),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final TaskListState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = state.totalTaskCount - state.completedTaskCount;
    final total = state.totalTaskCount;
    final completed = state.completedTaskCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task completion',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed of $total tasks complete',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$total tasks · $pending pending',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(
                key: ValueKey(completed * 1000 + total),
                progress: state.todayProgress,
                size: 72,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.filter});

  final TaskFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasFilters =
        filter.hasActiveFilters || filter.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No tasks match your filters' : 'No tasks yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting filters or search terms.'
                  : 'Tap + to create your first task.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (filter.hasActiveFilters) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(filterProvider.notifier).clearFilters(),
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
