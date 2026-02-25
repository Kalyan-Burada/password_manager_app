import 'dart:convert';

/// Represents an imported credential
class ImportedCredential {
  final String title;
  final String password;
  final String? username;
  final String? email;
  final String? url;
  final String? notes;
  final String category;
  final DateTime importedAt;

  ImportedCredential({
    required this.title,
    required this.password,
    this.username,
    this.email,
    this.url,
    this.notes,
    this.category = 'Other',
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now();

  /// Convert to vault format
  Map<String, dynamic> toVaultEntry() {
    return {
      'password': password,
      'updatedAt': _formatDateTime(importedAt),
    };
  }

  static String _formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}

/// Import result with statistics
class ImportResult {
  final List<ImportedCredential> successfullyImported;
  final List<String> failed;
  final int totalCount;

  ImportResult({
    required this.successfullyImported,
    required this.failed,
    required this.totalCount,
  });

  int get successCount => successfullyImported.length;
  int get failCount => failed.length;
  double get successRate =>
      totalCount == 0 ? 0 : (successCount / totalCount) * 100;
}

/// Service to import credentials from various password managers
class ImportService {
  /// Parse CSV format (common export format for most password managers)
  /// Supports: LastPass, 1Password, Bitwarden, KeePass, etc.
  static Future<ImportResult> parseCSV(String csvContent) async {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) {
      return ImportResult(
        successfullyImported: [],
        failed: ['File is empty'],
        totalCount: 0,
      );
    }

    final headers = _parseCSVLine(lines[0]);
    final credentials = <ImportedCredential>[];
    final errors = <String>[];

    // Map common header names to our field names
    final titleIndex = _findColumnIndex(
        headers, ['name', 'title', 'item name', 'password name', 'site name']);
    final passwordIndex =
        _findColumnIndex(headers, ['password', 'pass', 'pwd']);
    final usernameIndex = _findColumnIndex(
        headers, ['username', 'user', 'login', 'email', 'account']);
    final emailIndex = _findColumnIndex(headers, ['email', 'e-mail']);
    final urlIndex =
        _findColumnIndex(headers, ['url', 'website', 'uri', 'login uri']);
    final notesIndex = _findColumnIndex(headers, ['notes', 'note', 'comments']);
    final categoryIndex =
        _findColumnIndex(headers, ['category', 'type', 'folder']);

    // Check if critical columns are found
    if (titleIndex == -1) {
      errors.add(
          'Could not find title column. Found columns: ${headers.join(", ")}');
    }
    if (passwordIndex == -1) {
      errors.add(
          'Could not find password column. Found columns: ${headers.join(", ")}');
    }

    if (errors.isNotEmpty) {
      return ImportResult(
        successfullyImported: [],
        failed: errors,
        totalCount: 0,
      );
    }

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCSVLine(line);

        if (titleIndex >= fields.length || fields[titleIndex].isEmpty) {
          errors.add('Row $i: Missing title/name');
          continue;
        }

        if (passwordIndex >= fields.length || fields[passwordIndex].isEmpty) {
          errors.add('Row $i: Missing password');
          continue;
        }

        final credential = ImportedCredential(
          title: fields[titleIndex].trim(),
          password: fields[passwordIndex].trim(),
          username: usernameIndex >= 0 && usernameIndex < fields.length
              ? fields[usernameIndex].trim()
              : null,
          email: emailIndex >= 0 && emailIndex < fields.length
              ? fields[emailIndex].trim()
              : null,
          url: urlIndex >= 0 && urlIndex < fields.length
              ? fields[urlIndex].trim()
              : null,
          notes: notesIndex >= 0 && notesIndex < fields.length
              ? fields[notesIndex].trim()
              : null,
          category: categoryIndex >= 0 && categoryIndex < fields.length
              ? fields[categoryIndex].trim()
              : _detectCategory(fields[titleIndex].trim()),
        );

        credentials.add(credential);
      } catch (e) {
        errors.add('Row $i: ${e.toString()}');
      }
    }

    return ImportResult(
      successfullyImported: credentials,
      failed: errors,
      totalCount: lines.length - 1, // Exclude header
    );
  }

  /// Parse JSON format (Bitwarden export, custom JSON, etc.)
  static Future<ImportResult> parseJSON(String jsonContent) async {
    final credentials = <ImportedCredential>[];
    final errors = <String>[];

    try {
      final data = jsonDecode(jsonContent);

      if (data is List) {
        // Array of items
        for (int i = 0; i < data.length; i++) {
          try {
            final item = data[i] as Map<String, dynamic>;
            final credential = _parseJSONItem(item);
            if (credential != null) {
              credentials.add(credential);
            }
          } catch (e) {
            errors.add('Item $i: ${e.toString()}');
          }
        }
      } else if (data is Map<String, dynamic>) {
        // Single item or nested structure
        if (data['items'] != null && data['items'] is List) {
          for (int i = 0; i < data['items'].length; i++) {
            try {
              final item = data['items'][i] as Map<String, dynamic>;
              final credential = _parseJSONItem(item);
              if (credential != null) {
                credentials.add(credential);
              }
            } catch (e) {
              errors.add('Item $i: ${e.toString()}');
            }
          }
        } else {
          final credential = _parseJSONItem(data);
          if (credential != null) {
            credentials.add(credential);
          }
        }
      }
    } catch (e) {
      errors.add('JSON Parse Error: ${e.toString()}');
    }

    return ImportResult(
      successfullyImported: credentials,
      failed: errors,
      totalCount: credentials.length + errors.length,
    );
  }

  /// Helper to parse individual JSON item
  static ImportedCredential? _parseJSONItem(Map<String, dynamic> item) {
    final title = _getNestedValue(
            item, ['name', 'title', 'itemName', 'displayName', 'passwordName'])
        as String?;
    final password =
        _getNestedValue(item, ['password', 'pass', 'pwd', 'secret']) as String?;

    if (title == null || title.isEmpty) {
      throw Exception('Missing title or name field');
    }
    if (password == null || password.isEmpty) {
      throw Exception('Missing password field');
    }

    return ImportedCredential(
      title: title,
      password: password,
      username: _getNestedValue(item, ['username', 'user', 'login']) as String?,
      email: _getNestedValue(item, ['email', 'emailAddress']) as String?,
      url: _getNestedValue(item, ['url', 'website', 'uri']) as String?,
      notes: _getNestedValue(item, ['notes', 'note', 'comments']) as String?,
      category:
          _getNestedValue(item, ['category', 'type', 'folder']) as String? ??
              'Imported',
    );
  }

  /// Helper to get nested value from map by multiple possible keys
  static dynamic _getNestedValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }
    return null;
  }

  /// Find column index by trying multiple possible header names
  static int _findColumnIndex(
      List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final headerLower = headers[i].toLowerCase().trim();
      for (final name in possibleNames) {
        if (headerLower.contains(name.toLowerCase())) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Parse a single CSV line handling quotes
  static List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          current += '"';
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    fields.add(current);

    return fields;
  }

  /// Auto-detect category from credential title
  static String _detectCategory(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('email') ||
        lower.contains('gmail') ||
        lower.contains('outlook') ||
        lower.contains('yahoo')) {
      return 'Email';
    } else if (lower.contains('github') ||
        lower.contains('gitlab') ||
        lower.contains('bitbucket') ||
        lower.contains('dev') ||
        lower.contains('code')) {
      return 'Development';
    } else if (lower.contains('amazon') ||
        lower.contains('ebay') ||
        lower.contains('paypal') ||
        lower.contains('shopping')) {
      return 'Shopping';
    } else if (lower.contains('bank') ||
        lower.contains('financial') ||
        lower.contains('crypto') ||
        lower.contains('wallet')) {
      return 'Finance';
    } else if (lower.contains('netflix') ||
        lower.contains('youtube') ||
        lower.contains('spotify') ||
        lower.contains('disney') ||
        lower.contains('hulu')) {
      return 'Entertainment';
    } else if (lower.contains('twitter') ||
        lower.contains('facebook') ||
        lower.contains('instagram') ||
        lower.contains('linkedin') ||
        lower.contains('social')) {
      return 'Social Media';
    } else if (lower.contains('work') ||
        lower.contains('office') ||
        lower.contains('slack') ||
        lower.contains('teams')) {
      return 'Work';
    } else {
      return 'Other';
    }
  }

  /// Detect file format based on extension or content
  static String detectFormat(String filename, String content) {
    filename = filename.toLowerCase();

    if (filename.endsWith('.csv')) {
      return 'csv';
    } else if (filename.endsWith('.json')) {
      return 'json';
    } else if (content.trim().startsWith('{') ||
        content.trim().startsWith('[')) {
      return 'json';
    } else if (content.contains(',')) {
      return 'csv';
    }

    return 'unknown';
  }
}
