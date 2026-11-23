import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_pro/domain/entities/app_user.dart';
import 'package:task_manager_pro/presentation/pages/auth_gate.dart';
import 'package:task_manager_pro/presentation/providers/auth_providers.dart';

Widget buildSubject(Stream<AppUser?> stream) {
  return ProviderScope(
    overrides: [authStateProvider.overrideWith((ref) => stream)],
    child: const MaterialApp(home: AuthGate()),
  );
}

void main() {
  testWidgets('shows login page when signed out', (tester) async {
    await tester.pumpWidget(buildSubject(Stream.value(null)));
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('shows loading while auth state is unresolved', (tester) async {
    await tester.pumpWidget(buildSubject(const Stream.empty()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows retry state when auth stream fails', (tester) async {
    await tester.pumpWidget(buildSubject(Stream.error(Exception('failure'))));
    await tester.pump();

    expect(find.text('Could not check your session.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
