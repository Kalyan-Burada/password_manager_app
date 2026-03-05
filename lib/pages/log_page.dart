
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

/// Displays the audit log for the currently signed-in user with filtering
/// and sorting controls.
class LogPage extends StatefulWidget {
  final String token;
  const LogPage({super.key, required this.token});

  @override
  State<LogPage> createState() => _LogPageState();
}

// ── Category filter model ─────────────────────────────────────────────────────
class _Category {
  final String label;
  final Set<String> actions; // server action codes this category matches
  const _Category(this.label, this.actions);
}

final _categories = [
  _Category('All', {}),
  _Category('Login / Logout',   {'LOGIN', 'LOGOUT', 'REGISTER'}),
  _Category('Failed Login',     {'LOGIN_FAILED', 'MFA_VERIFY_FAILED'}),
  _Category('Vault',            {'VAULT_ACCESS', 'VAULT_UPDATE'}),
  _Category('Backup',           {'BACKUP_CREATE', 'BACKUP_RESTORE', 'BACKUP_DELETE', 'BACKUP_LIST'}),
  _Category('MFA',              {'MFA_SETUP_INIT', 'MFA_ENABLED', 'MFA_DISABLED'}),
  _Category('Security Alerts',  {'SECURITY_BLOCK', 'SECURITY_SUSPICIOUS'}),
];

class _LogPageState extends State<LogPage> {
  final _authService = AuthService();

  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  // ── Filter state ─────────────────────────────────────────────────────────────
  int _categoryIndex = 0;   // index into _categories; 0 = "All"
  DateTime? _selectedDate;  // null = no date filter
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final logs = await _authService.getLogs(widget.token);
      if (mounted) setState(() { _logs = logs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load logs. Please try again.'; _isLoading = false; });
    }
  }

  // ── Computed filtered + sorted list ──────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredLogs {
    final cat = _categories[_categoryIndex];
    var result = _logs.where((log) {
      final action = log['action'] ?? '';

      // Category filter (empty set = "All")
      if (cat.actions.isNotEmpty && !cat.actions.contains(action)) return false;

      // Date filter
      if (_selectedDate != null) {
        final ts = DateTime.tryParse(log['timestamp'] ?? '');
        if (ts == null) return false;
        if (ts.year != _selectedDate!.year ||
            ts.month != _selectedDate!.month ||
            ts.day != _selectedDate!.day) return false;
      }

      return true;
    }).toList();

    // Sort
    result.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(0);
      final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(0);
      return _sortNewestFirst ? tb.compareTo(ta) : ta.compareTo(tb);
    });

    return result;
  }

  // ── Helper: human-readable action label ──────────────────────────────────────
  String _formatAction(Map<String, dynamic> log) {
    final action = log['action'] ?? '';
    final details = log['details'] ?? '';
    switch (action) {
      case 'REGISTER':           return 'Account registered';
      case 'LOGIN':              return 'Logged in';
      case 'LOGOUT':             return 'Logged out';
      case 'LOGIN_FAILED':       return details.isNotEmpty ? details : 'Login failed';
      case 'VAULT_ACCESS':       return 'Vault accessed';
      case 'VAULT_UPDATE':       return 'Vault updated';
      case 'BACKUP_CREATE':      return 'Backup created';
      case 'BACKUP_RESTORE':     return details.isNotEmpty ? 'Backup restored: ${details.replaceFirst('Restored backup: ', '')}' : 'Backup restored';
      case 'BACKUP_DELETE':      return details.isNotEmpty ? 'Backup deleted: ${details.replaceFirst('Deleted backup: ', '')}' : 'Backup deleted';
      case 'BACKUP_LIST':        return 'Backups listed';
      case 'MFA_SETUP_INIT':     return 'MFA setup initiated';
      case 'MFA_ENABLED':        return 'MFA enabled';
      case 'MFA_DISABLED':       return 'MFA disabled';
      case 'MFA_VERIFY_FAILED':  return 'MFA verification failed';
      case 'SECURITY_BLOCK':     return details.isNotEmpty ? details : 'IP blocked';
      case 'SECURITY_SUSPICIOUS':return details.isNotEmpty ? details : 'Suspicious activity';
      default:                   return details.isNotEmpty ? details : action;
    }
  }

  // ── Helper: icon for action ───────────────────────────────────────────────────
  IconData _iconFor(String action) {
    switch (action) {
      case 'REGISTER':            return Icons.person_add;
      case 'LOGIN':               return Icons.login;
      case 'LOGOUT':              return Icons.logout;
      case 'LOGIN_FAILED':        return Icons.no_accounts;
      case 'VAULT_ACCESS':        return Icons.lock_open;
      case 'VAULT_UPDATE':        return Icons.edit;
      case 'BACKUP_CREATE':       return Icons.backup;
      case 'BACKUP_RESTORE':      return Icons.restore;
      case 'BACKUP_DELETE':       return Icons.delete_outline;
      case 'BACKUP_LIST':         return Icons.list_alt;
      case 'MFA_SETUP_INIT':
      case 'MFA_ENABLED':
      case 'MFA_DISABLED':        return Icons.security;
      case 'MFA_VERIFY_FAILED':   return Icons.mobile_off;
      case 'SECURITY_BLOCK':
      case 'SECURITY_SUSPICIOUS': return Icons.warning_amber_rounded;
      default:                    return Icons.history;
    }
  }

  // ── Helper: icon color for action ─────────────────────────────────────────────
  Color _colorFor(String action, ColorScheme cs) {
    if (action.contains('FAILED') || action.contains('BLOCK') || action.contains('SUSPICIOUS')) {
      return Colors.red.shade400;
    }
    if (action.startsWith('BACKUP')) return Colors.blue.shade400;
    if (action.startsWith('MFA'))    return Colors.purple.shade300;
    if (action == 'LOGIN')           return Colors.green.shade400;
    if (action == 'LOGOUT')          return Colors.orange.shade400;
    return cs.primary;
  }

  // ── Helper: is this a security alert action? ──────────────────────────────
  bool _isSecurityAction(String action) =>
      action.contains('FAILED') ||
      action.contains('BLOCK') ||
      action.contains('SUSPICIOUS');

  // ── Summary stats for the banner row ─────────────────────────────────────
  Map<String, int> _buildStats(List<Map<String, dynamic>> all) {
    int logins = 0, vault = 0, alerts = 0;
    for (final log in all) {
      final a = log['action'] ?? '';
      if (a == 'LOGIN' || a == 'LOGOUT' || a == 'REGISTER') logins++;
      else if (a.startsWith('VAULT')) vault++;
      else if (_isSecurityAction(a)) alerts++;
    }
    return {'Logins': logins, 'Vault': vault, 'Alerts': alerts};
  }

  // ── Compact stat card widget ──────────────────────────────────────────────
  Widget _statCard(ColorScheme cs, IconData icon, String label, int value, bool isAlert) {
    final active = isAlert && value > 0;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Colors.red.shade900.withOpacity(0.25)
              : cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? Colors.red.shade700.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.red.shade300 : cs.primary,
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: active ? Colors.red.shade300 : cs.primary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date picker ───────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredLogs;
    final stats = _buildStats(_logs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            icon: Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: _sortNewestFirst ? 'Switch to oldest first' : 'Switch to newest first',
            onPressed: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: _selectedDate != null ? cs.primary : null,
            ),
            tooltip: _selectedDate != null
                ? 'Filtered by: ${DateFormat('dd MMM').format(_selectedDate!)} (tap to change)'
                : 'Filter by date',
            onPressed: () async => await _pickDate(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary stats row ──────────────────────────────────────────────
          if (!_isLoading && _error == null && _logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _statCard(cs, Icons.login, 'Logins', stats['Logins']!, false),
                  _statCard(cs, Icons.lock_open, 'Vault', stats['Vault']!, false),
                  _statCard(cs, Icons.warning_amber_rounded, 'Alerts', stats['Alerts']!, true),
                ],
              ),
            ),

          // ── Filter Chips with scroll shadow ────────────────────────────────
          Material(
            color: Colors.transparent,
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.15),
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = _categoryIndex == i;
                  return ChoiceChip(
                    label: Text(_categories[i].label),
                    selected: selected,
                    onSelected: (_) => setState(() => _categoryIndex = i),
                    showCheckmark: false,
                    selectedColor: cs.primary,
                    backgroundColor: Colors.transparent,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outline.withOpacity(0.5),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : cs.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── Results count + clear filters ──────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} entr${filtered.length == 1 ? 'y' : 'ies'}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  if (_categoryIndex != 0 || _selectedDate != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _categoryIndex = 0;
                        _selectedDate = null;
                      }),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

          // ── Animated Logs List ─────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey('$_categoryIndex-${_selectedDate?.toIso8601String()}-$_sortNewestFirst'),
                child: _buildBody(filtered, cs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filtered, ColorScheme cs) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadLogs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: cs.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _logs.isEmpty ? 'No activity yet' : 'No entries match the current filters',
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ── Group logs by date for section headers ────────────────────────────
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final log in filtered) {
      final ts = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
      final dayKey = DateFormat('yyyy-MM-dd').format(ts);
      grouped.putIfAbsent(dayKey, () => []).add(log);
    }
    final dayKeys = grouped.keys.toList()
      ..sort((a, b) => _sortNewestFirst ? b.compareTo(a) : a.compareTo(b));

    return ListView.builder(
      itemCount: dayKeys.fold<int>(0, (sum, k) => sum + 1 + grouped[k]!.length),
      itemBuilder: (context, index) {
        int offset = 0;
        for (final day in dayKeys) {
          final items = grouped[day]!;
          if (index == offset) {
            final date = DateTime.parse(day);
            final now = DateTime.now();
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isYesterday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day - 1;
            final label = isToday
                ? 'TODAY'
                : isYesterday
                    ? 'YESTERDAY'
                    : DateFormat('EEEE • dd MMM yyyy').format(date).toUpperCase();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 0.6, height: 1),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }
          offset++;
          if (index < offset + items.length) {
            final log = items[index - offset];
            final action = log['action'] ?? '';
            final ts = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
            final color = _colorFor(action, cs);
            final isAlert = _isSecurityAction(action);

            return Column(
              children: [
                InkWell(
                  hoverColor: isAlert
                      ? Colors.red.withOpacity(0.06)
                      : cs.primary.withOpacity(0.05),
                  onTap: () {},
                  child: Container(
                    color: isAlert ? Colors.red.shade900.withOpacity(0.12) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(_iconFor(action), color: color, size: 20),
                      ),
                      title: Row(
                        children: [
                          if (isAlert)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.warning_amber_rounded,
                                  size: 14, color: Colors.redAccent.shade200),
                            ),
                          Expanded(
                            child: Text(
                              _formatAction(log),
                              style: TextStyle(
                                color: isAlert ? Colors.redAccent.shade100 : null,
                                fontWeight: isAlert ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        DateFormat('HH:mm:ss').format(ts),
                        style: TextStyle(
                          fontSize: 11,
                          color: isAlert
                              ? Colors.redAccent.shade100.withOpacity(0.7)
                              : null,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 0.4, indent: 72, endIndent: 16),
              ],
            );
          }
          offset += items.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}
