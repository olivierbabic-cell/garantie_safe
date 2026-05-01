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
    final setupItems = _getSetupItems(context, t);

    return Scaffold(
      appBar: AppBar(title: Text(t.setup_hub_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderSection(
            subtitle: t.setup_hub_subtitle,
            note: t.setup_hub_note,
          ),
          const SizedBox(height: 24),
          ...setupItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SetupCard(item: item),
              )),
        ],
      ),
    );
  }

  List<_SetupItem> _getSetupItems(BuildContext context, AppLocalizations t) {
    return [
      _SetupItem(
        icon: Icons.backup,
        title: t.setup_backup_title,
        subtitle: t.setup_backup_subtitle,
        destination: const BackupSetupScreen(),
      ),
      _SetupItem(
        icon: Icons.notifications,
        title: t.setup_notifications_title,
        subtitle: t.setup_notifications_subtitle,
        destination: const NotificationsSettingsScreen(),
      ),
      _SetupItem(
        icon: Icons.payment,
        title: t.setup_payment_methods_title,
        subtitle: t.setup_payment_methods_subtitle,
        destination: const PaymentMethodSettingsScreen(),
      ),
      _SetupItem(
        icon: Icons.security,
        title: t.setup_security_title,
        subtitle: t.setup_security_subtitle,
        destination: const SecuritySettingsScreen(),
      ),
    ];
  }
}

/// Data model for a setup item
class _SetupItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget destination;

  const _SetupItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.destination,
  });
}

/// Header section with subtitle and note
class _HeaderSection extends StatelessWidget {
  final String subtitle;
  final String note;

  const _HeaderSection({
    required this.subtitle,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          note,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}

/// Reusable setup card widget
class _SetupCard extends StatelessWidget {
  final _SetupItem item;

  const _SetupCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(item.icon),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToDestination(context),
      ),
    );
  }

  void _navigateToDestination(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => item.destination),
    );
  }
}
