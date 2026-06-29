import '../entities/task_filter.dart';

abstract class SettingsRepository {
  Future<bool> getIsDarkMode();

  Future<void> setIsDarkMode(bool value);

  Future<TaskFilter> getSavedFilter();

  Future<void> saveFilter(TaskFilter filter);
}
