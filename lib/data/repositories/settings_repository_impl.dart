import '../../domain/entities/task_filter.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/task_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dataSource);

  final TaskLocalDataSource _dataSource;

  @override
  Future<bool> getIsDarkMode() => _dataSource.getIsDarkMode();

  @override
  Future<void> setIsDarkMode(bool value) => _dataSource.setIsDarkMode(value);

  @override
  Future<TaskFilter> getSavedFilter() => _dataSource.getSavedFilter();

  @override
  Future<void> saveFilter(TaskFilter filter) =>
      _dataSource.saveFilter(filter);
}
