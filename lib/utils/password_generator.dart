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

    // Build character set and ensure at least one from each enabled category
    final rnd = Random.secure();
    final requiredChars = <String>[];
    String allChars = '';

    // Add at least one character from each enabled category
    if (useLower) {
      allChars += _lower;
      requiredChars.add(_lower[rnd.nextInt(_lower.length)]);
    }
    if (useUpper) {
      allChars += _upper;
      requiredChars.add(_upper[rnd.nextInt(_upper.length)]);
    }
    if (useNumbers) {
      allChars += _numbers;
      requiredChars.add(_numbers[rnd.nextInt(_numbers.length)]);
    }
    if (useSymbols) {
      allChars += _symbols;
      requiredChars.add(_symbols[rnd.nextInt(_symbols.length)]);
    }

    if (allChars.isEmpty) return '';

    // If requested length is less than required characters,
    // randomly select subset of required characters
    if (length < requiredChars.length) {
      requiredChars.shuffle(rnd);
      return requiredChars.sublist(0, length).join();
    }

    // Build password with required characters + random fill
    final password = <String>[...requiredChars];

    // Fill the rest of the password length with random characters
    while (password.length < length) {
      password.add(allChars[rnd.nextInt(allChars.length)]);
    }

    // Shuffle to avoid predictable pattern (always having required chars at start)
    password.shuffle(rnd);

    return password.join();
  }
}
