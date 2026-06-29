import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task_filter.dart';
import 'dependency_providers.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  ThemeNotifier([ThemeMode? initial]) : _initial = initial;

  final ThemeMode? _initial;

  @override
  ThemeMode build() => _initial ?? ThemeMode.light;

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;

    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      await repo.setIsDarkMode(next == ThemeMode.dark);
    } catch (_) {
      // Keep UI responsive even if persistence fails momentarily.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class FilterNotifier extends Notifier<TaskFilter> {
  FilterNotifier([TaskFilter? initial]) : _initial = initial;

  final TaskFilter? _initial;

  @override
  TaskFilter build() => _initial ?? const TaskFilter();

  Future<void> _persist() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.saveFilter(state);
  }

  void setCategory(String? category) {
    state = state.copyWith(category: () => category);
    _persist();
  }

  void setStatus(TaskStatusFilter status) {
    state = state.copyWith(status: status);
    _persist();
  }

  void setDueDateFilter(DueDateFilter filter) {
    state = state.copyWith(dueDateFilter: filter);
    _persist();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _persist();
  }

  void clearFilters() {
    state = const TaskFilter();
    _persist();
  }
}

final filterProvider = NotifierProvider<FilterNotifier, TaskFilter>(
  FilterNotifier.new,
);
