import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/task.dart';
import 'dependency_providers.dart';
import 'settings_providers.dart';

class TaskListState {
  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.todayProgress = 0,
    this.totalTaskCount = 0,
    this.completedTaskCount = 0,
  });

  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final double todayProgress;
  final int totalTaskCount;
  final int completedTaskCount;

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? Function()? error,
    double? todayProgress,
    int? totalTaskCount,
    int? completedTaskCount,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      todayProgress: todayProgress ?? this.todayProgress,
      totalTaskCount: totalTaskCount ?? this.totalTaskCount,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
    );
  }
}

class PendingDelete {
  const PendingDelete({
    required this.task,
    required this.index,
    required this.remainingSeconds,
  });

  final Task task;
  final int index;
  final int remainingSeconds;

  PendingDelete copyWith({int? remainingSeconds}) {
    return PendingDelete(
      task: task,
      index: index,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class TaskListNotifier extends AsyncNotifier<TaskListState> {
  Timer? _searchDebounce;
  PendingDelete? _pendingDelete;
  Timer? _undoTimer;
  bool _remindersBootstrapped = false;

  @override
  Future<TaskListState> build() async {
    ref.onDispose(() {
      _searchDebounce?.cancel();
      _undoTimer?.cancel();
    });
    return _loadTasks(bootstrapReminders: true);
  }

  Future<TaskListState> _loadTasks({bool bootstrapReminders = false}) async {
    final getTasks = await ref.read(getTasksUseCaseProvider.future);
    final repository = await ref.read(taskRepositoryProvider.future);
    final filter = ref.read(filterProvider);

    final allTasks = await getTasks();
    final tasks = repository.filterTasks(allTasks, filter);
    final completed = allTasks.where((task) => task.isCompleted).length;
    final progress =
        allTasks.isEmpty ? 0.0 : completed / allTasks.length;

    if (bootstrapReminders && !_remindersBootstrapped) {
      _remindersBootstrapped = true;
      unawaited(NotificationService.instance.syncTaskReminders(allTasks));
    }

    return TaskListState(
      tasks: tasks,
      todayProgress: progress,
      totalTaskCount: allTasks.length,
      completedTaskCount: completed,
    );
  }

  TaskListState _stateFromAllTasks(List<Task> allTasks, List<Task> visible) {
    final completed = allTasks.where((task) => task.isCompleted).length;
    return TaskListState(
      tasks: visible,
      todayProgress: allTasks.isEmpty ? 0.0 : completed / allTasks.length,
      totalTaskCount: allTasks.length,
      completedTaskCount: completed,
    );
  }

  Future<void> refresh() => _silentRefresh();

  Future<void> _silentRefresh() async {
    final previous = state.valueOrNull;
    try {
      final next = await _loadTasks();
      state = AsyncData(next);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  void debouncedSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () async {
        ref.read(filterProvider.notifier).setSearchQuery(query);
        await _silentRefresh();
      },
    );
  }

  Future<bool> addTask(Task task) async {
    final useCase = await ref.read(createTaskUseCaseProvider.future);
    final saved = await useCase(task);
    return _persistAndRefresh(saved);
  }

  Future<bool> updateTask(Task task) async {
    final useCase = await ref.read(updateTaskUseCaseProvider.future);
    final saved = await useCase(task);
    return _persistAndRefresh(saved);
  }

  Future<bool> _persistAndRefresh(Task saved) async {
    final scheduled = await _scheduleReminderIfNeeded(saved);

    final getTasks = await ref.read(getTasksUseCaseProvider.future);
    final repository = await ref.read(taskRepositoryProvider.future);
    final filter = ref.read(filterProvider);
    final allTasks = await getTasks();
    final visible = repository.filterTasks(allTasks, filter);

    state = AsyncData(_stateFromAllTasks(allTasks, visible));
    return scheduled;
  }

  Future<void> toggleComplete(Task task) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final now = DateTime.now();
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: () => !task.isCompleted ? now : null,
    );

    final optimisticTasks = current.tasks
        .map((t) => t.id == task.id ? updated : t)
        .toList(growable: false);
    state = AsyncData(current.copyWith(tasks: optimisticTasks));

    final useCase = await ref.read(updateTaskUseCaseProvider.future);
    final saved = await useCase(updated);
    await _scheduleReminderIfNeeded(saved);

    final getTasks = await ref.read(getTasksUseCaseProvider.future);
    final repository = await ref.read(taskRepositoryProvider.future);
    final filter = ref.read(filterProvider);
    final allTasks = await getTasks();
    final visible = repository.filterTasks(allTasks, filter);
    state = AsyncData(_stateFromAllTasks(allTasks, visible));
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final tasks = List<Task>.from(current.tasks);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, moved);

    state = AsyncData(current.copyWith(tasks: tasks));

    final reorderUseCase = await ref.read(reorderTasksUseCaseProvider.future);
    await reorderUseCase(tasks.map((t) => t.id).toList());
  }

  Future<void> deleteWithUndo(Task task, int index) async {
    _undoTimer?.cancel();

    final current = state.valueOrNull;
    if (current == null) return;

    final tasks = List<Task>.from(current.tasks)..removeAt(index);
    state = AsyncData(current.copyWith(tasks: tasks));

    final deleteUseCase = await ref.read(deleteTaskUseCaseProvider.future);
    await deleteUseCase(task.id);
    await _cancelReminder(task);

    _pendingDelete = PendingDelete(
      task: task,
      index: index,
      remainingSeconds: AppConstants.undoDeleteSeconds,
    );

    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final pending = _pendingDelete;
      if (pending == null) {
        timer.cancel();
        return;
      }
      if (pending.remainingSeconds <= 1) {
        _pendingDelete = null;
        timer.cancel();
        await _silentRefresh();
        return;
      }
      _pendingDelete = pending.copyWith(
        remainingSeconds: pending.remainingSeconds - 1,
      );
    });
  }

  Future<bool> undoDelete() async {
    final pending = _pendingDelete;
    if (pending == null) return false;

    _undoTimer?.cancel();
    _pendingDelete = null;

    final createUseCase = await ref.read(createTaskUseCaseProvider.future);
    final reorderUseCase = await ref.read(reorderTasksUseCaseProvider.future);
    final getTasksUseCase = await ref.read(getTasksUseCaseProvider.future);

    await createUseCase(pending.task);

    final allTasks = await getTasksUseCase();
    final ids = allTasks
        .map((task) => task.id)
        .where((id) => id != pending.task.id)
        .toList();
    final insertAt = pending.task.sortOrder.clamp(0, ids.length);
    ids.insert(insertAt, pending.task.id);
    await reorderUseCase(ids);

    await _scheduleReminderIfNeeded(pending.task);
    await _silentRefresh();
    return true;
  }

  PendingDelete? get pendingDelete => _pendingDelete;

  Future<bool> _scheduleReminderIfNeeded(Task task) async {
    final notifications = NotificationService.instance;
    final id = notifications.notificationIdFromTaskId(task.id);

    if (task.reminderAt == null || task.isCompleted) {
      await notifications.cancelReminder(id);
      return false;
    }

    return notifications.scheduleTaskReminder(
      notificationId: id,
      title: 'Task reminder',
      body: task.title,
      scheduledAt: task.reminderAt!,
    );
  }

  Future<void> _cancelReminder(Task task) async {
    final notifications = NotificationService.instance;
    await notifications.cancelReminder(
      notifications.notificationIdFromTaskId(task.id),
    );
  }
}

final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, TaskListState>(
  TaskListNotifier.new,
);
