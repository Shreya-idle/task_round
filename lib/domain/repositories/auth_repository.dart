import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> register({required String email, required String password});

  Future<AppUser> login({required String email, required String password});

  Future<void> logout();
}
