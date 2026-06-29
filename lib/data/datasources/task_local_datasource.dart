import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/task_filter.dart';
import '../models/task_model.dart';

class TaskLocalDataSource {
  TaskLocalDataSource(this._db);

  final Database _db;

  static Future<TaskLocalDataSource> create(String dbPath) async {
    final db = await openDatabase(
      p.join(dbPath, AppConstants.dbName),
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            sort_order INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            due_date INTEGER,
            reminder_at INTEGER,
            completed_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return TaskLocalDataSource(db);
  }

  Future<List<TaskModel>> getAllTasks() async {
    final rows = await _db.query(
      'tasks',
      orderBy: 'sort_order ASC, created_at DESC',
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final rows = await _db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TaskModel.fromMap(rows.first);
  }

  Future<TaskModel> insertTask(TaskModel task) async {
    await _db.insert('tasks', task.toMap());
    return task;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    await _db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    return task;
  }

  Future<void> deleteTask(String id) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSortOrders(List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'tasks',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> getNextSortOrder() async {
    final result = await _db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM tasks',
    );
    final maxOrder = result.first['max_order'] as int?;
    return (maxOrder ?? -1) + 1;
  }

  Future<bool> getIsDarkMode() async {
    final rows = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['is_dark_mode'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['value'] == 'true';
  }

  Future<void> setIsDarkMode(bool value) async {
    await _db.insert(
      'settings',
      {'key': 'is_dark_mode', 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TaskFilter> getSavedFilter() async {
    final rows = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['task_filter'],
      limit: 1,
    );
    if (rows.isEmpty) return const TaskFilter();
    final json = jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
    return TaskFilter.fromJson(json);
  }

  Future<void> saveFilter(TaskFilter filter) async {
    await _db.insert(
      'settings',
      {'key': 'task_filter', 'value': jsonEncode(filter.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
