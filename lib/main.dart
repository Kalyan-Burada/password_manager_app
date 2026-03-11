import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// UI ENHANCEMENT: Provider for state management of settings
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'services/auth_service.dart';
import 'services/log_service.dart';
import 'services/inactivity_service.dart';
import 'widgets/app_hero_title.dart';
import 'widgets/backup_dialog.dart';
import 'widgets/import_dialog.dart';
import 'docs_page.dart';
// UI ENHANCEMENT: New settings page for accessibility controls
import 'pages/settings_page.dart';
import 'pages/locked_vault_page.dart';
// UI ENHANCEMENT: Settings provider for theme and accessibility preferences
import 'providers/settings_provider.dart';
// UI ENHANCEMENT: Comprehensive theme system with dark/light and high contrast modes
import 'theme/app_theme.dart';
import 'pages/log_page.dart';
import 'widgets/password_generator_dialog.dart';
import 'dart:async';

import 'dart:io';

/// DEV ONLY: HttpOverrides for trusting self-signed certificates during local development
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // DEV ONLY: Trust self-signed certificates for local development
  HttpOverrides.global = DevHttpOverrides();

  // UI ENHANCEMENT: Wrap app with ChangeNotifierProvider for settings state management
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

/* =========================
   APP ROOT
   ========================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // UI ENHANCEMENT: Consumer listens to settings changes for reactive theme updates
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Password Manager',
          debugShowCheckedModeBanner: false,
          // UI ENHANCEMENT: Dynamic theme mode based on user preference
          themeMode: settings.themeMode,
          // UI ENHANCEMENT: Light theme with optional high contrast
          theme: AppTheme.lightTheme(highContrast: settings.highContrast),
          // UI ENHANCEMENT: Dark theme with optional high contrast
          darkTheme: AppTheme.darkTheme(highContrast: settings.highContrast),
          builder: (context, child) {
            // UI ENHANCEMENT: Apply user-selected text scale factor (0.8x - 1.5x)
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: settings.textScale,
              ),
              child: child!,
            );
          },
          home: const StartPage(),
        );
      },
    );
  }
}

/* UI ENHANCEMENT: Start Page (Landing Page)
 * 
 * Purpose:
 * - App entry point for unauthenticated users
 * - Provides navigation to login or registration
 * - Displays app branding and tagline
 * 
 * Features:
 * - Theme toggle button for immediate accessibility
 * - Full-width buttons for easy touch targets
 * - Icon-enhanced buttons for visual clarity
 * - Responsive spacing based on screen height
 * - Consistent styling with rounded corners
 */

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _topAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween:
              AlignmentTween(begin: Alignment.topLeft, end: Alignment.topRight),
          weight: 1),
    ]).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _bottomAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: AlignmentTween(
              begin: Alignment.bottomRight, end: Alignment.bottomLeft),
          weight: 1),
    ]).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignment.value,
                end: _bottomAlignment.value,
                colors: isDark
                    ? [
                        const Color(0xFF0D0F14),
                        const Color(0xFF1A1030),
                        const Color(0xFF0D1520),
                      ]
                    : [
                        const Color(0xFFF0F2F8),
                        const Color(0xFFE8E0FF),
                        const Color(0xFFE0F0FF),
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Theme toggle top-right
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return IconButton(
                      icon: Icon(
                        settings.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                      onPressed: () => settings.toggleTheme(),
                      tooltip: settings.isDarkMode
                          ? 'Switch to light mode'
                          : 'Switch to dark mode',
                    );
                  },
                ),
              ),
              // Center content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero section
                      const AppHeroTitle(
                        title: 'SE 12',
                        subtitle: 'Your secrets. Locked. Local. Yours.',
                        icon: Icons.lock_rounded,
                      ),
                      const SizedBox(height: 56),
                      // Login button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: _AnimatedButton(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Login',
                                  style: TextStyle(fontSize: 17)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 17),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Register button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 650),
                        child: _AnimatedButton(
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Create Account',
                                  style: TextStyle(fontSize: 17)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterUsernamePage(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 17),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Security tagline
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.security_rounded,
                                size: 14, color: primary.withOpacity(0.7)),
                            const SizedBox(width: 6),
                            Text(
                              'end-to-end encrypted · zero knowledge',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF5A6282)
                                    : Colors.grey.shade500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
   ANIMATED BUTTON WRAPPER
   ========================= */

/// Wraps any button with a subtle scale press animation
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  const _AnimatedButton({required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/* =========================
   LOGIN PAGE
   ========================= */

/* UI ENHANCEMENT: Login Page
 * 
 * Purpose:
 * - Authenticates existing users with username/password
 * - Provides clear, user-friendly error messages
 * - Shows loading states during authentication
 * - Supports keyboard navigation (Tab/Enter)
 * 
 * Features:
 * - Theme toggle button in AppBar for accessibility
 * - Client-side validation before API calls
 * - Semantic labels for screen readers
 * - Disabled inputs during loading to prevent double-submission
 * - Styled error messages with icons for better visibility
 * 
 * Flow:
 * 1. User enters username (converted to lowercase, trimmed)
 * 2. User enters password (obscured text)
 * 3. Validation checks for empty fields
 * 4. Fetch auth salt to verify user exists
 * 5. Attempt login with credentials
 * 6. On success: Navigate to vault page
 * 7. On error: Display user-friendly error message
 */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String _error = '';

  /// Handles login authentication flow
  /// Validates inputs, calls auth service, and navigates on success
  void _showSecurityAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gpp_bad_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();
      final password = _passwordController.text;

      // UI ENHANCEMENT: Validation with user-friendly error messages
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Please enter both username and password');
      }

      final salt = await _authService.getAuthSalt(username);
      // UI ENHANCEMENT: Clear, helpful error message instead of technical exception
      if (salt == null)
        throw Exception('User not found. Please check your username.');

      // SECURITY FIX: Always verify password BEFORE checking MFA status
      // This prevents incorrect passwords from proceeding to MFA verification
      final token = await _authService.login(username, password);
      if (token == null)
        throw Exception('Incorrect password. Please try again.');

      // Check if MFA is enabled
      final mfaEnabled = await _authService.checkMfaStatus(username);

      if (!mounted) return;

      if (mfaEnabled) {
        // MFA is enabled - redirect to MFA verification page
        // Note: The temporary token will be replaced after MFA verification
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MfaVerifyPage(
              username: username,
              password: password,
            ),
          ),
        );
      } else {
        // Normal login without MFA - proceed to vault
        final vault = await _authService.getVault(token);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VaultPage(
              username: username,
              token: token,
              password: password,
              vaultResponse: vault,
            ),
          ),
        );
      }
    } catch (e) {
      if (e is RateLimitException) {
        if (!mounted) return;
        _showSecurityAlert(e.message);
      } else {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        // UI ENHANCEMENT: Theme toggle button for accessibility
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            const AppHeroTitle(
              title: 'Welcome Back',
              subtitle: 'Unlock your vault',
              icon: Icons.key_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            // Username field
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: Semantics(
                label: 'Username input field',
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_loading,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Password field
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 330),
              child: Semantics(
                label: 'Password input field',
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _login(),
                  enabled: !_loading,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.035),
            // Login button
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 460),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
            ),
            // Error message with animated entrance
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   REGISTER – STEP 1
   ========================= */

/* UI ENHANCEMENT: Registration Step 1 - Username Selection
 * 
 * Purpose:
 * - First step of two-step registration process
 * - Validates username availability before proceeding
 * - Prevents duplicate usernames
 * 
 * Features:
 * - Theme toggle for accessibility
 * - Real-time username availability check
 * - Lowercase normalization for consistency
 * - Clear error messages for taken usernames
 * - Keyboard navigation support (Enter to proceed)
 * 
 * Flow:
 * 1. User enters desired username
 * 2. Username is trimmed and converted to lowercase
 * 3. Check if username already exists via auth salt lookup
 * 4. If available: Navigate to password step
 * 5. If taken: Show error message
 */

class RegisterUsernamePage extends StatefulWidget {
  const RegisterUsernamePage({super.key});

  @override
  State<RegisterUsernamePage> createState() => _RegisterUsernamePageState();
}

class _RegisterUsernamePageState extends State<RegisterUsernamePage> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();

  bool _loading = false;
  String _error = '';

  /// Validates username and proceeds to password step
  Future<void> _next() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();

      if (username.isEmpty) {
        throw Exception('Please enter a username');
      }

      final salt = await _authService.getAuthSalt(username);
      if (salt != null)
        throw Exception('Username already taken. Please choose another.');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterPasswordPage(username: username),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            const AppHeroTitle(
              title: 'Create Account',
              subtitle: 'Choose a unique username',
              icon: Icons.person_add_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: Semantics(
                label: 'Username input field',
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Choose a username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _next(),
                  enabled: !_loading,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 350),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _next,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Next'),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   REGISTER – STEP 2
   ========================= */

/* UI ENHANCEMENT: Registration Step 2 - Password Creation
 * 
 * Purpose:
 * - Second and final step of registration
 * - Creates secure password for the account
 * - Enforces minimum security requirements
 * - Automatically logs in after successful registration
 * 
 * Features:
 * - Theme toggle for accessibility
 * - Password length validation (minimum 8 characters)
 * - Obscured password input for security
 * - Helper text showing requirements
 * - Automatic login and vault navigation on success
 * 
 * Security:
 * - Password is used for client-side encryption
 * - Never stored in plain text
 * - Used to derive encryption keys via PBKDF2
 * 
 * Flow:
 * 1. Display selected username (from step 1)
 * 2. User enters password (minimum 8 characters)
 * 3. Validate password length
 * 4. Register account with auth service
 * 5. Automatically log in with new credentials
 * 6. Navigate to vault page
 */

class RegisterPasswordPage extends StatefulWidget {
  final String username;

  const RegisterPasswordPage({super.key, required this.username});

  @override
  State<RegisterPasswordPage> createState() => _RegisterPasswordPageState();
}

class _RegisterPasswordPageState extends State<RegisterPasswordPage> {
  final _authService = AuthService();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String _error = '';
  String _passwordText = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordText = _passwordController.text);
    });
  }

  // Returns 0-4: 0=Weak … 4=Very Strong
  int _calcStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#%^&*(),.?":{}|<>~`_+=\[\]\\\/\-]'))) score++;
    return score.clamp(0, 4);
  }

  static const _strengthLabels = [
    'Weak',
    'Fair',
    'Good',
    'Strong',
    'Very Strong'
  ];
  static const _strengthColors = [
    Color(0xFFE74C3C),
    Color(0xFFE67E22),
    Color(0xFFF1C40F),
    Color(0xFF2ECC71),
    Color(0xFF00CEC9),
  ];

  List<String> _getMissingTips(String p) {
    final tips = <String>[];
    if (p.length < 8)
      tips.add('At least 8 characters');
    else if (p.length < 12) tips.add('12+ characters is even better');
    if (!p.contains(RegExp(r'[A-Z]')))
      tips.add('Add an uppercase letter (A-Z)');
    if (!p.contains(RegExp(r'[a-z]'))) tips.add('Add a lowercase letter (a-z)');
    if (!p.contains(RegExp(r'[0-9]'))) tips.add('Add a number (0-9)');
    if (!p.contains(RegExp(r'[!@#%^&*]'))) tips.add('Add a symbol (!@#...)');
    return tips;
  }

  /// Registers new account and automatically logs in
  void _showSecurityAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gpp_bad_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final password = _passwordController.text;

      if (password.isEmpty) {
        throw Exception('Please enter a password');
      }

      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters long');
      }

      await _authService.register(widget.username, password);

      final token = await _authService.login(widget.username, password);
      if (token == null)
        throw Exception(
            'Registration succeeded but login failed. Please try logging in.');

      final vault = await _authService.getVault(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultPage(
            username: widget.username,
            token: token,
            password: password,
            vaultResponse: vault,
          ),
        ),
      );
    } catch (e) {
      if (e is RateLimitException) {
        if (!mounted) return;
        _showSecurityAlert(e.message);
      } else {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            const AppHeroTitle(
              title: 'Set a Strong Password',
              subtitle: 'This protects everything',
              icon: Icons.shield_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            // Username chip
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 150),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 280),
              child: Semantics(
                label: 'Password input field',
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _register(),
                  enabled: !_loading,
                ),
              ),
            ),
            // ── Strength Meter ──────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _passwordText.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _PasswordStrengthMeter(
                        strength: _calcStrength(_passwordText),
                        label: _strengthLabels[_calcStrength(_passwordText)],
                        color: _strengthColors[_calcStrength(_passwordText)],
                        tips: _getMissingTips(_passwordText),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 410),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated password strength indicator widget.
/// Shows 5 coloured segments + a label + missing-criteria tips.
class _PasswordStrengthMeter extends StatelessWidget {
  final int strength; // 0–4
  final String label;
  final Color color;
  final List<String> tips;

  const _PasswordStrengthMeter({
    required this.strength,
    required this.label,
    required this.color,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 5-segment bar ───────────────────────────────────────
        Row(
          children: List.generate(5, (i) {
            final filled = i <= strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: 6,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled ? color : emptyColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // ── Label ───────────────────────────────────────────────
        Row(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              child: Text(label),
            ),
            const Spacer(),
            if (strength == 4)
              Row(children: [
                Icon(Icons.check_circle_rounded, color: color, size: 15),
                const SizedBox(width: 4),
                Text(
                  'Looks great!',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
          ],
        ),
        // ── Tips ────────────────────────────────────────────────
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_rounded,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

class VaultPage extends StatefulWidget {
  final String username;
  final String token;
  final String password;
  final Map<String, dynamic> vaultResponse;
  final AuthService authService;
  final LogService logService;
  final Duration clipboardClearDelay;

  VaultPage({
    super.key,
    required this.username,
    required this.token,
    required this.password,
    required this.vaultResponse,
    AuthService? authService,
    LogService? logService,
    Duration clipboardDelay = const Duration(seconds: 20),
  })  : authService = authService ?? AuthService(),
        logService = logService ?? LogService(),
        clipboardClearDelay = clipboardDelay;

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with WidgetsBindingObserver {
  late final AuthService _authService;
  late final LogService _logService;
  Map<String, Map<String, String>> _vaultItems = {};
  late TextEditingController _searchController;
  String _searchQuery = '';
  Set<String> _selectedCategories = {'All'};

  // SECURITY ENHANCEMENT: Auto-lock on inactivity
  late InactivityService _inactivityService;
  bool _isVaultLocked = false;
  late String _unlockedPassword; // Current password to use for unlocking

  final List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Banking',
    'Shopping',
    'Social Media',
    'Other',
  ];

  String _now() {
    final t = DateTime.now();
    return "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} "
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  // -------- SEARCH & FILTER FUNCTION --------
  Map<String, Map<String, String>> _getFilteredItems(
      Map<String, Map<String, String>> items) {
    var filtered = items;

    // Apply category filter
    if (!_selectedCategories.contains('All')) {
      filtered = filtered.entries.where((entry) {
        final category = entry.value['category'] ?? 'Other';
        return _selectedCategories.contains(category);
      }).fold<Map<String, Map<String, String>>>({}, (map, entry) {
        map[entry.key] = entry.value;
        return map;
      });
    }

    // Apply search filter
    if (_searchQuery.isEmpty) {
      return filtered;
    }

    final searchFiltered = <String, Map<String, String>>{};
    final query = _searchQuery.toLowerCase();

    filtered.forEach((key, value) {
      if (key.toLowerCase().contains(query)) {
        searchFiltered[key] = value;
      }
    });

    return searchFiltered;
  }

  // -------- SORT FUNCTION --------
  Map<String, Map<String, String>> _getSortedMap(
      Map<String, Map<String, String>> map) {
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return {for (var k in sortedKeys) k: map[k]!};
  }

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);

    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _authService = widget.authService;
    _logService = widget.logService;
    _logService.setUsername(widget.username);
    _unlockedPassword = widget.password;

    // SECURITY ENHANCEMENT: Initialize inactivity service
    _initializeInactivityService();

    _loadVault(widget.vaultResponse);
  }

  /// Initialize the inactivity service with auto-lock functionality
  void _initializeInactivityService() {
    // Get the auto-lock timeout from settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _inactivityService = InactivityService(
      inactivityTimeout: settings.autoLockTimeout,
    );

    _inactivityService.startMonitoring(
      onInactivityDetected: _lockVault,
    );
  }

  /// Lock the vault due to inactivity
  void _lockVault() {
    debugPrint(
        '[VaultPage] Lock vault called. Current state: _isVaultLocked=$_isVaultLocked');
    if (_isVaultLocked) {
      debugPrint('[VaultPage] Vault already locked, skipping');
      return; // Already locked
    }

    debugPrint('[VaultPage] Locking vault due to inactivity');
    setState(() {
      _isVaultLocked = true;
    });

    _logService.logAction('Vault auto-locked due to inactivity');
  }

  /// Unlock the vault with verified password
  void _unlockVault(String password) {
    setState(() {
      _isVaultLocked = false;
      _unlockedPassword = password;
    });

    // Reset inactivity timer when unlocking
    _inactivityService.resetInactivityTimer();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inactivityService.handleAppLifecycleChange(state);
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Stop inactivity monitoring
    _inactivityService.stopMonitoring();
    _inactivityService.dispose();

    _clipboardTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVault([Map<String, dynamic>? vaultData]) async {
    Map<String, dynamic> data;

    if (vaultData != null) {
      data = vaultData;
    } else {
      try {
        data = await _authService.getVault(widget.token);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to refresh vault: $e')),
          );
        }
        return;
      }
    }

    final blob = data['blob'];
    if (blob == null) return;

    final decrypted = await _authService.decryptVault(
      Map<String, dynamic>.from(blob),
      _unlockedPassword,
    );

    setState(() {
      // UI ENHANCEMENT: Backward compatibility - handle both old (String) and new (Map) vault formats
      _vaultItems = Map<String, Map<String, String>>.from(
        decrypted.map((k, v) {
          // Handle both old format (String) and new format (Map)
          if (v is String) {
            // Old format: just a password string - convert to new format
            return MapEntry(
              k,
              {
                "password": v,
                "updatedAt": _now(),
              },
            );
          } else if (v is Map) {
            // New format: Map with password and updatedAt
            return MapEntry(
              k,
              Map<String, String>.from(v),
            );
          } else {
            // Fallback for unexpected types
            return MapEntry(
              k,
              {
                "password": v.toString(),
                "updatedAt": _now(),
              },
            );
          }
        }),
      );
    });
  }

  Future<void> _saveVault() async {
    final encrypted =
        await _authService.encryptVault(_vaultItems, _unlockedPassword);
    await _authService.updateVault(widget.token, encrypted);

    // SECURITY ENHANCEMENT: Reset inactivity timer on vault save activity
    _inactivityService.resetInactivityTimer();
  }

  Future<void> _saveVaultSnapshot(
      Map<String, Map<String, String>> vaultSnapshot) async {
    final encrypted =
        await _authService.encryptVault(vaultSnapshot, _unlockedPassword);
    await _authService.updateVault(widget.token, encrypted);

    _inactivityService.resetInactivityTimer();
  }

  void _wipeTransientImportData(Map<String, Map<String, String>> importedData) {
    for (final credential in importedData.values) {
      credential.clear();
    }
    importedData.clear();
  }

  bool _isStrongPassword(String pass) {
    if (pass.length < 8) return false;

    final hasUpper = pass.contains(RegExp(r'[A-Z]'));
    final hasLower = pass.contains(RegExp(r'[a-z]'));
    final hasNumber = pass.contains(RegExp(r'[0-9]'));
    final hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUpper && hasLower && hasNumber && hasSpecial;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return Icons.work_rounded;
      case 'Personal':
        return Icons.person_rounded;
      case 'Banking':
        return Icons.account_balance_rounded;
      case 'Shopping':
        return Icons.shopping_cart_rounded;
      case 'Social Media':
        return Icons.share_rounded;
      case 'Other':
        return Icons.category_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return const Color(0xFF6C5CE7);
      case 'Personal':
        return const Color(0xFF00B894);
      case 'Banking':
        return const Color(0xFFFFC312);
      case 'Shopping':
        return const Color(0xFFFF6B6B);
      case 'Social Media':
        return const Color(0xFF48DBFB);
      case 'Other':
      default:
        return const Color(0xFFB0B8CC);
    }
  }

  void _addItem() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    late String selectedCategory = 'Personal';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                items: _categories
                    .where((cat) => cat != 'All')
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setDialogState(() {
                      selectedCategory = category;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: valCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.password),
                    tooltip: 'Generate Strong Password',
                    onPressed: () async {
                      final generated = await showDialog<String>(
                        context: context,
                        builder: (_) => const PasswordGeneratorDialog(),
                      );
                      if (generated != null) {
                        valCtrl.text = generated;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = keyCtrl.text.trim();
                final pass = valCtrl.text.trim();

                if (title.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Title and Password cannot be empty')),
                  );
                  return;
                }

                if (_vaultItems.containsKey(title)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title already exists')),
                  );
                  return;
                }

                if (!_isStrongPassword(pass)) {
                  final wantGenerate = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Weak Password'),
                      content: const Text(
                          'This password is not strong enough. Would you like to generate a secure password?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Generate'),
                        ),
                      ],
                    ),
                  );

                  if (wantGenerate == true) {
                    final generated = await showDialog<String>(
                      context: context,
                      builder: (_) => const PasswordGeneratorDialog(),
                    );
                    if (generated != null) {
                      valCtrl.text = generated;
                    }
                  }
                  return;
                }

                setState(() {
                  _vaultItems[title] = {
                    "password": pass,
                    "category": selectedCategory,
                    "updatedAt": _now(),
                  };
                });

                Navigator.pop(context);
                await _saveVault();
                await _logService.logAction('Item added: $title');
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editItem(String key, String currentValue, String currentCategory) {
    final valCtrl = TextEditingController(text: currentValue);
    late String selectedCategory = currentCategory;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit $key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                items: _categories
                    .where((cat) => cat != 'All')
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setDialogState(() {
                      selectedCategory = category;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: valCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.password),
                    tooltip: 'Generate Strong Password',
                    onPressed: () async {
                      final generated = await showDialog<String>(
                        context: context,
                        builder: (_) => const PasswordGeneratorDialog(),
                      );
                      if (generated != null) {
                        valCtrl.text = generated;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPass = valCtrl.text.trim();

                if (newPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password cannot be empty')),
                  );
                  return;
                }

                if (!_isStrongPassword(newPass)) {
                  final wantGenerate = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Weak Password'),
                      content: const Text(
                          'This password is not strong enough. Would you like to generate a secure password?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Generate'),
                        ),
                      ],
                    ),
                  );

                  if (wantGenerate == true) {
                    final generated = await showDialog<String>(
                      context: context,
                      builder: (_) => const PasswordGeneratorDialog(),
                    );
                    if (generated != null) {
                      valCtrl.text = generated;
                    }
                  }
                  return;
                }

                setState(() {
                  _vaultItems[key] = {
                    "password": newPass,
                    "category": selectedCategory,
                    "updatedAt": _now(),
                  };
                });

                Navigator.pop(context);
                await _saveVault();
                await _logService.logAction('Item edited: $key');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(String key) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$key"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              setState(() {
                _vaultItems.remove(key);
              });

              Navigator.pop(context); // close dialog
              await _saveVault();
              await _logService.logAction('Item deleted: $key');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// SECURITY ENHANCEMENT: Handle imported credentials
  /// Merges imported credentials with existing vault items
  Future<void> _handleImport(
      Map<String, Map<String, String>> importedData) async {
    if (importedData.isEmpty) return;

    final mergedVault = _vaultItems.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );

    final conflictingKeys =
        mergedVault.keys.toSet().intersection(importedData.keys.toSet());

    if (conflictingKeys.isNotEmpty) {
      // Show conflict resolution dialog
      final mergeChoice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Credential Conflicts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${conflictingKeys.length} credential(s) with the same name(s):',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    conflictingKeys.join(', '),
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('How do you want to proceed?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'skip'),
              child: const Text('Skip Duplicates'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'keepOld'),
              child: const Text('Keep Existing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'overwrite'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );

      if (mergeChoice == 'skip') {
        // Only add non-conflicting items
        for (final entry in importedData.entries) {
          if (!mergedVault.containsKey(entry.key)) {
            mergedVault[entry.key] = Map<String, String>.from(entry.value);
          }
        }
      } else if (mergeChoice == 'keepOld') {
        // Keep existing, only add new items
        for (final entry in importedData.entries) {
          if (!mergedVault.containsKey(entry.key)) {
            mergedVault[entry.key] = Map<String, String>.from(entry.value);
          }
        }
      } else if (mergeChoice == 'overwrite') {
        // Overwrite all
        for (final entry in importedData.entries) {
          mergedVault[entry.key] = Map<String, String>.from(entry.value);
        }
      } else {
        // Cancelled
        return;
      }
    } else {
      // No conflicts, add all
      for (final entry in importedData.entries) {
        mergedVault[entry.key] = Map<String, String>.from(entry.value);
      }
    }

    // Save the updated vault
    try {
      await _saveVaultSnapshot(mergedVault);
      if (!mounted) return;

      setState(() {
        _vaultItems = mergedVault;
      });

      await _logService.logAction(
        'Imported ${importedData.length} credential(s)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully imported ${importedData.length} credential(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _wipeTransientImportData(importedData);
    }
  }

  Timer? _clipboardTimer;

  void _copy(String text) {
    // Copy password
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );

    // Cancel previous timer if exists
    _clipboardTimer?.cancel();

    // Start 20-second timer
    _clipboardTimer = Timer(widget.clipboardClearDelay, () async {
      await Clipboard.setData(const ClipboardData(text: ''));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard cleared automatically')),
      );
    });
  }

  /// SECURITY ENHANCEMENT: Copy credential with authorization
  /// Requires password verification before copying to prevent unauthorized access
  Future<void> _copyWithAuthorization(
      String credentialValue, String credentialName) async {
    final passwordController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Authorize Access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your password to copy this credential.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Authorize'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      final enteredPassword = passwordController.text;

      // Verify password matches
      if (enteredPassword != _unlockedPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect password'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Password verified - copy the credential
      _copy(credentialValue);

      // Log the copy action for audit trail
      await _logService.logAction(
        'Credential copied: $credentialName',
      );
    } finally {
      // Dispose controller after the current frame completes to avoid
      // issues with widget rebuilds in tests (tester.pump/pumpAndSettle)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        passwordController.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // SECURITY ENHANCEMENT: Show locked screen if vault is locked
    if (_isVaultLocked) {
      return LockedVaultPage(
        username: widget.username,
        token: widget.token,
        password: widget.password,
        onUnlock: _unlockVault,
        onLogout: () {
          // Logout and return to login screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StartPage()),
            (_) => false,
          );
        },
      );
    }

    final sortedItems = _getSortedMap(_vaultItems);
    final filteredItems = _getFilteredItems(sortedItems);

    // SECURITY ENHANCEMENT: Wrap UI in Listener to detect user activity (pointer events)
    return Listener(
      onPointerDown: (_) {
        debugPrint('[VaultPage] Pointer down detected');
        _inactivityService.resetInactivityTimer();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text(
            'Your Vault',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          actions: [
            // UI ENHANCEMENT: Log of Action button
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Log of Action',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LogPage(token: widget.token)),
                );
              },
            ),
            // UI ENHANCEMENT: Settings button for accessibility controls
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.backup),
              tooltip: 'Encrypted Backups',
              onPressed: () async {
                final restored = await showDialog<bool>(
                  context: context,
                  builder: (_) => BackupManagerDialog(
                    token: widget.token,
                    authService: _authService,
                  ),
                );

                if (restored == true) {
                  _loadVault();
                }
              },
            ),
            // SECURITY ENHANCEMENT: Import credentials from other password managers
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Import Credentials',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ImportCredentialsDialog(
                    onImport: _handleImport,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.security),
              tooltip: 'Security & MFA Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MfaSettingsPage(
                      username: widget.username,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Security Documentation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentationPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                // Background cleanup
                widget.authService.logout(widget.token);
                _logService.clearLogs();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const StartPage()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
        body: sortedItems.isEmpty
            ? const Center(child: Text('Your vault is empty'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search credentials...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategories.contains(category),
                            onSelected: (selected) {
                              setState(() {
                                if (category == 'All') {
                                  // 'All' is a special case - selection/deselection toggles between just 'All' and other categories
                                  if (selected) {
                                    _selectedCategories = {'All'};
                                  } else {
                                    // Don't allow deselecting all
                                    _selectedCategories = {'All'};
                                  }
                                } else {
                                  if (selected) {
                                    // If adding a category, ensure 'All' is not selected
                                    _selectedCategories.remove('All');
                                    _selectedCategories.add(category);
                                  } else {
                                    // If removing a category and no categories are left, default to 'All'
                                    _selectedCategories.remove(category);
                                    if (_selectedCategories.isEmpty) {
                                      _selectedCategories.add('All');
                                    }
                                  }
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'Your vault is empty'
                                  : 'No credentials found',
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                              bottom: 88,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final entry =
                                  filteredItems.entries.elementAt(index);
                              final category =
                                  entry.value['category'] ?? 'Other';
                              final categoryColor = _getCategoryColor(category);
                              return FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                delay: Duration(milliseconds: 60 * (index % 8)),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Card(
                                    child: ListTile(
                                      // Leading: colored category avatar
                                      leading: Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: categoryColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(category),
                                          color: categoryColor,
                                          size: 22,
                                        ),
                                      ),
                                      // Title: row with name + category chip
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: categoryColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: categoryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Subtitle: timestamp
                                      subtitle: Text(
                                        'Updated: ${entry.value["updatedAt"] ?? ""}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      // Trailing: action icons
                                      // Use base icon names so widget tests can find them
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 20),
                                            tooltip: 'Copy password',
                                            onPressed: () => _copyWithAuthorization(
                                              entry.value['password']!,
                                              entry.key,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            tooltip: 'Edit',
                                            onPressed: () => _editItem(
                                              entry.key,
                                              entry.value['password']!,
                                              category,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red.withOpacity(0.7),
                                            ),
                                            tooltip: 'Delete',
                                            onPressed: () => _deleteItem(entry.key),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addItem,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/* =========================
   MFA VERIFY PAGE (FOR LOGIN)
   ========================= */

class MfaVerifyPage extends StatefulWidget {
  final String username;
  final String password;

  const MfaVerifyPage({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<MfaVerifyPage> createState() => _MfaVerifyPageState();
}

class _MfaVerifyPageState extends State<MfaVerifyPage> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _verify() async {
    if (_codeController.text.length != 6) {
      setState(() => _error = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final token = await _authService.loginWithMfa(
        widget.username,
        widget.password,
        _codeController.text,
      );

      if (token == null) throw Exception('Invalid MFA code');

      final vault = await _authService.getVault(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultPage(
            username: widget.username,
            token: token,
            password: widget.password,
            vaultResponse: vault,
          ),
        ),
      );
    } catch (e) {
      if (e is RateLimitException) {
        if (!mounted) return;
        _showSecurityAlert(e.message);
      } else {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSecurityAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gpp_bad_rounded, color: Colors.red),
            SizedBox(width: 24),
            Text('Security Alert'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter MFA Code')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const AppHeroTitle(
              title: 'Two-Factor Authentication',
              subtitle: 'Enter the code from your authenticator app',
              icon: Icons.shield_rounded,
            ),
            const SizedBox(height: 40),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: '6-Digit Code',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_clock_rounded),
                ),
                onSubmitted: (_) => _verify(),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 350),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _error.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FadeInDown(
                        animate: _error.isNotEmpty,
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   MFA SETTINGS PAGE
   ========================= */

class MfaSettingsPage extends StatefulWidget {
  final String username;
  final String token;

  const MfaSettingsPage({
    super.key,
    required this.username,
    required this.token,
  });

  @override
  State<MfaSettingsPage> createState() => _MfaSettingsPageState();
}

class _MfaSettingsPageState extends State<MfaSettingsPage> {
  final _authService = AuthService();
  bool _loading = true;
  bool _mfaEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  /// Check if MFA is currently enabled for this user
  Future<void> _checkStatus() async {
    try {
      final enabled = await _authService.checkMfaStatus(widget.username);
      setState(() {
        _mfaEnabled = enabled;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _mfaEnabled = false;
        _loading = false;
      });
    }
  }

  /// Setup MFA - with warning if already enabled
  Future<void> _setupMfa() async {
    // Show warning if MFA is already enabled
    if (_mfaEnabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('⚠️ Replace MFA Setup?'),
          content: const Text(
            'You already have MFA enabled. Setting up again will:\n\n'
            '• Invalidate your current QR code/secret\n'
            '• Make your old backup codes useless\n'
            '• Temporarily disable MFA until you verify the new code\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Replace MFA'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Navigate to setup page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MfaSetupPage(
          username: widget.username,
          token: widget.token,
        ),
      ),
    );

    // Refresh status after setup (in case user completed it)
    if (result == true || mounted) {
      _checkStatus();
    }
  }

  /// Disable MFA with confirmation
  Future<void> _disableMfa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disable MFA'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? '
          'This will make your account less secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final success = await _authService.disableMfa(widget.token);
      if (!success) throw Exception('Failed to disable MFA');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MFA disabled successfully')),
      );

      // Refresh status
      _checkStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MFA Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current Status Card
                Card(
                  color: _mfaEnabled
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  child: ListTile(
                    leading: Icon(
                      _mfaEnabled ? Icons.check_circle : Icons.warning_rounded,
                      color: _mfaEnabled ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      _mfaEnabled ? 'MFA Enabled' : 'MFA Disabled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _mfaEnabled ? Colors.green : Colors.orange,
                      ),
                    ),
                    subtitle: Text(
                      _mfaEnabled
                          ? 'Your account is protected with two-factor authentication'
                          : 'Your account is not protected with MFA',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Setup/Re-setup Button
                if (!_mfaEnabled) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.security, color: Colors.blue),
                      title: const Text('Setup Two-Factor Authentication'),
                      subtitle: const Text(
                        'Add an extra layer of security to your account',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _setupMfa,
                    ),
                  ),
                ] else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.orange),
                      title: const Text('Re-setup MFA'),
                      subtitle: const Text(
                        'Replace your current MFA with a new one',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _setupMfa,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.remove_circle, color: Colors.red),
                      title: const Text('Disable MFA'),
                      subtitle: const Text(
                        'Turn off two-factor authentication',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _disableMfa,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Info Card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About MFA'),
                    subtitle: const Text(
                      'Use apps like Google Authenticator, Authy, '
                      'or Microsoft Authenticator',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* =========================
   MFA SETUP PAGE
   ========================= */

class MfaSetupPage extends StatefulWidget {
  final String username;
  final String token;

  const MfaSetupPage({
    super.key,
    required this.username,
    required this.token,
  });

  @override
  State<MfaSetupPage> createState() => _MfaSetupPageState();
}

class _MfaSetupPageState extends State<MfaSetupPage> {
  final _authService = AuthService();
  final _codeController = TextEditingController();

  bool _loading = true;
  bool _verifying = false;
  String? _qrCode;
  String? _secret;
  List<String>? _backupCodes;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final data = await _authService.setupMfa(widget.token);

      setState(() {
        _qrCode = data['qr_code'];
        _secret = data['secret'];
        _backupCodes = List<String>.from(data['backup_codes'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verify() async {
    if (_codeController.text.length != 6) {
      setState(() => _error = 'Please enter a 6-digit code');
      return;
    }

    setState(() {
      _verifying = true;
      _error = '';
    });

    try {
      // Actually verify the code with the server
      final success = await _authService.verifyMfa(
        widget.username,
        _codeController.text,
      );

      if (!success) {
        throw Exception('Invalid code. Please try again.');
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('MFA Enabled!'),
          content: const Text(
            'Two-factor authentication has been enabled successfully. '
            'Make sure you\'ve saved your backup codes!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close setup page
                Navigator.pop(context); // Close settings page
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Setup MFA')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty && _qrCode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Setup MFA')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error, style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Setup MFA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Step 1: Scan QR Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Open your authenticator app and scan this QR code:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_qrCode != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.memory(
                    Uri.parse(_qrCode!).data!.contentAsBytes(),
                    width: 250,
                    height: 250,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_secret != null) ...[
              const Text(
                'Or enter this key manually:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _secret!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Step 2: Save Backup Codes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Save these codes in a secure place. You can use them to access your account if you lose your device.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_backupCodes != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: _backupCodes!.map((code) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 32),
            const Text(
              'Step 3: Verify Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the 6-digit code from your authenticator app:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: '6-Digit Code',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifying ? null : _verify,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _verifying
                  ? const CircularProgressIndicator()
                  : const Text('Verify and Enable MFA'),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
