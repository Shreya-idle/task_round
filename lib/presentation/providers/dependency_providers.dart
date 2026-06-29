import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/task_usecases.dart';

final databaseProvider = FutureProvider<TaskLocalDataSource>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return TaskLocalDataSource.create(dir.path);
});

final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final dataSource = await ref.watch(databaseProvider.future);
  return TaskRepositoryImpl(dataSource);
});

final settingsRepositoryProvider =
    FutureProvider<SettingsRepository>((ref) async {
  final dataSource = await ref.watch(databaseProvider.future);
  return SettingsRepositoryImpl(dataSource);
});

final createTaskUseCaseProvider = FutureProvider<CreateTaskUseCase>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return CreateTaskUseCase(repo);
});

final updateTaskUseCaseProvider = FutureProvider<UpdateTaskUseCase>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return UpdateTaskUseCase(repo);
});

final deleteTaskUseCaseProvider = FutureProvider<DeleteTaskUseCase>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return DeleteTaskUseCase(repo);
});

final reorderTasksUseCaseProvider =
    FutureProvider<ReorderTasksUseCase>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return ReorderTasksUseCase(repo);
});

final getTasksUseCaseProvider = FutureProvider<GetTasksUseCase>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return GetTasksUseCase(repo);
});

final getTodayProgressUseCaseProvider =
    FutureProvider<GetTodayProgressUseCase>((ref) async {
  final repo = await ref.watch(taskRepositoryProvider.future);
  return GetTodayProgressUseCase(repo);
});
