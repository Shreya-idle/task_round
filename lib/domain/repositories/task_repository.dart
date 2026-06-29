import '../entities/task.dart';
import '../entities/task_filter.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks({TaskFilter? filter});

  Future<Task?> getTaskById(String id);

  Future<Task> createTask(Task task);

  Future<Task> updateTask(Task task);

  Future<void> deleteTask(String id);

  Future<void> reorderTasks(List<String> orderedIds);

  Future<double> getTodayCompletionProgress();

  List<Task> filterTasks(List<Task> tasks, TaskFilter filter);
}
