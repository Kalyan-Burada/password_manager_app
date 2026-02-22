import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const LockedVaultPage({
    super.key,
    required this.username,
    required this.token,
    required this.password,
    required this.onUnlock,
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
          .logAction(widget.username, 'Vault unlocked after being locked due to inactivity');

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
          widget.username, 'Vault unlocked after being locked due to inactivity (MFA verified)');

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

  @override
  void dispose() {
    _passwordController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_requiresMfa)
                // === PASSWORD ENTRY SCREEN ===
                ...[
                const AppHeroTitle(
                  title: 'Vault Locked',
                  subtitle: 'Your vault was locked due to inactivity',
                  icon: Icons.lock,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.06,
                ),
                // Security info card
                Card(
                  color: Colors.orange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.security, color: Colors.orange),
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.04,
                ),
                // Password field
                Semantics(
                  label: 'Password input field to unlock vault',
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _unlock(),
                    enabled: !_loading,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                // Unlock button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock Vault'),
                    onPressed: _loading ? null : _unlock,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ] else
                // === MFA VERIFICATION SCREEN ===
                ...[
                const AppHeroTitle(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Enter your authenticator code to unlock',
                  icon: Icons.verified_user,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.06,
                ),
                // MFA info card
                Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, color: Colors.blue),
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.04,
                ),
                // MFA code field
                Semantics(
                  label: 'MFA code input field (6 digits)',
                  child: TextField(
                    controller: _mfaCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Authentication Code',
                      hintText: '000000',
                      counterText: '', // Hide character counter
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _verifyMfa(),
                    enabled: !_loading,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Verify & Unlock'),
                    onPressed: _loading ? null : _verifyMfa,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                // Back button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Password'),
                    onPressed: _loading ? null : _cancelMfa,
                  ),
                ),
              ],
              // Error message (shown on both screens)
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
      ),
    );
  }
}
