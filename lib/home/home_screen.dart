import 'package:flutter/material.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.home_title),
        actions: [
          IconButton(
            tooltip: t.settings_title,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.home_welcome, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _DashTile(
                    icon: Icons.document_scanner,
                    label: t.scan_title,
                    onTap: () => Navigator.of(context).pushNamed('/scan'),
                  ),
                  _DashTile(
                    icon: Icons.receipt_long,
                    label: t.items_title,
                    onTap: () => Navigator.of(context).pushNamed('/items'),
                  ),
                  _DashTile(
                    icon: Icons.notifications,
                    label: t.notifications_title,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  _DashTile(
                    icon: Icons.settings,
                    label: t.settings_title,
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
