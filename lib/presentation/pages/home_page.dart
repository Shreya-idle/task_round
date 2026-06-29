import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/page_transitions.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter.dart';
import '../providers/settings_providers.dart';
import '../providers/task_list_provider.dart';
import '../widgets/active_filter_banner.dart';
import '../widgets/animated_fab.dart';
import '../widgets/progress_ring.dart';
import '../widgets/task_tile.dart';
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
    _searchController.addListener(() => setState(() {}));
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

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    ref.listen(filterProvider, (previous, next) {
      if (previous == null) return;
      if (previous.category != next.category ||
          previous.status != next.status ||
          previous.dueDateFilter != next.dueDateFilter) {
        ref.read(taskListProvider.notifier).refresh();
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task Manager Pro'),
        ),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                flex: keyboardOpen ? 1 : 0,
                fit: keyboardOpen ? FlexFit.tight : FlexFit.loose,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!keyboardOpen)
                        taskState.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (state) => _ProgressHeader(state: state),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: SearchBar(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          hintText: 'Search title or description...',
                          leading: const Icon(Icons.search),
                          elevation: WidgetStateProperty.all(0),
                          backgroundColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerHighest,
                          ),
                          onChanged: (value) {
                            ref
                                .read(taskListProvider.notifier)
                                .debouncedSearch(value);
                          },
                          trailing: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(taskListProvider.notifier)
                                      .debouncedSearch('');
                                },
                              ),
                          ],
                        ),
                      ),
                      if (!keyboardOpen) const ActiveFilterBanner(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: taskState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (state) {
                    if (state.tasks.isEmpty) {
                      return _EmptyState(filter: filter);
                    }

                    return ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      cacheExtent: 400,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: state.tasks.length,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(taskListProvider.notifier)
                            .reorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final task = state.tasks[index];
                        return Dismissible(
                          key: ValueKey(task.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.onError,
                            ),
                          ),
                          onDismissed: (_) => _handleDismiss(task, index),
                          child: TaskTile(
                            task: task,
                            onTap: () => _openTaskForm(task: task),
                            onToggleComplete: () => ref
                                .read(taskListProvider.notifier)
                                .toggleComplete(task),
                            dragHandle: ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: AnimatedFab(
          onAddTask: () => _openTaskForm(),
          onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final TaskListState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = state.tasks.where((task) => !task.isCompleted).length;
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
                      '${state.tasks.length} tasks · $pending pending',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(
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
