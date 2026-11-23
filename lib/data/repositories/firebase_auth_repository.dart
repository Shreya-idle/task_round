import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/auth_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_mapUser);

  @override
  Future<AppUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    } on FirebaseException catch (error) {
      throw AuthException(
        'Authentication is temporarily unavailable. Please try again.',
        code: error.code,
      );
    }
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    } on FirebaseException catch (error) {
      throw AuthException(
        'Authentication is temporarily unavailable. Please try again.',
        code: error.code,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  static AppUser? _mapUser(User? user) =>
      user == null ? null : AppUser(id: user.uid, email: user.email ?? '');

  static AppUser _requireUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw const AuthException(
        'Authentication succeeded but no user session was returned.',
      );
    }
    return mapped;
  }

  static AuthException mapFirebaseAuthException(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a stronger password with at least 6 characters.',
      'email-already-in-use' =>
        'An account already exists for this email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'The email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' =>
        'Too many attempts. Wait a moment before trying again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'operation-not-allowed' =>
        'Email and password sign-in is not enabled for this app.',
      _ => 'Authentication failed. Please try again.',
    };
    return AuthException(message, code: error.code);
  }
}
