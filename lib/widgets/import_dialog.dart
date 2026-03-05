import 'package:flutter/material.dart';
import 'dart:io' hide FileType;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../services/import_service.dart';

class ImportCredentialsDialog extends StatefulWidget {
  final Function(Map<String, Map<String, String>>) onImport;

  const ImportCredentialsDialog({
    super.key,
    required this.onImport,
  });

  @override
  State<ImportCredentialsDialog> createState() =>
      _ImportCredentialsDialogState();
}

class _ImportCredentialsDialogState extends State<ImportCredentialsDialog> {
  bool _loading = false;
  ImportResult? _result;
  String? _error;
  String? _selectedFile;
  String _importFormat = 'csv'; // 'csv' or 'json'

  @override
  void dispose() {
    super.dispose();
  }

  /// Format DateTime for vault storage
  String _formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  /// SECURITY ENHANCEMENT: File selection with native file picker
  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Avoid extension filter bugs on some platforms
        dialogTitle: 'Select Password File',
        lockParentWindow: true,
        withData: true, // Required to get file contents on Web
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final filePath = pickedFile.path;
        final fileName = pickedFile.name;
        
        // Manual extension validation
        final extension = fileName.split('.').last.toLowerCase();
        if (extension != 'csv' && extension != 'json') {
          setState(() => _error = 'Invalid file type. Only CSV and JSON are supported.');
          return;
        }

        String content;

        if (filePath != null) {
          // Native platforms (Desktop/Mobile) provide direct file paths
          final file = File(filePath);
          if (!await file.exists()) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File not found'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          content = await file.readAsString();
        } else if (pickedFile.bytes != null) {
          // Web platform provides bytes instead of a file path
          content = utf8.decode(pickedFile.bytes!);
        } else {
          setState(() => _error = 'Could not read file content');
          return;
        }

        final format = ImportService.detectFormat(fileName, content);

        setState(() {
          _selectedFile = fileName; // Display name since Web doesn't have an absolute path
          _importFormat = format;
        });

        // Auto-parse after file selection
        await _parseFile(content, format);
      }
    } catch (e) {
      setState(() => _error = 'Error selecting file: $e');
    }
  }

  Future<void> _parseFile(String content, String format) async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = format == 'json'
          ? await ImportService.parseJSON(content)
          : await ImportService.parseCSV(content);

      setState(() {
        _result = result;
        _loading = false;
      });

      if (_result!.successCount == 0) {
        // Show detailed error with failure reasons
        final failureDetails = _result!.failed.isNotEmpty
            ? _result!.failed.take(3).join('\n')
            : 'Could not parse file format';
        setState(() => _error = 'No valid credentials found:\n$failureDetails');
      }
    } catch (e) {
      setState(() {
        _error = 'Parse error: $e';
        _loading = false;
      });
    }
  }

  /// Process import and return credentials to VaultPage
  void _confirmImport() {
    if (_result == null || _result!.successCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credentials to import')),
      );
      return;
    }

    // Convert to vault format with complete credential info
    final importedData = <String, Map<String, String>>{};
    for (final credential in _result!.successfullyImported) {
      importedData[credential.title] = {
        'password': credential.password,
        'updatedAt': _formatDateTime(credential.importedAt),
        if (credential.username != null) 'username': credential.username!,
        if (credential.email != null) 'email': credential.email!,
        if (credential.url != null) 'url': credential.url!,
        if (credential.notes != null) 'notes': credential.notes!,
        'category': credential.category,
      };
    }

    Navigator.pop(context);
    widget.onImport(importedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported ${_result!.successCount} credential(s)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Credentials'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import credentials from other password managers',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (_selectedFile == null)
                ElevatedButton.icon(
                  onPressed: _loading ? null : _selectFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Import File'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected File:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedFile!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Format: ${_importFormat.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selectedFile = null;
                                  _result = null;
                                }),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (_result != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _result!.successCount > 0
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        border: Border.all(
                          color: _result!.successCount > 0
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_result!.successCount} Successful',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  if (_result!.failCount > 0)
                                    Text(
                                      '${_result!.failCount} Failed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_result!.successRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_result!.failCount > 0) ...[
                            const Divider(height: 12),
                            const Text(
                              'Failed Entries:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 100,
                              child: ListView(
                                children: _result!.failed
                                    .map((e) => Text(
                                          '• $e',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_result!.successCount > 0)
                      Text(
                        'Preview: ${_result!.successfullyImported.take(3).map((c) => c.title).join(', ')}${_result!.successCount > 3 ? '...' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Supported Formats:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '• CSV: LastPass, 1Password, KeePass, Dashlane\n'
                  '• JSON: Bitwarden, custom exports',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_result != null && _result!.successCount > 0)
          ElevatedButton(
            onPressed: _loading ? null : _confirmImport,
            child: const Text('Import Credentials'),
          ),
      ],
    );
  }
}
