import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* =========================
   UI ENHANCEMENT: SETTINGS PROVIDER
   State management for app-wide accessibility preferences
   
   Manages:
   - Theme mode (dark/light)
   - High contrast mode
   - Text scale factor (0.8x - 1.5x)
   - Auto-lock inactivity timeout
   
   All settings persist to local storage using shared_preferences
   and are loaded automatically on app startup
   ========================= */

/// Settings provider to manage app-wide preferences
/// Handles theme mode, high contrast, text scaling, and auto-lock timeout
class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';
  static const String _textScaleKey = 'text_scale';
  static const String _autoLockTimeoutKey = 'auto_lock_timeout_minutes';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _highContrast = false;
  double _textScale = 1.0;
  int _autoLockTimeoutMinutes =
      1; // Default: 1 minute (for testing), change to 5 for production

  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  double get textScale => _textScale;
  int get autoLockTimeoutMinutes => _autoLockTimeoutMinutes;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  /// Load settings from persistent storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode - handle both int and potential string values
      final themeModeValue = prefs.get(_themeModeKey);
      int themeModeIndex;
      if (themeModeValue is int) {
        themeModeIndex = themeModeValue;
      } else if (themeModeValue is String) {
        themeModeIndex = int.tryParse(themeModeValue) ?? ThemeMode.dark.index;
      } else {
        themeModeIndex = ThemeMode.dark.index;
      }
      _themeMode = ThemeMode.values[themeModeIndex];

      // Load high contrast
      _highContrast = prefs.getBool(_highContrastKey) ?? false;

      // Load text scale
      _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;

      // Load auto-lock timeout (in minutes)
      final savedTimeout = prefs.getInt(_autoLockTimeoutKey);
      if (savedTimeout != null) {
        _autoLockTimeoutMinutes = savedTimeout;
      }
      // If no saved value, use default (1) - ensure it's persisted
      await prefs.setInt(_autoLockTimeoutKey, _autoLockTimeoutMinutes);
      debugPrint(
          '[SettingsProvider] Auto-lock timeout initialized: $_autoLockTimeoutMinutes minutes');

      notifyListeners();
    } catch (e) {
      // If loading fails, use defaults
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveThemeMode();
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemeMode();
      notifyListeners();
    }
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    _highContrast = !_highContrast;
    await _saveHighContrast();
    notifyListeners();
  }

  /// Set high contrast mode
  Future<void> setHighContrast(bool value) async {
    if (_highContrast != value) {
      _highContrast = value;
      await _saveHighContrast();
      notifyListeners();
    }
  }

  /// Set text scale factor (0.8 to 1.5)
  Future<void> setTextScale(double scale) async {
    final clampedScale = scale.clamp(0.8, 1.5);
    if (_textScale != clampedScale) {
      _textScale = clampedScale;
      await _saveTextScale();
      notifyListeners();
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.dark;
    _highContrast = false;
    _textScale = 1.0;
    _autoLockTimeoutMinutes = 5;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  /// Set auto-lock timeout in minutes (1-60)
  Future<void> setAutoLockTimeout(int minutes) async {
    final clampedMinutes = minutes.clamp(1, 60);
    if (_autoLockTimeoutMinutes != clampedMinutes) {
      _autoLockTimeoutMinutes = clampedMinutes;
      await _saveAutoLockTimeout();
      notifyListeners();
    }
  }

  /// Get auto-lock timeout as Duration
  Duration get autoLockTimeout => Duration(minutes: _autoLockTimeoutMinutes);

  // Private save methods
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }

  Future<void> _saveHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, _highContrast);
  }

  Future<void> _saveTextScale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, _textScale);
  }

  Future<void> _saveAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockTimeoutKey, _autoLockTimeoutMinutes);
  }
}
