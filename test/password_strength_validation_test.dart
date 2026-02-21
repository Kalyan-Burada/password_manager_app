import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager_app/utils/password_generator.dart';

void main() {
  bool isStrongPassword(String pass) {
    if (pass.length < 8) return false;
    final hasUpper = pass.contains(RegExp(r'[A-Z]'));
    final hasLower = pass.contains(RegExp(r'[a-z]'));
    final hasNumber = pass.contains(RegExp(r'[0-9]'));
    final hasSpecial = pass.contains(RegExp(r'[!@#\$%^&*(),.?\":{}|<>]'));
    return hasUpper && hasLower && hasNumber && hasSpecial;
  }

  test('Generated passwords always pass strength check', () {
    // Generate 100 passwords with default settings
    for (int i = 0; i < 100; i++) {
      final password = PasswordGenerator.generate();
      expect(isStrongPassword(password), true, 
        reason: 'Generated password "" failed strength check');
    }
  });
  
  test('Generated 16-char passwords with all types enabled pass strength check', () {
    for (int i = 0; i < 50; i++) {
      final password = PasswordGenerator.generate(
        length: 16,
        useLower: true,
        useUpper: true,
        useNumbers: true,
        useSymbols: true,
      );
      expect(isStrongPassword(password), true,
        reason: 'Generated password "" failed strength check');
    }
  });
}
