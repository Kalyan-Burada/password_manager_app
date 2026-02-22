
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

/// Displays the audit log for the currently signed-in user.
///
/// Logs are fetched from the server's /logs endpoint, which filters
/// entries server-side — so each user only ever sees their own activity.
/// This replaces the previous device-local SharedPreferences log storage
/// that incorrectly showed all users' logs on the same device.
class LogPage extends StatefulWidget {
  /// The session token of the logged-in user, passed in from VaultPage.
  /// Required to authenticate the /logs API call.
  final String token;

  const LogPage({super.key, required this.token});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final _authService = AuthService();

  // Holds the list of log entries fetched from the server
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs(); // Fetch logs as soon as the page opens
  }

  /// Fetch audit logs from the server using the session token.
  /// The server filters logs by the token's owner, so only this
  /// user's activity is returned.
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _authService.getLogs(widget.token);
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load logs. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Build a human-readable label for each server action code.
  /// The server uses uppercase action names like "VAULT_ACCESS";
  /// this converts them to friendly display text.
  String _formatAction(Map<String, dynamic> log) {
    final action = log['action'] ?? '';
    final details = log['details'] ?? '';

    // Map server action codes → readable labels
    switch (action) {
      case 'VAULT_ACCESS':   return 'Vault accessed';
      case 'VAULT_UPDATE':   return 'Vault updated';
      case 'BACKUP_CREATE':  return 'Backup created';
      case 'BACKUP_RESTORE': return details.isNotEmpty ? 'Backup restored: ${details.replaceFirst('Restored backup: ', '')}' : 'Backup restored';
      case 'BACKUP_DELETE':  return details.isNotEmpty ? 'Backup deleted: ${details.replaceFirst('Deleted backup: ', '')}' : 'Backup deleted';
      case 'BACKUP_LIST':    return 'Backups listed';
      case 'MFA_SETUP_INIT': return 'MFA setup initiated';
      case 'MFA_DISABLED':   return 'MFA disabled';
      default:
        // Fall back to details if available, otherwise the raw action name
        return details.isNotEmpty ? details : action;
    }
  }

  /// Return an icon that visually represents the action type.
  IconData _iconFor(String action) {
    switch (action) {
      case 'VAULT_ACCESS':   return Icons.lock_open;
      case 'VAULT_UPDATE':   return Icons.edit;
      case 'BACKUP_CREATE':  return Icons.backup;
      case 'BACKUP_RESTORE': return Icons.restore;
      case 'BACKUP_DELETE':  return Icons.delete_outline;
      case 'MFA_SETUP_INIT':
      case 'MFA_DISABLED':   return Icons.security;
      default:               return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          // Refresh button — re-fetches from the server
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show a spinner while the network request is in-flight
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show an error message with a retry button if the request failed
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLogs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show a placeholder if there are no log entries yet
    if (_logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No activity yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Render the list of log entries from the server
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final action = log['action'] ?? '';

        // Parse the ISO-8601 timestamp returned by the server
        final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();

        return ListTile(
          leading: Icon(_iconFor(action)),
          title: Text(_formatAction(log)),
          subtitle: Text(
            DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp),
          ),
        );
      },
    );
  }
}
