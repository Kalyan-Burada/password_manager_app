import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LogAction {
  final String action;
  final DateTime timestamp;

  LogAction({required this.action, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LogAction.fromJson(Map<String, dynamic> json) => LogAction(
        action: json['action'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class LogService {
  String _getStorageKey(String username) => 'user_action_logs_${username.toLowerCase()}';

  Future<List<LogAction>> getLogs(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_getStorageKey(username)) ?? [];
    
    return logsJson
        .map((e) => LogAction.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
  }

  Future<void> logAction(String username, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getLogs(username);
    
    final newLog = LogAction(
      action: action,
      timestamp: DateTime.now(),
    );

    // Keep only last 100 logs to prevent infinite growth
    if (logs.length >= 100) {
      logs.removeLast();
    }
    
    // Insert new log at the beginning
    logs.insert(0, newLog);

    final logsJson = logs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_getStorageKey(username), logsJson);
  }

  Future<void> clearLogs(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getStorageKey(username));
  }
}
