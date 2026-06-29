import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:task_manager_pro/data/datasources/task_local_datasource.dart';
import 'package:task_manager_pro/data/repositories/task_repository_impl.dart';
import 'package:task_manager_pro/domain/entities/task.dart';
import 'package:task_manager_pro/domain/entities/task_filter.dart';

void main() {
  late TaskLocalDataSource dataSource;
  late TaskRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('task_manager_test_');
    dataSource = await TaskLocalDataSource.create(tempDir.path);
    repository = TaskRepositoryImpl(dataSource);
  });

  Task buildTask({
    required String id,
    required String title,
    String category = 'Work',
    bool isCompleted = false,
    int sortOrder = 0,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title,
      description: 'Description for $title',
      category: category,
      isCompleted: isCompleted,
      sortOrder: sortOrder,
      createdAt: DateTime(2026, 1, 1),
      dueDate: dueDate,
      completedAt: completedAt,
    );
  }

  test('createTask persists and returns task with sort order', () async {
    final created = await repository.createTask(
      buildTask(id: '1', title: 'First task'),
    );

    expect(created.sortOrder, 0);

    final tasks = await repository.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'First task');
  });

  test('updateTask marks completion with timestamp', () async {
    final task = await repository.createTask(
      buildTask(id: '1', title: 'Complete me'),
    );

    final completedAt = DateTime(2026, 6, 29, 10);
    final updated = await repository.updateTask(
      task.copyWith(isCompleted: true, completedAt: () => completedAt),
    );

    expect(updated.isCompleted, isTrue);
    expect(updated.completedAt, completedAt);
  });

  test('deleteTask removes task from storage', () async {
    await repository.createTask(buildTask(id: '1', title: 'Delete me'));
    await repository.deleteTask('1');

    final tasks = await repository.getTasks();
    expect(tasks, isEmpty);
  });

  test('reorderTasks updates persisted order', () async {
    await repository.createTask(buildTask(id: '1', title: 'A', sortOrder: 0));
    await repository.createTask(buildTask(id: '2', title: 'B', sortOrder: 1));
    await repository.createTask(buildTask(id: '3', title: 'C', sortOrder: 2));

    await repository.reorderTasks(['3', '1', '2']);

    final tasks = await repository.getTasks();
    expect(tasks.map((t) => t.id).toList(), ['3', '1', '2']);
  });

  test('getTasks filters by category and status', () async {
    await repository.createTask(
      buildTask(id: '1', title: 'Work pending', category: 'Work'),
    );
    await repository.createTask(
      buildTask(
        id: '2',
        title: 'Work done',
        category: 'Work',
        isCompleted: true,
        completedAt: DateTime(2026, 6, 29),
      ),
    );
    await repository.createTask(
      buildTask(id: '3', title: 'Personal', category: 'Personal'),
    );

    final filtered = await repository.getTasks(
      filter: const TaskFilter(
        category: 'Work',
        status: TaskStatusFilter.pending,
      ),
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.title, 'Work pending');
  });

  test('getTasks filters by search query', () async {
    await repository.createTask(buildTask(id: '1', title: 'Buy groceries'));
    await repository.createTask(buildTask(id: '2', title: 'Team sync'));

    final filtered = await repository.getTasks(
      filter: const TaskFilter(searchQuery: 'grocer'),
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.title, 'Buy groceries');
  });

  test('getTodayCompletionProgress uses completed vs total tasks', () async {
    await repository.createTask(
      buildTask(
        id: '1',
        title: 'Done',
        isCompleted: true,
        completedAt: DateTime(2026, 6, 29),
      ),
    );
    await repository.createTask(
      buildTask(
        id: '2',
        title: 'Pending',
      ),
    );

    final progress = await repository.getTodayCompletionProgress();
    expect(progress, closeTo(0.5, 0.001));
  });
}
