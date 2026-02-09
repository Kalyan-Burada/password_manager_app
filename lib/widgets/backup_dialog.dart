import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class BackupManagerDialog extends StatefulWidget {
  final String token;
  final AuthService authService;

  const BackupManagerDialog({
    super.key,
    required this.token,
    required this.authService,
  });

  @override
  State<BackupManagerDialog> createState() => _BackupManagerDialogState();
}

class _BackupManagerDialogState extends State<BackupManagerDialog> {
  List<String> _backups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final backups = await widget.authService.getBackups(widget.token);
      setState(() {
        _backups = backups;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    try {
      setState(() => _loading = true);
      await widget.authService.createBackup(widget.token);
      await _loadBackups(); // Reload list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _restoreBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text(
          'WARNING: Restoring a backup will overwrite ALL current data.\n\n'
          'Are you sure you want to proceed?',
        ), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _loading = true);
      await widget.authService.restoreBackup(widget.token, filename);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate restore happened
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime? _parseTimestamp(String filename) {
    // Extract timestamp from filename like "backup_20260209_210036.enc"
    final regex = RegExp(r'backup_(\d{8})_(\d{6})\.enc');
    final match = regex.firstMatch(filename);
    
    if (match == null) return null;
    
    final dateStr = match.group(1)!; // "20260209"
    final timeStr = match.group(2)!; // "210036"
    
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    final hour = int.parse(timeStr.substring(0, 2));
    final minute = int.parse(timeStr.substring(2, 4));
    final second = int.parse(timeStr.substring(4, 6));
    
    return DateTime(year, month, day, hour, minute, second);
  }

  String _formatTimestamp(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Encrypted Backups',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.1),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _backups.isEmpty
                      ? const Center(child: Text('No backups found'))
                      : ListView.builder(
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            final timestamp = _parseTimestamp(backup);
                            return ListTile(
                              leading: const Icon(Icons.backup),
                              title: Text(backup),
                              subtitle: Text(timestamp != null 
                                ? 'Created: ${_formatTimestamp(timestamp)}'
                                : 'Encrypted Backup'),
                              trailing: ElevatedButton(
                                onPressed: () => _restoreBackup(backup),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Restore'),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create New Backup'),
                onPressed: _loading ? null : _createBackup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
