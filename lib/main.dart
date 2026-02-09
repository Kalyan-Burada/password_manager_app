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

void main() {
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

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // enables back arrow
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppHeroTitle(
                title: 'SE 12',
                subtitle: 'Your secrets. Locked. Local. Yours.',
                icon: Icons.lock_rounded,
              ),
              const SizedBox(height: 48),
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
      if (salt == null) throw Exception('User not found. Please check your username.');

      final token = await _authService.login(username, password);
      // UI ENHANCEMENT: User-friendly password error message
      if (token == null) throw Exception('Incorrect password. Please try again.');

      final vault = await _authService.getVault(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultPage(
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
      if (salt != null) throw Exception('Username already taken. Please choose another.');

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
                decoration: const InputDecoration(labelText: 'Choose a username'),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
      if (token == null) throw Exception('Registration succeeded but login failed. Please try logging in.');

      final vault = await _authService.getVault(token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VaultPage(
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
  final String token;
  final String password;
  final Map<String, dynamic> vaultResponse;

  const VaultPage({
    super.key,
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
    _loadVault();
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVault() async {
    final blob = widget.vaultResponse['blob'];
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
              setState(() {
                _vaultItems[keyCtrl.text] = {
                  "password": valCtrl.text,
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
              setState(() {
                _vaultItems[key] = {
                  "password": valCtrl.text,
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
    setState(() {
      _vaultItems.remove(key);
      _vaultItems = _getSortedMap(_vaultItems);
    });
    _saveVault();
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
            tooltip: 'Manage Backups',
            onPressed: () async {
              final restored = await showDialog<bool>(
                context: context,
                builder: (context) => BackupManagerDialog(
                  token: widget.token,
                  authService: _authService,
                ),
              );
              
              // If a backup was restored, reload vault data
              if (restored == true && mounted) {
                final freshVault = await _authService.getVault(widget.token);
                final blob = freshVault['blob'];
                if (blob != null) {
                  final decrypted = await _authService.decryptVault(
                    Map<String, dynamic>.from(blob),
                    widget.password,
                  );
                  setState(() {
                    _vaultItems = Map<String, Map<String, String>>.from(
                      decrypted.map((k, v) => MapEntry(
                            k,
                            Map<String, String>.from(v),
                          )),
                    );
                  });
                }
              }
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
