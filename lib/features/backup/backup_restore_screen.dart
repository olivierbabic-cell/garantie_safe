import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/db/db_providers.dart';
import 'package:garantie_safe/core/services/cloud_backup_service.dart';
import 'package:garantie_safe/core/widgets/app_buttons.dart';
import 'package:garantie_safe/features/items/items_providers.dart';
import 'package:garantie_safe/features/items/item_edit_screen.dart';
import 'snapshot_chooser_screen.dart';

/// Simplified Backup & Restore screen with clean, reassuring design
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  Map<String, dynamic>? _backupStatus;
  Map<String, dynamic>? _cloudStatus;
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await BackupService.getBackupStatus();
    final cloudStatus = await CloudBackupService.getStatus();
    if (!mounted) return;
    setState(() {
      _backupStatus = status;
      _cloudStatus = cloudStatus;
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

  Future<void> _restoreFromInternalBackup() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SnapshotChooserScreen(),
      ),
    );
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

      ref.read(isRestoringProvider.notifier).state = true;

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

      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        throw Exception('Invalid backup file: not a valid ZIP archive');
      }

      await BackupService.restoreBackup(backupBytes: bytes);

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

  Future<void> _setupCloudBackup() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      final success = await CloudBackupService.setupCloudBackup();

      if (success) {
        await _loadStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.backupCloudConfigured)),
        );
      }
    } catch (e) {
      debugPrint('Cloud backup setup failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.backupCloudSetupError}: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _manualCloudBackup() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _processing = true);

    try {
      final success = await CloudBackupService.performCloudBackup();

      if (success) {
        await _loadStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.backupCloudBackupSuccess)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.backupCloudBackupFailed),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Manual cloud backup failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.backupCloudBackupFailed}: ${e.toString()}'),
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
    final cloudEnabled = _cloudStatus?['enabled'] as bool? ?? false;

    if (cloudEnabled) {
      await _disableCloudBackup();
    } else {
      await _enableCloudBackup();
    }
  }

  Future<void> _enableCloudBackup() async {
    await Prefs.setCloudExportEnabled(true);
    await _loadStatus();
  }

  Future<void> _disableCloudBackup() async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.backupCloudDisable),
        content: Text(t.backupCloudDisableConfirm),
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
  }

  Future<void> _removeCloudBackupSetup() async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.backupCloudDisable),
        content: Text(t.backupCloudDisableConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.remove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CloudBackupService.disable();
      await _loadStatus();
    }
  }

  String _formatTimestamp(int? timestamp) {
    final t = AppLocalizations.of(context)!;
    if (timestamp == null) return t.backup_never;

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return t.backup_time_just_now;
    if (diff.inHours < 1) return t.backup_time_minutes_ago(diff.inMinutes);
    if (diff.inDays < 1) return t.backup_time_hours_ago(diff.inHours);
    if (diff.inDays < 7) return t.backup_time_days_ago(diff.inDays);

    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(t.backup_title),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _backupStatus!;
    final lastSuccessAt = status['lastSuccessAt'] as int?;
    final hasBackup = status['hasBackup'] as bool? ?? false;
    final dirty = status['dirty'] as bool? ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t.backup_title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==================================================
          // 1. BACKUP STATUS
          // ==================================================
          _buildStatusCard(t, hasBackup, dirty, lastSuccessAt),

          const SizedBox(height: 32),

          // ==================================================
          // 2. PRIMARY ACTIONS
          // ==================================================
          _buildPrimaryActions(t, hasBackup),

          const SizedBox(height: 32),

          // ==================================================
          // 3. CLOUD BACKUP (OPTIONAL)
          // ==================================================
          _buildCloudBackupSection(t),

          const SizedBox(height: 32),

          // ==================================================
          // 4. RESTORE
          // ==================================================
          _buildRestoreSection(t, hasBackup),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    AppLocalizations t,
    bool hasBackup,
    bool dirty,
    int? lastSuccessAt,
  ) {
    final isSafe = hasBackup && !dirty;
    final statusColor = isSafe ? Colors.green : Colors.orange;
    final statusIcon = isSafe ? Icons.check_circle : Icons.info_outline;
    final statusText = isSafe ? t.backupStatusSafe : t.backupStatusNeedsBackup;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor.shade700,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: statusColor.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                t.backupLastBackupLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatTimestamp(lastSuccessAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(AppLocalizations t, bool hasBackup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          label: t.backup_now,
          onPressed: _backupNow,
          icon: Icons.backup,
          isLoading: _processing,
        ),
        const SizedBox(height: 12),
        AppSecondaryButton(
          label: t.backup_share,
          onPressed: _processing || !hasBackup ? null : _shareBackup,
          icon: Icons.ios_share,
        ),
      ],
    );
  }

  Widget _buildCloudBackupSection(AppLocalizations t) {
    final cloudConfigured = _cloudStatus?['configured'] as bool? ?? false;

    if (!cloudConfigured) {
      // STATE 1: Not configured - show setup button
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.backupCloudTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.backupCloudSetupDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSoftButton(
              label: t.backupCloudSetup,
              onPressed: _processing ? null : _setupCloudBackup,
              icon: Icons.folder_open,
            ),
          ],
        ),
      );
    }

    // STATE 2: Configured - show folder, toggle, and options
    final cloudEnabled = _cloudStatus?['enabled'] as bool? ?? false;
    final folderName = _cloudStatus?['folderName'] as String?;
    final folderPath = _cloudStatus?['folderPath'] as String?;
    final lastExportAt = _cloudStatus?['lastExportAt'] as int?;
    final lastError = _cloudStatus?['lastError'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and toggle
          Row(
            children: [
              Icon(
                Icons.cloud_done,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.backupCloudAutomatic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: cloudEnabled,
                onChanged: _processing ? null : (_) => _toggleCloudBackup(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Folder path
          Row(
            children: [
              Icon(Icons.folder, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.backupCloudFolderLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      folderName ?? folderPath ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Last backup timestamp
          if (lastExportAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.backupCloudLastBackup,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(lastExportAt),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Error message
          if (lastError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastError,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _manualCloudBackup,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: Text(
                    t.backupCloudBackupNow,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _processing ? null : _setupCloudBackup,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                child: Text(
                  t.backupCloudChangeFolder,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _processing ? null : _removeCloudBackupSetup,
            icon: const Icon(Icons.close, size: 16),
            label: Text(t.backupCloudDisable),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreSection(AppLocalizations t, bool hasBackup) {
    // Maximum button width for centered, premium appearance
    const double maxButtonWidth = 340.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          t.backupRestoreTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),

        // Centered button container
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxButtonWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary restore action
                AppPrimaryButton(
                  label: t.backup_restore_from_backup,
                  onPressed: _processing || !hasBackup
                      ? null
                      : _restoreFromInternalBackup,
                  icon: Icons.history,
                  fullWidth: true,
                ),
                const SizedBox(height: 14),

                // Secondary restore action
                AppSecondaryButton(
                  label: t.backup_restore_from_file,
                  onPressed: _processing ? null : _restoreFromFile,
                  icon: Icons.upload_file,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _resetDataLayerAfterRestore() {
    ref.invalidate(itemsRepositoryProvider);
    ref.invalidate(attachmentsRepositoryProvider);
    ref.invalidate(itemsListProvider);
    debugPrint('Data layer reset after restore - all providers invalidated');
  }
}
