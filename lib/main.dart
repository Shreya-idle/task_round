import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/task_local_datasource.dart';
import 'presentation/providers/settings_providers.dart';

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
          () => ThemeNotifier(initialTheme),
        ),
        filterProvider.overrideWith(
          () => FilterNotifier(savedFilter),
        ),
      ],
      child: const TaskManagerApp(),
    ),
  );
}
