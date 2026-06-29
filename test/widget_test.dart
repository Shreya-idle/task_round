import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:task_manager_pro/app.dart';

void main() {
  testWidgets('App renders home title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TaskManagerApp(),
      ),
    );

    expect(find.text('Task Manager Pro'), findsOneWidget);
  });
}
