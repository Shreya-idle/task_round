import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/auth_exception.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
);

final watchAuthStateUseCaseProvider = Provider<WatchAuthStateUseCase>(
  (ref) => WatchAuthStateUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(watchAuthStateUseCaseProvider)();
});

class AuthSubmitState {
  const AuthSubmitState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;
}

class AuthController extends Notifier<AuthSubmitState> {
  @override
  AuthSubmitState build() => const AuthSubmitState();

  Future<bool> login({required String email, required String password}) => _run(
    () => ref.read(loginUseCaseProvider)(email: email, password: password),
  );

  Future<bool> register({required String email, required String password}) =>
      _run(
        () =>
            ref.read(registerUseCaseProvider)(email: email, password: password),
      );

  Future<bool> logout() => _run(() => ref.read(logoutUseCaseProvider)());

  void clearError() {
    if (state.errorMessage != null) state = const AuthSubmitState();
  }

  Future<bool> _run(Future<Object?> Function() operation) async {
    if (state.isLoading) return false;
    state = const AuthSubmitState(isLoading: true);
    try {
      await operation();
      state = const AuthSubmitState();
      return true;
    } on AuthException catch (error) {
      state = AuthSubmitState(errorMessage: error.message);
      return false;
    } catch (_) {
      state = const AuthSubmitState(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthSubmitState>(AuthController.new);
