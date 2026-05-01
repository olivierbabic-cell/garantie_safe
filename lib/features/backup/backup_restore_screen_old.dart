import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/db/db_providers.dart';
import 'package:garantie_safe/core/services/backup_reminder_service.dart';
import 'package:garantie_safe/features/items/items_providers.dart';
import 'package:garantie_safe/features/items/item_edit_screen.dart';
import 'snapshot_chooser_screen.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  Map<String, dynamic>? _backupStatus;
  Map<String, dynamic>? _cloudStatus;
  BackupHealth? _backupHealth;
  int? _cloudBackupAgeDays;
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await BackupService.getBackupStatus();
    final cloudStatus = await BackupService.getCloudExportStatus();
    final health = await BackupService.getBackupHealth();
    final cloudAge = await BackupService.getCloudBackupAgeDays();
    if (!mounted) return;
    setState(() {
      _backupStatus = status;
      _cloudStatus = cloudStatus;
      _backupHealth = health;
      _cloudBackupAgeDays = cloudAge;
      _loading = false;
    });
  }

  Future<void> _backupNow() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      await BackupService.createSnapshot();
      await _loadStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.backup_success)),
      );
    } catch (e) {
      debugPrint('Snapshot failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.backup_snapshot_failed(e.toString())),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _restoreFromInternalBackup() async {
    // Open snapshot chooser screen
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SnapshotChooserScreen(),
      ),
    );

    // Reload status after returning from snapshot chooser
    _loadStatus();
  }

  Future<void> _restoreFromFile() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        setState(() => _processing = false);
        return;
      }

      final file = result.files.single;

      if (!file.name.toLowerCase().endsWith('.gsbackup')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.backup_select_valid_file),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _processing = false);
        return;
      }

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.backup_restore_confirm_title),
          content: Text('${t.backup_restore_confirm}\n\nFile: ${file.name}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.backup_restore),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _processing = false);
        return;
      }

      // Set restoring state
      ref.read(isRestoringProvider.notifier).state = true;

      // Read bytes
      List<int>? bytes;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        bytes = file.bytes!;
      } else if (file.path != null && file.path!.isNotEmpty) {
        final sourceFile = File(file.path!);
        if (await sourceFile.exists()) {
          bytes = await sourceFile.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Unable to read backup file');
      }

      // Validate ZIP header
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        throw Exception('Invalid backup file: not a valid ZIP archive');
      }

      // Perform restore
      await BackupService.restoreBackup(backupBytes: bytes);

      // Reset data layer after restore - invalidate all DB-dependent providers
      _resetDataLayerAfterRestore();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.backup_restore_completed),
          content: Text(t.backup_restore_success),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.ok),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e, st) {
      debugPrint('Restore error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.backup_restore_failed_details(e.toString())),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        ref.read(isRestoringProvider.notifier).state = false;
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _shareBackup() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      final success = await BackupService.shareBackup();

      if (success) {
        await _loadStatus();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.backup_exported_successfully)),
        );
      }
      // If cancelled, don't show any message
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.backupExportFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _exportToCloud() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      final success = await BackupService.exportToCloudFolder();

      if (success) {
        await _loadStatus();

        // Reset backup reminder since user just exported
        await BackupReminderService.resetReminder();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.backup_cloud_exported),
            backgroundColor: Colors.green,
          ),
        );
      }
      // If cancelled, don't show any message
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.backup_cloud_export_failed(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _toggleCloudBackup() async {
    final t = AppLocalizations.of(context)!;
    final cloudEnabled = _cloudStatus?['enabled'] as bool? ?? false;

    if (cloudEnabled) {
      // Disable cloud backup
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.backup_disable_cloud_title),
          content: Text(t.backup_disable_cloud_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.disable),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await Prefs.setCloudExportEnabled(false);
        await _loadStatus();
      }
    } else {
      // Enable cloud backup and show instructions
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.backup_cloud_title),
          content: Text(t.backup_cloud_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await Prefs.setCloudExportEnabled(true);
                await _loadStatus();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(t.enable),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openDeviceBackupSettings() async {
    final t = AppLocalizations.of(context)!;
    // This would open device-specific backup settings
    // On Android: Settings > System > Backup
    // On iOS: Settings > [Your Name] > iCloud > iCloud Backup

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.backup_device_settings_info),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String _formatTimestamp(int? timestamp) {
    final t = AppLocalizations.of(context)!;
    if (timestamp == null) return t.backup_never;

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return t.backup_time_just_now;
    if (diff.inMinutes < 60) return t.backup_time_min_ago(diff.inMinutes);
    if (diff.inHours < 24) return t.backup_time_hours_ago(diff.inHours);
    if (diff.inDays < 7) return t.backup_time_days_ago(diff.inDays);

    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatSnapshotCounts(Map<String, int> counts) {
    final t = AppLocalizations.of(context)!;
    final total = counts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return t.backup_snapshot_count_none;

    final parts = <String>[];
    if ((counts['daily'] ?? 0) > 0) {
      parts.add(t.backup_snapshot_count_daily(counts['daily']!));
    }
    if ((counts['weekly'] ?? 0) > 0) {
      parts.add(t.backup_snapshot_count_weekly(counts['weekly']!));
    }
    if ((counts['monthly'] ?? 0) > 0) {
      parts.add(t.backup_snapshot_count_monthly(counts['monthly']!));
    }

    if (parts.isEmpty) return t.backup_snapshot_count_total(total);
    return '$total (${parts.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.backup_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _backupStatus!;
    final dirty = status['dirty'] as bool? ?? false;
    final lastSuccessAt = status['lastSuccessAt'] as int?;
    final nextDueAt = status['nextDueAt'] as int?;
    final lastError = status['lastError'] as String?;
    final hasBackup = status['hasBackup'] as bool? ?? false;
    final snapshotCounts = status['snapshotCounts'] as Map<String, int>? ?? {};

    final cloudEnabled = _cloudStatus?['enabled'] as bool? ?? false;
    final cloudLastExport = _cloudStatus?['lastExportAt'] as int?;
    final cloudError = _cloudStatus?['lastError'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text(t.backup_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        t.backup_status_header,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                    t.backup_last_backup_label,
                    _formatTimestamp(lastSuccessAt),
                  ),
                  if (snapshotCounts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      t.backup_snapshots_available_label,
                      _formatSnapshotCounts(snapshotCounts),
                      color: Colors.blue.shade700,
                    ),
                  ],
                  if (dirty && nextDueAt != null) ...[
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      t.backup_next_scheduled_label,
                      _formatTimestamp(nextDueAt),
                      color: Colors.orange,
                    ),
                  ],
                  if (!dirty) ...[
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      t.backup_status_label,
                      t.backup_status_up_to_date,
                      color: Colors.green,
                    ),
                  ],
                  if (lastError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.backup_last_error(lastError),
                              style: TextStyle(
                                  color: Colors.red.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup Health Status
          if (_backupHealth != null) _buildHealthStatusCard(_backupHealth!),
          if (_backupHealth != null) const SizedBox(height: 16),

          // Outdated Cloud Backup Warning
          if (cloudEnabled &&
              _cloudBackupAgeDays != null &&
              _cloudBackupAgeDays! >= 30) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.backup_cloud_outdated_title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your last cloud export was $_cloudBackupAgeDays days ago. '
                      'Export a fresh backup to keep your cloud storage up to date.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _processing ? null : _exportToCloud,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(t.backup_export_to_cloud_now),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Info Cards - Backup Protection Levels
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        t.backup_internal_protection_title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.backup_internal_protection_message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_done, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        t.backup_device_protection_title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.backup_device_protection_message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        t.backup_external_protection_title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.backup_external_protection_message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Manual Backup Button
          FilledButton.icon(
            onPressed: _processing ? null : _backupNow,
            icon: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.backup),
            label: Text(t.backup_now),
          ),
          const SizedBox(height: 8),
          Text(
            t.backup_create_update_now,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Share/Export Button
          OutlinedButton.icon(
            onPressed: _processing || !hasBackup ? null : _shareBackup,
            icon: const Icon(Icons.ios_share),
            label: Text(t.backup_share),
          ),
          const SizedBox(height: 8),
          Text(
            t.backup_export_to_cloud_storage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            t.backup_export_tip,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.orange,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),

          // Cloud Backup Section
          const Divider(),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                t.backup_cloud_section_header,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: cloudEnabled,
                onChanged: _processing ? null : (_) => _toggleCloudBackup(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.backup_auto_export_prompt,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          if (cloudEnabled) ...[
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_circle,
                            color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Cloud Export Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Last cloud export:',
                      _formatTimestamp(cloudLastExport),
                    ),
                    if (cloudError != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cloudError,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _processing || !hasBackup ? null : _exportToCloud,
              icon: const Icon(Icons.cloud_upload),
              label: Text(t.backup_export_to_cloud_button),
            ),
            const SizedBox(height: 8),
            Text(
              t.backup_export_to_cloud_help,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // Device Backup Help
          Text(
            t.backup_device_section_header,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.backup_device_may_protect,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.backup_device_protection_info,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openDeviceBackupSettings,
                    icon: const Icon(Icons.settings),
                    label: Text(t.backup_open_device_settings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 16),

          // Restore Section
          Text(
            t.backup_restore_section_header,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Restore from internal backup - always show
          OutlinedButton.icon(
            onPressed:
                (_processing || !hasBackup) ? null : _restoreFromInternalBackup,
            icon: const Icon(Icons.restore),
            label: Text(t.backup_restore_from_backup),
          ),
          const SizedBox(height: 8),
          Text(
            hasBackup
                ? t.backup_restore_from_storage
                : t.backup_no_internal_backup,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: hasBackup ? Colors.grey : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _processing ? null : _restoreFromFile,
            icon: const Icon(Icons.folder_open),
            label: Text(t.backup_restore_from_file),
          ),
          const SizedBox(height: 8),
          Text(
            t.backup_restore_from_file_help,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(BackupHealth health) {
    final t = AppLocalizations.of(context)!;
    Color bgColor;
    Color iconColor;
    Color textColor;
    IconData icon;
    String title;
    String description;

    switch (health) {
      case BackupHealth.protected:
        bgColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle;
        title = t.backup_health_protected;
        description = t.backup_health_full_message;
        break;
      case BackupHealth.partial:
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber;
        title = t.backup_health_partial;
        description = t.backup_health_partial_message;
        break;
      case BackupHealth.attention:
        bgColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        textColor = Colors.red.shade900;
        icon = Icons.error;
        title = t.backup_health_partial;
        description =
            'No backup available or backup errors detected. Create a backup now to protect your data.';
        break;
    }

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup Health: $title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.black87,
              fontWeight: color != null ? FontWeight.w500 : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Reset all DB-dependent providers after restore
  void _resetDataLayerAfterRestore() {
    // Invalidate repository providers
    ref.invalidate(itemsRepositoryProvider);
    ref.invalidate(attachmentsRepositoryProvider);

    // Invalidate data list providers
    ref.invalidate(itemsListProvider);

    debugPrint('Data layer reset after restore - all providers invalidated');
  }
}
