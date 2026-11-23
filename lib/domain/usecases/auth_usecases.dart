import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);
  final AuthRepository _repository;
  Stream<AppUser?> call() => _repository.authStateChanges();
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;
  Future<AppUser> call({required String email, required String password}) =>
      _repository.register(email: email.trim(), password: password);
}

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;
  Future<AppUser> call({required String email, required String password}) =>
      _repository.login(email: email.trim(), password: password);
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;
  Future<void> call() => _repository.logout();
}
