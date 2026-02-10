import 'dart:math';

class PasswordGenerator {
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*(),.?":{}|<>';

  static String generate({
    int length = 16,
    bool useLower = true,
    bool useUpper = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    if (length < 1) length = 1;
    
    String chars = '';
    if (useLower) chars += _lower;
    if (useUpper) chars += _upper;
    if (useNumbers) chars += _numbers;
    if (useSymbols) chars += _symbols;

    if (chars.isEmpty) return '';

    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
