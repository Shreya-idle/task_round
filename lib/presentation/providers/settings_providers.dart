import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task_filter.dart';
import 'dependency_providers.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> load() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    final isDark = await repo.getIsDarkMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await repo.setIsDarkMode(next == ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class FilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  Future<void> load() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    state = await repo.getSavedFilter();
  }

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
