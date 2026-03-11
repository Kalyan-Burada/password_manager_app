import 'package:flutter/material.dart';

/* =========================
   PREMIUM THEME SYSTEM
   Modern glassmorphism aesthetic with smooth transitions
   ========================= */

class AppTheme {
  // Color palette
  static const Color primaryBlue = Color(0xFF6C5CE7);
  static const Color accentGreen = Color(0xFF00B894);
  static const Color accentPurple = Color(0xFF9B59B6);
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkCard = Color(0xFF181B23);
  static const Color darkCardBorder = Color(0xFF2A2D3A);
  static const Color lightBg = Color(0xFFF0F2F8);
  static const Color lightCard = Color(0xFFFFFFFF);

  // High contrast colors
  static const Color hcDarkBg = Color(0xFF000000);
  static const Color hcDarkCard = Color(0xFF1A1A1A);
  static const Color hcLightBg = Color(0xFFFFFFFF);
  static const Color hcLightCard = Color(0xFFF0F0F0);

  /// Dark theme with premium glassmorphism aesthetic
  static ThemeData darkTheme({bool highContrast = false}) {
    final bgColor = highContrast ? hcDarkBg : darkBg;
    final cardColor = highContrast ? hcDarkCard : darkCard;
    final textColor = highContrast ? Colors.white : const Color(0xFFE8E8E8);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        secondary: accentGreen,
        surface: cardColor,
        background: bgColor,
      ),
      scaffoldBackgroundColor: bgColor,

      // Smooth zoom page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFB0B8CC)),
      ),

      // Card theme with refined shadow
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: highContrast
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide(color: darkCardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shadowColor: Colors.black.withOpacity(0.4),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrast ? hcDarkCard : const Color(0xFF1E222E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.white, width: 2)
              : const BorderSide(color: Color(0xFF2A2D3A), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.white70, width: 2)
              : const BorderSide(color: Color(0xFF2A2D3A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryBlue,
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: TextStyle(
          color: highContrast ? Colors.white : const Color(0xFF8892A4),
          fontSize: 15,
        ),
        hintStyle: const TextStyle(color: Color(0xFF555E72)),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: highContrast ? 0 : 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: primaryBlue.withOpacity(0.5),
            width: highContrast ? 3 : 1.5,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFB0B8CC),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: highContrast ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip theme for category filters
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E222E),
        selectedColor: primaryBlue.withOpacity(0.25),
        side: const BorderSide(color: Color(0xFF2A2D3A), width: 1),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0B8CC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF252833),
        contentTextStyle: TextStyle(color: textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(
            color: textColor, fontWeight: FontWeight.w800, fontSize: 32),
        headlineMedium: TextStyle(
            color: textColor, fontWeight: FontWeight.w700, fontSize: 26),
        headlineSmall: TextStyle(
            color: textColor, fontWeight: FontWeight.w600, fontSize: 22),
        titleLarge: TextStyle(
            color: textColor, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(
            color: textColor, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(
            color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textColor, fontSize: 14),
        bodySmall: TextStyle(color: const Color(0xFF8892A4), fontSize: 12),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: textColor),
      ),
    );
  }

  /// Light theme with clean, premium aesthetic
  static ThemeData lightTheme({bool highContrast = false}) {
    final bgColor = highContrast ? hcLightBg : lightBg;
    final cardColor = highContrast ? hcLightCard : lightCard;
    final textColor = highContrast ? Colors.black : const Color(0xFF1A1D2E);

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentGreen,
        surface: cardColor,
        background: bgColor,
      ),
      scaffoldBackgroundColor: bgColor,

      // Smooth zoom page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textColor.withOpacity(0.7)),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: highContrast
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shadowColor: Colors.black12,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrast ? hcLightCard : const Color(0xFFF7F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.black54, width: 2)
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryBlue,
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: TextStyle(
          color: highContrast ? Colors.black : Colors.grey.shade600,
          fontSize: 15,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: highContrast ? 0 : 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: primaryBlue.withOpacity(0.4),
            width: highContrast ? 3 : 1.5,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor.withOpacity(0.7),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: highContrast ? 0 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip theme for category filters
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryBlue.withOpacity(0.15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        labelStyle: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(
            color: textColor, fontWeight: FontWeight.w800, fontSize: 32),
        headlineMedium: TextStyle(
            color: textColor, fontWeight: FontWeight.w700, fontSize: 26),
        headlineSmall: TextStyle(
            color: textColor, fontWeight: FontWeight.w600, fontSize: 22),
        titleLarge: TextStyle(
            color: textColor, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(
            color: textColor, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(
            color: textColor, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textColor, fontSize: 14),
        bodySmall: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: textColor),
      ),
    );
  }
}
