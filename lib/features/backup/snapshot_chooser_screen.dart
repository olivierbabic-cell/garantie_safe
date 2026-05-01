import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/features/backup/snapshot_preview_screen.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Screen for choosing which snapshot to restore
class SnapshotChooserScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const SnapshotChooserScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<SnapshotChooserScreen> createState() =>
      _SnapshotChooserScreenState();
}

class _SnapshotChooserScreenState extends ConsumerState<SnapshotChooserScreen> {
  List<SnapshotInfo>? _snapshots;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    final snapshots = await BackupService.getAvailableSnapshots();
    if (!mounted) return;
    setState(() {
      _snapshots = snapshots;
      _loading = false;
    });
  }

  void _openSnapshotPreview(SnapshotInfo snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SnapshotPreviewScreen(
          snapshot: snapshot,
          isOnboarding: widget.isOnboarding,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.backup_choose_title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _snapshots == null || _snapshots!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.backup_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.backup_no_backups_title,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.backup_no_backups_subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildSectionedList(t),
    );
  }

  Widget _buildSectionedList(AppLocalizations t) {
    // Group snapshots by section
    final recommended = _snapshots!.where((s) => s.isRecommended).toList();
    final current = _snapshots!
        .where((s) => s.type == SnapshotType.current && !s.isRecommended)
        .toList();
    final previous =
        _snapshots!.where((s) => s.type == SnapshotType.previous).toList();
    final daily =
        _snapshots!.where((s) => s.type == SnapshotType.daily).toList();
    final weekly =
        _snapshots!.where((s) => s.type == SnapshotType.weekly).toList();
    final monthly =
        _snapshots!.where((s) => s.type == SnapshotType.monthly).toList();

    // Sort each group by date descending
    daily.sort((a, b) => b.date.compareTo(a.date));
    weekly.sort((a, b) => b.date.compareTo(a.date));
    monthly.sort((a, b) => b.date.compareTo(a.date));

    // Build recent group (Latest + Previous + Yesterday)
    final recent = <SnapshotInfo>[];
    recent.addAll(current);
    recent.addAll(previous);

    // Find yesterday's backup
    if (daily.isNotEmpty) {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final yesterdaySnapshot = daily.where((s) {
        final date = DateTime(s.date.year, s.date.month, s.date.day);
        return date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;
      }).toList();

      if (yesterdaySnapshot.isNotEmpty) {
        recent.add(yesterdaySnapshot.first);
        daily.remove(yesterdaySnapshot.first);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recommended section
        if (recommended.isNotEmpty) ...[
          _buildSectionHeader(t.snapshot_section_recommended),
          const SizedBox(height: 8),
          ...recommended.map((s) => _buildSnapshotTile(s, t)),
          const SizedBox(height: 16),
        ],

        // Recent section
        if (recent.isNotEmpty) ...[
          _buildSectionHeader(t.snapshot_section_recent),
          const SizedBox(height: 8),
          ...recent.map((s) => _buildSnapshotTile(s, t)),
          const SizedBox(height: 16),
        ],

        // Daily section (only if more than 1, or if it adds clarity)
        if (daily.length > 1) ...[
          _buildSectionHeader(t.snapshot_section_daily),
          const SizedBox(height: 8),
          ...daily.map((s) => _buildSnapshotTile(s, t)),
          const SizedBox(height: 16),
        ],

        // Weekly section
        if (weekly.isNotEmpty) ...[
          _buildSectionHeader(t.snapshot_section_weekly),
          const SizedBox(height: 8),
          ...weekly.map((s) => _buildSnapshotTile(s, t)),
          const SizedBox(height: 16),
        ],

        // Monthly section
        if (monthly.isNotEmpty) ...[
          _buildSectionHeader(t.snapshot_section_monthly),
          const SizedBox(height: 8),
          ...monthly.map((s) => _buildSnapshotTile(s, t)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSnapshotTile(SnapshotInfo snapshot, AppLocalizations t) {
    IconData icon;
    Color? color;

    switch (snapshot.type) {
      case SnapshotType.current:
        icon = Icons.backup;
        color = snapshot.isEmpty ? Colors.orange : Colors.green;
        break;
      case SnapshotType.previous:
        icon = Icons.history;
        color = Colors.blue;
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

    // Determine display title
    String displayTitle = snapshot.displayTitle;
    if (snapshot.type == SnapshotType.current && snapshot.isEmpty) {
      displayTitle = t.snapshot_current_state;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: snapshot.isRecommended ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: snapshot.isRecommended
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          radius: 22,
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (snapshot.isRecommended) ...[
              const SizedBox(width: 6),
              Icon(Icons.star, size: 16, color: Colors.green.shade600),
            ],
            if (snapshot.isEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  t.snapshot_empty_label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            snapshot.displaySubtitle,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => _openSnapshotPreview(snapshot),
      ),
    );
  }
}
