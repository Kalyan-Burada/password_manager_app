import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../widgets/app_hero_title.dart';

/// Locked Vault Page
///
/// Displayed when the vault is automatically locked due to inactivity.
/// Users must enter their password to unlock and return to the vault.
///
/// Features:
/// - Password entry field
/// - Unlock button
/// - Security indicator showing auto-lock reason
/// - Auto-lock timer in footer
class LockedVaultPage extends StatefulWidget {
  final String username;
  final String token;
  final String password;
  final Function(String) onUnlock; // Callback with password as parameter
  final VoidCallback onLogout; // Callback for logout action

  const LockedVaultPage({
    super.key,
    required this.username,
    required this.token,
    required this.password,
    required this.onUnlock,
    required this.onLogout,
  });

  @override
  State<LockedVaultPage> createState() => _LockedVaultPageState();
}

class _LockedVaultPageState extends State<LockedVaultPage> {
  final _authService = AuthService();
  final _logService = LogService();
  final _passwordController = TextEditingController();
  final _mfaCodeController = TextEditingController();

  bool _loading = false;
  bool _requiresMfa = false;
  String _enteredPassword = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _logService.setUsername(widget.username);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  /// Verify password and check if MFA is required
  Future<void> _unlock() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final enteredPassword = _passwordController.text;

      if (enteredPassword.isEmpty) {
        throw Exception('Please enter your password');
      }

      // Verify the password by attempting to get vault
      // This ensures the password is correct
      final vault = await _authService.getVault(widget.token);

      // Try to decrypt with the entered password to verify it's correct
      if (vault['blob'] != null) {
        try {
          await _authService.decryptVault(
            Map<String, dynamic>.from(vault['blob']),
            enteredPassword,
          );
        } catch (e) {
          throw Exception('Incorrect password. Please try again.');
        }
      }

      await _logService
          .logAction('Vault unlocked after being locked due to inactivity');

      if (!mounted) return;

      // Notify parent to update vault with the entered password
      widget.onUnlock(enteredPassword);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Verify MFA code and unlock vault
  Future<void> _verifyMfa() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final mfaCode = _mfaCodeController.text;

      if (mfaCode.length != 6) {
        throw Exception('Please enter a 6-digit code');
      }

      // Verify MFA code using loginWithMfa (validates the code)
      debugPrint(
          '[LockedVaultPage] Verifying MFA code for user: ${widget.username}');
      final token = await _authService.loginWithMfa(
        widget.username,
        _enteredPassword,
        mfaCode,
      );

      if (token == null) {
        throw Exception('Invalid MFA code. Please try again.');
      }

      debugPrint(
          '[LockedVaultPage] MFA verification successful, unlocking vault');
      await _logService.logAction(
          'Vault unlocked after being locked due to inactivity (MFA verified)');

      if (!mounted) return;

      // MFA verified - unlock vault with the entered password
      widget.onUnlock(_enteredPassword);
    } catch (e) {
      debugPrint('[LockedVaultPage] MFA verification error: $e');
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Cancel MFA verification and go back to password entry
  void _cancelMfa() {
    debugPrint(
        '[LockedVaultPage] User cancelled MFA verification, returning to password entry');
    setState(() {
      _requiresMfa = false;
      _enteredPassword = '';
      _mfaCodeController.clear();
      _error = '';
    });
    _passwordController.clear();
  }

  /// Logout and return to login screen
  Future<void> _logout() async {
    debugPrint('[LockedVaultPage] User initiated logout');
    setState(() {
      _loading = true;
    });
    try {
      // Call logout API to invalidate token on server
      await _authService.logout(widget.token);
      _logService.clearLogs();

      if (!mounted) return;

      // Call parent logout callback
      widget.onLogout();
    } catch (e) {
      debugPrint('[LockedVaultPage] Logout error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_requiresMfa)
                // === PASSWORD ENTRY SCREEN ===
                ...[
                const AppHeroTitle(
                  title: 'Vault Locked',
                  subtitle: 'Your vault was locked due to inactivity',
                  icon: Icons.lock_rounded,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                // Security info card
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded,
                            color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Security Feature',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter your password to unlock your vault',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                // Password field
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 330),
                  child: Semantics(
                    label: 'Password input field to unlock vault',
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _unlock(),
                      enabled: !_loading,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                // Unlock button
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 460),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Unlock Vault'),
                      onPressed: _loading ? null : _unlock,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Logout button
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 560),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      onPressed: _loading ? null : _logout,
                    ),
                  ),
                ),
              ] else
                // === MFA VERIFICATION SCREEN ===
                ...[
                const AppHeroTitle(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Enter your authenticator code to unlock',
                  icon: Icons.verified_user_rounded,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                // MFA info card
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded,
                            color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MFA Required',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter the 6-digit code from your authenticator app',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                // MFA code field
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 330),
                  child: Semantics(
                    label: 'MFA code input field (6 digits)',
                    child: TextField(
                      controller: _mfaCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          letterSpacing: 10,
                          fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Authentication Code',
                        hintText: '000000',
                        counterText: '',
                        prefixIcon: Icon(Icons.lock_clock_rounded),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _verifyMfa(),
                      enabled: !_loading,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                // Verify button
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 460),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Verify & Unlock'),
                      onPressed: _loading ? null : _verifyMfa,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Back button
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 560),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to Password'),
                      onPressed: _loading ? null : _cancelMfa,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Logout button
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 660),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      onPressed: _loading ? null : _logout,
                    ),
                  ),
                ),
              ],
              // Animated error (shown on both screens)
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
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
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
      ),
    );
  }
}
