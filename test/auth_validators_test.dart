import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_pro/core/validation/auth_validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('requires a value', () {
      expect(AuthValidators.email(''), 'Email is required');
    });

    test('rejects malformed email', () {
      expect(AuthValidators.email('person@'), 'Enter a valid email address');
    });

    test('accepts and trims a valid email', () {
      expect(AuthValidators.email(' person@example.com '), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('requires a value', () {
      expect(AuthValidators.password(''), 'Password is required');
    });

    test('requires at least six characters', () {
      expect(
        AuthValidators.password('12345'),
        'Password must be at least 6 characters',
      );
    });

    test('accepts a valid password', () {
      expect(AuthValidators.password('123456'), isNull);
    });
  });

  group('AuthValidators.confirmation', () {
    test('rejects mismatched passwords', () {
      expect(
        AuthValidators.confirmation('different', 'password'),
        'Passwords do not match',
      );
    });

    test('accepts matching passwords', () {
      expect(AuthValidators.confirmation('password', 'password'), isNull);
    });
  });
}
