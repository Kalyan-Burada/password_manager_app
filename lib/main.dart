import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// UI ENHANCEMENT: Provider for state management of settings
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'widgets/app_hero_title.dart';
import 'widgets/backup_dialog.dart';
import 'docs_page.dart';
// UI ENHANCEMENT: New settings page for accessibility controls
import 'pages/settings_page.dart';
// UI ENHANCEMENT: Settings provider for theme and accessibility preferences
import 'providers/settings_provider.dart';
// UI ENHANCEMENT: Comprehensive theme system with dark/light and high contrast modes
import 'theme/app_theme.dart';
import 'dart:async';

import 'dart:io';

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

// Development-only override to accept self-signed certificates
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
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

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // enables back arrow
        // UI ENHANCEMENT: Theme toggle button for accessibility
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App branding with icon and tagline
              const AppHeroTitle(
                title: 'SE 12',
                subtitle: 'Your secrets. Locked. Local. Yours.',
                icon: Icons.lock_rounded,
              ),
              const SizedBox(height: 48),
              // Login button - primary action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Login', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Register button - secondary action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Account'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterUsernamePage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

      // Check if MFA is enabled
      final mfaEnabled = await _authService.checkMfaStatus(username);

      if (!mounted) return;

      if (mfaEnabled) {
        // Redirect to MFA verification page
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
        // Normal login without MFA
        final token = await _authService.login(username, password);
        if (token == null)
          throw Exception('Incorrect password. Please try again.');

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
        // UI ENHANCEMENT: Theme toggle button for accessibility
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.06,
            ),
            const AppHeroTitle(
              title: 'Welcome Back',
              subtitle: 'Unlock your vault',
              icon: Icons.key_rounded,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.06,
            ),
            // UI ENHANCEMENT: Semantic label for screen reader accessibility
            Semantics(
              label: 'Username input field',
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                // UI ENHANCEMENT: Keyboard navigation - Tab to next field
                textInputAction: TextInputAction.next,
                // UI ENHANCEMENT: Disable input during loading
                enabled: !_loading,
              ),
            ),
            const SizedBox(height: 12),
            // UI ENHANCEMENT: Semantic label for screen reader accessibility
            Semantics(
              label: 'Password input field',
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                // UI ENHANCEMENT: Keyboard navigation - Enter to submit
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _login(),
                // UI ENHANCEMENT: Disable input during loading
                enabled: !_loading,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.03,
            ),
            // UI ENHANCEMENT: Full-width button with loading indicator
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                // UI ENHANCEMENT: Show circular progress indicator during loading
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
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              // UI ENHANCEMENT: Styled error message container with icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        // UI ENHANCEMENT: Theme toggle button
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            const AppHeroTitle(
              title: 'Create Account',
              subtitle: 'Choose a unique username',
              icon: Icons.person_add_rounded,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.06),
            Semantics(
              label: 'Username input field',
              child: TextField(
                controller: _usernameController,
                decoration:
                    const InputDecoration(labelText: 'Choose a username'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _next(),
                enabled: !_loading,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
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
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  String _error = '';

  /// Registers new account and automatically logs in
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
        // UI ENHANCEMENT: Theme toggle button
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return IconButton(
                icon: Icon(
                  settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => settings.toggleTheme(),
                tooltip: settings.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.06,
            ),
            const AppHeroTitle(
              title: 'Set a Strong Password',
              subtitle: 'This protects everything',
              icon: Icons.shield_rounded,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.06,
            ),
            Text(
              'Username: ${widget.username}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Password input field',
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 8 characters',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _register(),
                enabled: !_loading,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
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
                    : const Text('Register'),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppHeroTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AppHeroTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary, // solid blue
          ),
          child: Icon(
            icon,
            size: 42,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade400,
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }
}

class VaultPage extends StatefulWidget {
  final String username;
  final String token;
  final String password;
  final Map<String, dynamic> vaultResponse;

  const VaultPage({
    super.key,
    required this.username,
    required this.token,
    required this.password,
    required this.vaultResponse,
  });

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _authService = AuthService();
  Map<String, Map<String, String>> _vaultItems = {};
  String _now() {
    final t = DateTime.now();
    return "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} "
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  bool _loading = false;

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
    _loadVault(widget.vaultResponse);
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
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
      widget.password,
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
    setState(() => _loading = true);

    final encrypted =
        await _authService.encryptVault(_vaultItems, widget.password);
    await _authService.updateVault(widget.token, encrypted);

    setState(() => _loading = false);
  }

  bool _isStrongPassword(String pass) {
    if (pass.length < 8) return false;

    final hasUpper = pass.contains(RegExp(r'[A-Z]'));
    final hasLower = pass.contains(RegExp(r'[a-z]'));
    final hasNumber = pass.contains(RegExp(r'[0-9]'));
    final hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUpper && hasLower && hasNumber && hasSpecial;
  }

  void _addItem() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: valCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter strong password')),
                );
                return;
              }

              setState(() {
                _vaultItems[title] = {
                  "password": pass,
                  "updatedAt": _now(),
                };
              });

              Navigator.pop(context);
              _saveVault();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editItem(String key, String currentValue) {
    final valCtrl = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: valCtrl,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPass = valCtrl.text.trim();

              if (newPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password cannot be empty')),
                );
                return;
              }

              if (!_isStrongPassword(newPass)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter strong password')),
                );
                return;
              }

              setState(() {
                _vaultItems[key] = {
                  "password": newPass,
                  "updatedAt": _now(),
                };
              });

              Navigator.pop(context);
              _saveVault();
            },
            child: const Text('Save'),
          ),
        ],
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
            onPressed: () {
              setState(() {
                _vaultItems.remove(key);
              });

              Navigator.pop(context); // close dialog
              _saveVault();

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
    _clipboardTimer = Timer(const Duration(seconds: 20), () async {
      await Clipboard.setData(const ClipboardData(text: ''));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard cleared automatically')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _getSortedMap(_vaultItems);

    return Scaffold(
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: sortedItems.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    subtitle: Text("Updated: ${entry.value['updatedAt']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copy(entry.value["password"]!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _editItem(entry.key, entry.value["password"]!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(entry.key),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
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
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter MFA Code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AppHeroTitle(
              title: 'Two-Factor Authentication',
              subtitle: 'Enter code from your authenticator app',
              icon: Icons.shield_rounded,
            ),
            const SizedBox(height: 40),
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
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
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

  Future<void> _checkStatus() async {
    // This is a workaround - we'd need to pass username or store it
    // For now, just show the setup option
    setState(() => _loading = false);
  }

  Future<void> _setupMfa() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MfaSetupPage(
          username: widget.username,
          token: widget.token,
        ),
      ),
    );
  }

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

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
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
                const SizedBox(height: 12),
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
  String _username = '';

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
        _username = ''; // Would need to be passed or stored
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
