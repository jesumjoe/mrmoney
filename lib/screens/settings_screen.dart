import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrmoney/providers/settings_provider.dart';
import 'package:mrmoney/screens/category_management_screen.dart';
import 'package:mrmoney/screens/debug_log_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // General Section
          _buildSectionHeader(context, 'General'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(
              settings.themeMode == ThemeMode.system
                  ? 'System Default'
                  : settings.themeMode == ThemeMode.dark
                  ? 'Dark Mode'
                  : 'Light Mode',
            ),
            onTap: () => settings.toggleTheme(),
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                settings.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Currency Symbol'),
            subtitle: const Text('₹ (Indian Rupee)'),
            onTap: () {
              // TODO: Implement currency selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Currency selection coming soon!'),
                ),
              );
            },
          ),

          const Divider(),

          // Categories
          _buildSectionHeader(context, 'Categories'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit, or remove categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Data & Sync
          _buildSectionHeader(context, 'Data & Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Last SMS Scan'),
            subtitle: const Text('Just now'), // Placeholder
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Manage your data'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup feature coming soon!')),
              );
            },
          ),

          const Divider(),

          // About
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Mr. Money'),
            subtitle: const Text('Version 1.0.0'),
          ),

          const Divider(),

          // Debug
          _buildSectionHeader(context, 'Debug & Logs'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('View Background Logs'),
            subtitle: const Text('Check SMS processing logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugLogScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
