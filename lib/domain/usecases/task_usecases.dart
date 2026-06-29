import '../entities/task.dart';
import '../entities/task_filter.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(Task task) => _repository.createTask(task);
}

class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(Task task) => _repository.updateTask(task);
}

class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}

class ReorderTasksUseCase {
  const ReorderTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(List<String> orderedIds) =>
      _repository.reorderTasks(orderedIds);
}

class GetTasksUseCase {
  const GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call({TaskFilter? filter}) =>
      _repository.getTasks(filter: filter);
}

class GetTodayProgressUseCase {
  const GetTodayProgressUseCase(this._repository);

  final TaskRepository _repository;

  Future<double> call() => _repository.getTodayCompletionProgress();
}
