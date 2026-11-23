import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_pro/core/errors/auth_exception.dart';
import 'package:task_manager_pro/data/repositories/firebase_auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth firebaseAuth;
  late FirebaseAuthRepository repository;

  setUp(() {
    firebaseAuth = MockFirebaseAuth();
    repository = FirebaseAuthRepository(firebaseAuth);
  });

  test('login maps Firebase user to domain user and trims email', () async {
    final credential = MockUserCredential();
    final user = MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => user.email).thenReturn('person@example.com');
    when(() => credential.user).thenReturn(user);
    when(
      () => firebaseAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);

    final result = await repository.login(
      email: ' person@example.com ',
      password: 'secret1',
    );

    expect(result.id, 'user-1');
    expect(result.email, 'person@example.com');
    verify(
      () => firebaseAuth.signInWithEmailAndPassword(
        email: 'person@example.com',
        password: 'secret1',
      ),
    ).called(1);
  });

  test('login maps invalid credentials to an understandable error', () async {
    when(
      () => firebaseAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    expect(
      () => repository.login(email: 'person@example.com', password: 'wrong1'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'The email or password is incorrect.',
        ),
      ),
    );
  });

  test('logout delegates to Firebase Auth', () async {
    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => firebaseAuth.signOut()).called(1);
  });
}
