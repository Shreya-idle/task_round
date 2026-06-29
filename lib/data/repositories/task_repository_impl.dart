import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dataSource);

  final TaskLocalDataSource _dataSource;

  @override
  Future<List<Task>> getTasks({TaskFilter? filter}) async {
    final models = await _dataSource.getAllTasks();
    var tasks = models.map((m) => m.toEntity()).toList();
    if (filter != null) {
      tasks = filterTasks(tasks, filter);
    }
    return tasks;
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final model = await _dataSource.getTaskById(id);
    return model?.toEntity();
  }

  @override
  Future<Task> createTask(Task task) async {
    final sortOrder = task.sortOrder >= 0
        ? task.sortOrder
        : await _dataSource.getNextSortOrder();
    final model = TaskModel.fromEntity(task.copyWith(sortOrder: sortOrder));
    final saved = await _dataSource.insertTask(model);
    return saved.toEntity();
  }

  @override
  Future<Task> updateTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    final saved = await _dataSource.updateTask(model);
    return saved.toEntity();
  }

  @override
  Future<void> deleteTask(String id) => _dataSource.deleteTask(id);

  @override
  Future<void> reorderTasks(List<String> orderedIds) =>
      _dataSource.updateSortOrders(orderedIds);

  @override
  Future<double> getTodayCompletionProgress() async {
    final models = await _dataSource.getAllTasks();
    final allTasks = models.map((m) => m.toEntity()).toList();

    if (allTasks.isEmpty) return 0;

    final completedCount = allTasks.where((t) => t.isCompleted).length;
    return completedCount / allTasks.length;
  }

  @override
  List<Task> filterTasks(List<Task> tasks, TaskFilter filter) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final endOfWeek = startOfDay.add(const Duration(days: 7));

    Iterable<Task> result = tasks;

    if (filter.category != null) {
      result = result.where((t) => t.category == filter.category);
    }

    switch (filter.status) {
      case TaskStatusFilter.pending:
        result = result.where((t) => !t.isCompleted);
      case TaskStatusFilter.done:
        result = result.where((t) => t.isCompleted);
      case TaskStatusFilter.all:
        break;
    }

    switch (filter.dueDateFilter) {
      case DueDateFilter.today:
        result = result.where((t) {
          if (t.dueDate == null) return false;
          return !t.dueDate!.isBefore(startOfDay) &&
              t.dueDate!.isBefore(endOfDay);
        });
      case DueDateFilter.overdue:
        result = result.where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.isBefore(startOfDay) &&
              !t.isCompleted,
        );
      case DueDateFilter.thisWeek:
        result = result.where((t) {
          if (t.dueDate == null) return false;
          return !t.dueDate!.isBefore(startOfDay) &&
              t.dueDate!.isBefore(endOfWeek);
        });
      case DueDateFilter.all:
        break;
    }

    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where(
        (t) =>
            t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query),
      );
    }

    return result.toList();
  }
}
