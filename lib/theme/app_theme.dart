import 'package:flutter/material.dart';

/* =========================
   UI ENHANCEMENT: COMPREHENSIVE THEME SYSTEM
   Modern, accessible themes with dark/light and high contrast modes
   
   Features:
   - Dark Theme: Sleek dark background with modern card design
   - Light Theme: Clean light background with subtle shadows
   - High Contrast: Enhanced contrast for accessibility (both modes)
   - Consistent styling: Rounded corners, proper elevation, smooth animations
   
   Color Palette:
   - Primary Blue: #6C5CE7 (vibrant purple-blue)
   - Accent Green: #00B894 (modern teal)
   - Dark BG: #0F1115, Light BG: #F5F6FA
   
   All themes use Material 3 design with comprehensive component theming
   ========================= */

/// Comprehensive theme configurations for the password manager app
/// Supports dark, light, and high contrast modes with sleek modern design
class AppTheme {
  // Color palette
  static const Color primaryBlue = Color(0xFF6C5CE7);
  static const Color accentGreen = Color(0xFF00B894);
  static const Color darkBg = Color(0xFF0F1115);
  static const Color darkCard = Color(0xFF1A1D24);
  static const Color lightBg = Color(0xFFF5F6FA);
  static const Color lightCard = Color(0xFFFFFFFF);

  // High contrast colors
  static const Color hcDarkBg = Color(0xFF000000);
  static const Color hcDarkCard = Color(0xFF1A1A1A);
  static const Color hcLightBg = Color(0xFFFFFFFF);
  static const Color hcLightCard = Color(0xFFF0F0F0);

  /// Dark theme with modern glassmorphism aesthetic
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
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      
      // Card theme with subtle elevation
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.white70, width: 2)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryBlue,
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: TextStyle(
          color: highContrast ? Colors.white : Colors.grey,
        ),
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
          elevation: highContrast ? 0 : 4,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            color: primaryBlue,
            width: highContrast ? 3 : 2,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
          foregroundColor: textColor,
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
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(color: textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textColor),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: textColor),
      ),
    );
  }

  /// Light theme with clean, modern aesthetic
  static ThemeData lightTheme({bool highContrast = false}) {
    final bgColor = highContrast ? hcLightBg : lightBg;
    final cardColor = highContrast ? hcLightCard : lightCard;
    final textColor = highContrast ? Colors.black : const Color(0xFF2D3436);

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
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: highContrast ? 0 : 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: highContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrast ? hcLightCard : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.black54, width: 2)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryBlue,
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: TextStyle(
          color: highContrast ? Colors.black : Colors.grey.shade700,
        ),
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
          elevation: highContrast ? 0 : 4,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            color: primaryBlue,
            width: highContrast ? 3 : 2,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
          foregroundColor: textColor,
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
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textColor),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: textColor),
      ),
    );
  }
}
