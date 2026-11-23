import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:task_manager_pro/app.dart';
import 'package:task_manager_pro/domain/entities/app_user.dart';
import 'package:task_manager_pro/presentation/providers/auth_providers.dart';

void main() {
  testWidgets('App renders home title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(id: 'test-user', email: 'test@example.com'),
            ),
          ),
        ],
        child: const TaskManagerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Task Manager Pro'), findsOneWidget);
  });
}
