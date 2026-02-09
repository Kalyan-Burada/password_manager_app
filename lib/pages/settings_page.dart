import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../docs_page.dart';

/* =========================
   UI ENHANCEMENT: SETTINGS PAGE
   Centralized accessibility and appearance controls
   
   Features:
   - Dark/Light mode toggle
   - High contrast mode for better readability
   - Adjustable text size (0.8x - 1.5x) with live preview
   - Keyboard shortcuts reference
   - Security documentation link
   
   All settings persist using shared_preferences
   ========================= */

/// Settings page with accessibility and appearance controls
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          semanticsLabel: 'Settings page',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
          const SizedBox(height: 12),
          _buildAppearanceSection(context),
          const SizedBox(height: 32),

          // Accessibility Section
          _buildSectionHeader(context, 'Accessibility', Icons.accessibility_new),
          const SizedBox(height: 12),
          _buildAccessibilitySection(context),
          const SizedBox(height: 32),

          // About Section
          _buildSectionHeader(context, 'About', Icons.info_outline),
          const SizedBox(height: 12),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            // Theme Mode Toggle
            _buildSettingCard(
              context,
              title: 'Dark Mode',
              subtitle: settings.isDarkMode ? 'Enabled' : 'Disabled',
              icon: settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              trailing: Switch(
                value: settings.isDarkMode,
                onChanged: (_) => settings.toggleTheme(),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              semanticLabel: 'Toggle dark mode, currently ${settings.isDarkMode ? "enabled" : "disabled"}',
            ),
            const SizedBox(height: 12),

            // High Contrast Toggle
            _buildSettingCard(
              context,
              title: 'High Contrast',
              subtitle: 'Enhance text readability',
              icon: Icons.contrast,
              trailing: Switch(
                value: settings.highContrast,
                onChanged: (value) => settings.setHighContrast(value),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              semanticLabel: 'Toggle high contrast mode, currently ${settings.highContrast ? "enabled" : "disabled"}',
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessibilitySection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            // Text Size Slider
            _buildTextSizeCard(context, settings),
            const SizedBox(height: 12),

            // Keyboard Shortcuts Info
            _buildSettingCard(
              context,
              title: 'Keyboard Navigation',
              subtitle: 'Tab to navigate, Enter to submit',
              icon: Icons.keyboard,
              onTap: () => _showKeyboardShortcutsDialog(context),
              semanticLabel: 'View keyboard navigation shortcuts',
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextSizeCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text Size',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${(settings.textScale * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Preview text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Preview: The quick brown fox jumps over the lazy dog',
                style: TextStyle(
                  fontSize: 14 * settings.textScale,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Slider
            Row(
              children: [
                const Icon(Icons.text_decrease, size: 16),
                Expanded(
                  child: Slider(
                    value: settings.textScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 14,
                    label: '${(settings.textScale * 100).round()}%',
                    onChanged: (value) => settings.setTextScale(value),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Icon(Icons.text_increase, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          title: 'Security Documentation',
          subtitle: 'Learn about zero-knowledge architecture',
          icon: Icons.security,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentationPage()),
            );
          },
          semanticLabel: 'View security documentation',
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          context,
          title: 'Version',
          subtitle: '1.0.0',
          icon: Icons.info,
          semanticLabel: 'App version 1.0.0',
        ),
      ],
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      child: Card(
        child: ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right)
                  : null),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showKeyboardShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard),
            SizedBox(width: 12),
            Text('Keyboard Shortcuts'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutRow('Tab', 'Navigate between fields'),
            const SizedBox(height: 8),
            _buildShortcutRow('Enter', 'Submit forms'),
            const SizedBox(height: 8),
            _buildShortcutRow('Esc', 'Close dialogs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String key, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.4)),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(description)),
      ],
    );
  }
}
