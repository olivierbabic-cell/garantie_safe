import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/core/db/db_providers.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/features/items/items_providers.dart';
import 'package:garantie_safe/home/home_screen.dart';

/// Preview screen for confirming snapshot restore
class SnapshotPreviewScreen extends ConsumerStatefulWidget {
  final SnapshotInfo snapshot;
  final bool isOnboarding;

  const SnapshotPreviewScreen({
    super.key,
    required this.snapshot,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<SnapshotPreviewScreen> createState() =>
      _SnapshotPreviewScreenState();
}

class _SnapshotPreviewScreenState extends ConsumerState<SnapshotPreviewScreen> {
  bool _restoring = false;
  String? _compatibilityStatus;

  @override
  void initState() {
    super.initState();
    _checkCompatibility();
  }

  Future<void> _checkCompatibility() async {
    if (widget.snapshot.metadata == null) {
      setState(() {
        _compatibilityStatus = 'legacy';
      });
      return;
    }

    final status =
        await BackupService.checkBackupCompatibility(widget.snapshot.metadata!);
    if (!mounted) return;
    setState(() {
      _compatibilityStatus = status;
    });
  }

  Future<void> _restore() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _restoring = true);
    ref.read(isRestoringProvider.notifier).state = true;

    try {
      await BackupService.restoreFromSnapshot(widget.snapshot.filePath);

      // Reset data layer
      _resetDataLayerAfterRestore();

      if (!mounted) return;

      // If onboarding, mark as done and navigate to home
      if (widget.isOnboarding) {
        await Prefs.setOnboardingDone(true);

        // Show success and go to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.backup_restored_count(
                  widget.snapshot.metadata?.itemCount ?? 0)),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Show success and return to home
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(t.backup_restore_completed),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.backup_restore_success_message),
              if (widget.snapshot.metadata != null) ...[
                const SizedBox(height: 16),
                Text(
                  t.backup_restored_items(widget.snapshot.metadata!.itemCount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.of(context)
                    .popUntil((route) => route.isFirst); // Go to home
              },
              child: Text(t.ok),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Restore error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.backup_restore_failed_details(e.toString())),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        ref.read(isRestoringProvider.notifier).state = false;
        setState(() => _restoring = false);
      }
    }
  }

  /// Reset all DB-dependent providers after restore
  void _resetDataLayerAfterRestore() {
    ref.invalidate(itemsRepositoryProvider);
    ref.invalidate(itemsListProvider);
    debugPrint('Data layer reset after restore - all providers invalidated');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final metadata = widget.snapshot.metadata;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.backup_restore_title),
      ),
      body: _restoring
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t.backup_restoring),
                  const SizedBox(height: 8),
                  Text(
                    t.backup_restoring_wait,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Snapshot Title Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getIcon(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.snapshot.displayTitle,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.snapshot.isRecommended) ...[
                                        const SizedBox(width: 8),
                                        _buildRecommendedBadge(),
                                      ],
                                      if (widget.snapshot.isEmpty) ...[
                                        const SizedBox(width: 8),
                                        _buildEmptyBadge(),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.snapshot.formattedDate,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
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
                ),
                const SizedBox(height: 16),

                // Backup Contents Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.backup_contents_header,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (metadata != null) ...[
                          _buildInfoRow(
                            Icons.receipt_long,
                            t.backup_info_warranties,
                            metadata.itemCount.toString(),
                            metadata.itemCount == 0
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.attach_file,
                            t.backup_info_attachments,
                            metadata.attachmentCount.toString(),
                            null,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.storage,
                            t.backup_info_size,
                            widget.snapshot.formattedSize,
                            null,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.app_settings_alt,
                            t.backup_info_app_version,
                            metadata.appVersion,
                            null,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.backup,
                            t.backup_info_backup_type,
                            metadata.isAutoBackup
                                ? t.backup_type_automatic
                                : t.backup_type_manual,
                            null,
                          ),
                        ] else ...[
                          _buildInfoRow(
                            Icons.storage,
                            t.backup_info_size,
                            widget.snapshot.formattedSize,
                            null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.backup_legacy_format,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Compatibility Status Card
                if (_compatibilityStatus != null)
                  _buildCompatibilityCard(_compatibilityStatus!),
                if (_compatibilityStatus != null) const SizedBox(height: 16),

                // Warning Card
                Card(
                  color: widget.snapshot.isEmpty
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.snapshot.isEmpty
                                  ? Icons.warning_amber
                                  : Icons.info_outline,
                              color: widget.snapshot.isEmpty
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.snapshot.isEmpty
                                  ? t.backup_warning_header
                                  : t.backup_before_restore_header,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.snapshot.isEmpty
                                    ? Colors.orange.shade900
                                    : Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.snapshot.isEmpty
                              ? t.backup_restore_warning_empty
                              : t.backup_restore_warning_replace,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.snapshot.isEmpty
                                ? Colors.orange.shade900
                                : Colors.blue.shade900,
                          ),
                        ),
                        if (widget.snapshot.isRecommended) ...[
                          const SizedBox(height: 8),
                          Text(
                            t.backup_recommended_contents,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Restore Button
                FilledButton.icon(
                  onPressed: _restore,
                  icon: const Icon(Icons.restore),
                  label: Text(t.backup_restore_this_backup),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        widget.snapshot.isEmpty ? Colors.orange : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(t.cancel),
                ),
              ],
            ),
    );
  }

  Widget _getIcon() {
    IconData icon;
    Color? color;

    switch (widget.snapshot.type) {
      case SnapshotType.current:
        icon = Icons.backup;
        color = Colors.green;
        break;
      case SnapshotType.previous:
        icon = Icons.history;
        color = Colors.orange;
        break;
      case SnapshotType.daily:
        icon = Icons.today;
        color = Colors.blue;
        break;
      case SnapshotType.weekly:
        icon = Icons.date_range;
        color = Colors.purple;
        break;
      case SnapshotType.monthly:
        icon = Icons.calendar_month;
        color = Colors.indigo;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      radius: 24,
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildRecommendedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'Recommended',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Text(
        'Empty',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color? valueColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityCard(String status) {
    Color bgColor;
    Color iconColor;
    Color textColor;
    IconData icon;
    String title;
    String message;

    if (status == 'compatible') {
      bgColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      title = 'Ready to Restore';
      message = 'This backup is compatible with your current app version.';
    } else if (status == 'legacy') {
      bgColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade700;
      textColor = Colors.blue.shade900;
      icon = Icons.info;
      title = 'Legacy Backup';
      message =
          'This is an older backup format. It should restore correctly, but detailed information is not available.';
    } else {
      bgColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade700;
      textColor = Colors.orange.shade900;
      icon = Icons.warning_amber;
      title = 'Compatibility Notice';
      message = status;
    }

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
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
      ),
    );
  }
}
