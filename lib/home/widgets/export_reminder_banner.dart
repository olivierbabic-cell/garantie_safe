import 'package:flutter/material.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

class ExportReminderBanner extends StatefulWidget {
  const ExportReminderBanner({super.key});

  @override
  State<ExportReminderBanner> createState() => _ExportReminderBannerState();
}

class _ExportReminderBannerState extends State<ExportReminderBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.backup, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.backupExportReminderTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  t.backupExportReminderMessage,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await BackupService.shareBackup();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.backup_exported_successfully)),
                );
                setState(() => _dismissed = true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.backupExportFailed(e.toString()))),
                );
              }
            },
            child: Text(t.backupExportButton),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
