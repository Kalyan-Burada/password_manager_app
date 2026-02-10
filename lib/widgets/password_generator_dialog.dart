import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/password_generator.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  double _length = 16;
  bool _useLower = true;
  bool _useUpper = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _password = PasswordGenerator.generate(
        length: _length.round(),
        useLower: _useLower,
        useUpper: _useUpper,
        useNumbers: _useNumbers,
        useSymbols: _useSymbols,
      );
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Area
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _password,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regenerate'),
                ),
              ],
            ),
            const Divider(),
            
            // Configuration
            const Text('Length'),
            Slider(
              value: _length,
              min: 4,
              max: 64,
              divisions: 60,
              label: _length.round().toString(),
              onChanged: (val) {
                setState(() => _length = val);
                _generate();
              },
            ),
            
            CheckboxListTile(
              title: const Text('Lowercase (a-z)'),
              value: _useLower,
              onChanged: (val) {
                if (val == false && !_useUpper && !_useNumbers && !_useSymbols) return;
                setState(() => _useLower = val ?? true);
                _generate();
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Uppercase (A-Z)'),
              value: _useUpper,
              onChanged: (val) {
                if (val == false && !_useLower && !_useNumbers && !_useSymbols) return;
                setState(() => _useUpper = val ?? true);
                _generate();
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Numbers (0-9)'),
              value: _useNumbers,
              onChanged: (val) {
                if (val == false && !_useLower && !_useUpper && !_useSymbols) return;
                setState(() => _useNumbers = val ?? true);
                _generate();
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Symbols (!@#)'),
              value: _useSymbols,
              onChanged: (val) {
                if (val == false && !_useLower && !_useUpper && !_useNumbers) return;
                setState(() => _useSymbols = val ?? true);
                _generate();
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _password),
          child: const Text('Use Password'),
        ),
      ],
    );
  }
}
