import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'backup_setup_screen.dart';
import '../settings/notifications_settings_screen.dart';
import '../settings/payment_method_settings_screen.dart';
import '../settings/security_settings_screen.dart';

/// Setup & Preferences hub screen
/// NOTE: All text must come from AppLocalizations to react to language changes
class SetupHubScreen extends StatelessWidget {
  const SetupHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.setup_hub_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.setup_hub_subtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            t.setup_hub_note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),

          // Backup section
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.backup),
              ),
              title: Text(t.setup_backup_title),
              subtitle: Text(t.setup_backup_subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BackupSetupScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Notifications section
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.notifications),
              ),
              title: Text(t.setup_notifications_title),
              subtitle: Text(t.setup_notifications_subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Payment methods section
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.payment),
              ),
              title: Text(t.setup_payment_methods_title),
              subtitle: Text(t.setup_payment_methods_subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Security section
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.security),
              ),
              title: Text(t.setup_security_title),
              subtitle: Text(t.setup_security_subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
