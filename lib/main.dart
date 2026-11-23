import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/task_local_datasource.dart';
import 'presentation/providers/settings_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.initialize();

    final dir = await getApplicationDocumentsDirectory();
    final dataSource = await TaskLocalDataSource.create(dir.path);
    final isDark = await dataSource.getIsDarkMode();
    final savedFilter = await dataSource.getSavedFilter();
    final initialTheme = isDark ? ThemeMode.dark : ThemeMode.light;

    runApp(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(() => ThemeNotifier(initialTheme)),
          filterProvider.overrideWith(() => FilterNotifier(savedFilter)),
        ],
        child: const TaskManagerApp(),
      ),
    );
  } catch (error) {
    runApp(StartupErrorApp(error: error));
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'The app could not start',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check the Firebase configuration and restart the app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
