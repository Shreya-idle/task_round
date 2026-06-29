import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/task_local_datasource.dart';
import 'domain/entities/task_filter.dart';
import 'presentation/providers/settings_providers.dart';

class _BootstrapThemeNotifier extends ThemeNotifier {
  _BootstrapThemeNotifier(this._initialMode);
  final ThemeMode _initialMode;

  @override
  ThemeMode build() => _initialMode;
}

class _BootstrapFilterNotifier extends FilterNotifier {
  _BootstrapFilterNotifier(this._initialFilter);
  final TaskFilter _initialFilter;

  @override
  TaskFilter build() => _initialFilter;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

  final dir = await getApplicationDocumentsDirectory();
  final dataSource = await TaskLocalDataSource.create(dir.path);
  final isDark = await dataSource.getIsDarkMode();
  final savedFilter = await dataSource.getSavedFilter();
  final initialTheme = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          () => _BootstrapThemeNotifier(initialTheme),
        ),
        filterProvider.overrideWith(
          () => _BootstrapFilterNotifier(savedFilter),
        ),
      ],
      child: const TaskManagerApp(),
    ),
  );
}
