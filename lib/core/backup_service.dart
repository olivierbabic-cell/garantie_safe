import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db/database_manager.dart';
import 'prefs.dart';
import 'services/warranty_notification_scheduler.dart';
import 'services/cloud_backup_service.dart';

/// Backup health status
enum BackupHealth {
  /// Protected: Has internal backup AND recent cloud backup (<30 days)
  protected,

  /// Partial: Has internal backup but no cloud or outdated cloud (>30 days)
  partial,

  /// Attention: No internal backup or errors exist
  attention,
}

/// Bomb-proof backup service with versioned snapshots and crash-safe rotation
///
/// Strategy:
/// - MANDATORY internal backup in app-private storage (not configurable)
/// - Versioned snapshots: current, prev, daily (7), weekly (8), monthly (12)
/// - Snapshots created on app start/resume when dirty flag is set
/// - Crash-safe: write to tmp, validate, rotate atomically
/// - Background best-effort via WorkManager
class BackupService {
  static const String dbFileName = 'garantie_safe.db';
  static const String manifestFileName = 'manifest.json';
  static const String backupsFolder = 'Backups';

  // Fixed backup filenames
  static const String currentBackupFile = 'garantie_safe_backup.gsbackup';
  static const String tempBackupFile = 'garantie_safe_backup.tmp';
  static const String prevBackupFile = 'garantie_safe_backup.prev';

  // Snapshot retention policies
  static const int dailySnapshotsToKeep = 7;
  static const int weeklySnapshotsToKeep = 8;
  static const int monthlySnapshotsToKeep = 12;

  /// Get the backup directory path (always app-private storage)
  static Future<Directory> getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, backupsFolder));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Mark data as changed - sets dirty flag
  /// Call this after every data mutation (item create/update/delete, attachments, etc.)
  /// Snapshot will be created on next app start/resume or background task
  static Future<void> markDataChanged({String reason = 'data_changed'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await Prefs.setBackupDirty(true);
    await Prefs.setBackupLastChangeAt(now);

    debugPrint('Backup: Data changed ($reason), dirty flag set');
  }

  /// Run snapshot routine if dirty flag is set
  /// Call this on app start/resume and from background tasks
  static Future<bool> runSnapshotIfDirty() async {
    try {
      final dirty = await Prefs.getBackupDirty();
      if (!dirty) {
        debugPrint('Snapshot: No pending changes');
        return false;
      }

      debugPrint('Snapshot: Starting snapshot routine...');
      await createSnapshot();
      return true;
    } catch (e) {
      debugPrint('Snapshot: routine failed: $e');
      return false;
    }
  }

  /// Create snapshot - updates current/prev and creates versioned snapshots
  /// Uses crash-safe temp write + validation + rotation
  static Future<void> createSnapshot() async {
    try {
      debugPrint('Snapshot: Starting...');
      final backupDir = await getBackupDirectory();
      final now = DateTime.now();

      // Build backup ZIP bytes (marked as current/auto)
      final backupBytes = await createBackupBytes(
        backupType: 'current',
        isAutoBackup: true,
      );
      debugPrint('Snapshot: Created ${backupBytes.length} bytes');

      // Write to temp file with flush
      final tempFile = File(p.join(backupDir.path, tempBackupFile));
      await tempFile.writeAsBytes(backupBytes, flush: true);
      debugPrint('Snapshot: Wrote to temp file');

      // Validate temp backup
      await _validateBackupFile(tempFile);
      debugPrint('Snapshot: Validated temp file');

      // Rotate current/prev atomically
      await _rotateBackups(backupDir);
      debugPrint('Snapshot: Rotated current/prev');

      // Create versioned snapshots if needed
      await _createVersionedSnapshots(backupDir, backupBytes, now);

      // Cleanup old snapshots
      await _cleanupOldSnapshots(backupDir);

      // Mark success
      final timestamp = now.millisecondsSinceEpoch;
      await Prefs.setBackupDirty(false);
      await Prefs.setBackupLastSuccessAt(timestamp);
      await Prefs.setBackupLastError(null);

      debugPrint(
          'Snapshot: Completed successfully at ${DateTime.fromMillisecondsSinceEpoch(timestamp)}');

      // Try cloud export if enabled (non-blocking)
      tryAutoExportToCloud().catchError((e) {
        debugPrint('Cloud export failed (non-fatal): $e');
      });
    } catch (e, st) {
      final errorMsg = e.toString();
      debugPrint('Snapshot: Failed: $errorMsg\n$st');
      await Prefs.setBackupLastError(errorMsg);
      rethrow;
    }
  }

  /// Create versioned snapshots (daily, weekly, monthly) if they don't exist
  static Future<void> _createVersionedSnapshots(
    Directory backupDir,
    List<int> backupBytes,
    DateTime now,
  ) async {
    // Daily snapshot: daily_YYYY-MM-DD.gsbackup
    final dailyFilename =
        'daily_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.gsbackup';
    final dailyFile = File(p.join(backupDir.path, dailyFilename));
    if (!await dailyFile.exists()) {
      await dailyFile.writeAsBytes(backupBytes, flush: true);
      debugPrint('Snapshot: Created daily snapshot $dailyFilename');
    }

    // Weekly snapshot: weekly_YYYY-WW.gsbackup (ISO week number)
    final weekNumber = _getISOWeekNumber(now);
    final weeklyFilename =
        'weekly_${now.year}-${weekNumber.toString().padLeft(2, '0')}.gsbackup';
    final weeklyFile = File(p.join(backupDir.path, weeklyFilename));
    if (!await weeklyFile.exists()) {
      await weeklyFile.writeAsBytes(backupBytes, flush: true);
      debugPrint('Snapshot: Created weekly snapshot $weeklyFilename');
    }

    // Monthly snapshot: monthly_YYYY-MM.gsbackup
    final monthlyFilename =
        'monthly_${now.year}-${now.month.toString().padLeft(2, '0')}.gsbackup';
    final monthlyFile = File(p.join(backupDir.path, monthlyFilename));
    if (!await monthlyFile.exists()) {
      await monthlyFile.writeAsBytes(backupBytes, flush: true);
      debugPrint('Snapshot: Created monthly snapshot $monthlyFilename');
    }
  }

  /// Get ISO week number for a date
  static int _getISOWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Cleanup old snapshots - keep only last N of each type
  static Future<void> _cleanupOldSnapshots(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();

      // Group snapshots by type
      final daily = <File>[];
      final weekly = <File>[];
      final monthly = <File>[];

      for (final entity in files) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.startsWith('daily_') && name.endsWith('.gsbackup')) {
          daily.add(entity);
        } else if (name.startsWith('weekly_') && name.endsWith('.gsbackup')) {
          weekly.add(entity);
        } else if (name.startsWith('monthly_') && name.endsWith('.gsbackup')) {
          monthly.add(entity);
        }
      }

      // Sort by name (descending) - newer files first
      daily.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
      weekly.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
      monthly.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));

      // Delete old snapshots
      await _deleteOldFiles(daily, dailySnapshotsToKeep);
      await _deleteOldFiles(weekly, weeklySnapshotsToKeep);
      await _deleteOldFiles(monthly, monthlySnapshotsToKeep);

      debugPrint(
          'Snapshot: Cleanup complete - keeping ${daily.length.clamp(0, dailySnapshotsToKeep)} daily, ${weekly.length.clamp(0, weeklySnapshotsToKeep)} weekly, ${monthly.length.clamp(0, monthlySnapshotsToKeep)} monthly');
    } catch (e) {
      debugPrint('Snapshot: Cleanup failed: $e');
      // Non-fatal - continue
    }
  }

  /// Delete files beyond the retention limit
  static Future<void> _deleteOldFiles(List<File> files, int keepCount) async {
    if (files.length <= keepCount) return;

    for (var i = keepCount; i < files.length; i++) {
      try {
        await files[i].delete();
        debugPrint(
            'Snapshot: Deleted old snapshot ${p.basename(files[i].path)}');
      } catch (e) {
        debugPrint(
            'Snapshot: Failed to delete ${p.basename(files[i].path)}: $e');
      }
    }
  }

  /// Validate backup file: size, PK header, ZIP decode, metadata
  static Future<void> _validateBackupFile(File backupFile) async {
    if (!await backupFile.exists()) {
      throw Exception('Backup file does not exist');
    }

    final bytes = await backupFile.readAsBytes();
    if (bytes.length < 4) {
      throw Exception('Backup file too small: ${bytes.length} bytes');
    }

    // Validate ZIP header (PK signature)
    if (bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw Exception('Invalid ZIP header: not a valid backup file');
    }

    // Decode and verify archive structure
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);

      // Verify backup_metadata.json exists (new format)
      final metadataFile = archive.files
          .where((f) => f.name == 'backup_metadata.json')
          .firstOrNull;

      // If no metadata, check for legacy manifest
      if (metadataFile == null) {
        final manifestFile =
            archive.files.where((f) => f.name == manifestFileName).firstOrNull;
        if (manifestFile == null) {
          throw Exception('Invalid backup: metadata missing');
        }
      }

      // Verify DB exists
      final dbFile =
          archive.files.where((f) => f.name == 'db/$dbFileName').firstOrNull;
      if (dbFile == null) {
        throw Exception('Invalid backup: database missing');
      }
    } catch (e) {
      throw Exception('Backup validation failed: $e');
    }
  }

  /// Read metadata from a backup file
  static Future<BackupMetadata?> _readBackupMetadata(File backupFile) async {
    try {
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Try to read backup_metadata.json
      final metadataFile = archive.files
          .where((f) => f.name == 'backup_metadata.json')
          .firstOrNull;

      if (metadataFile != null) {
        final content = utf8.decode(metadataFile.content as List<int>);
        final json = jsonDecode(content) as Map<String, dynamic>;
        return BackupMetadata.fromJson(json);
      }

      // Fall back to legacy manifest if available
      final manifestFile =
          archive.files.where((f) => f.name == manifestFileName).firstOrNull;
      if (manifestFile != null) {
        final content = utf8.decode(manifestFile.content as List<int>);
        final json = jsonDecode(content) as Map<String, dynamic>;
        // Create metadata from legacy manifest
        return BackupMetadata(
          createdAt: json['createdAt'] as int? ?? 0,
          backupType: 'legacy',
          itemCount: 0, // Unknown in legacy format
          attachmentCount: json['attachmentsCount'] as int? ?? 0,
          appVersion: json['appVersion'] as String? ?? '1.0.0',
          schemaVersion: json['schemaVersion'] as int? ?? 4,
          isAutoBackup: false,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error reading backup metadata: $e');
      return null;
    }
  }

  /// Create a backup ZIP archive with metadata
  static Future<Uint8List> createBackupBytes({
    required String backupType,
    required bool isAutoBackup,
  }) async {
    final archive = Archive();
    int attachmentsCount = 0;
    int itemCount = 0;

    // Get database path and attachments directory
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, dbFileName);
    final attachmentsDir = await getAttachmentsDirectory();

    // Query item count for metadata
    final db = await DatabaseManager.instance.getDatabase();
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM items WHERE deleted_at IS NULL');
    itemCount = (result.first['count'] as int?) ?? 0;

    // Add database file
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found at: $dbPath');
    }

    final dbBytes = await dbFile.readAsBytes();
    if (dbBytes.isEmpty) {
      throw Exception('Database file is empty');
    }

    archive.addFile(ArchiveFile('db/$dbFileName', dbBytes.length, dbBytes));
    debugPrint('Backup: Added DB (${dbBytes.length} bytes)');

    // Add attachments
    if (await attachmentsDir.exists()) {
      await for (final entity in attachmentsDir.list(recursive: true)) {
        if (entity is File) {
          try {
            final bytes = await entity.readAsBytes();
            final filename = p.basename(entity.path);
            final relativePath = 'attachments/$filename';
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
            attachmentsCount++;
          } catch (e) {
            debugPrint('Warning: Could not add attachment ${entity.path}: $e');
          }
        }
      }
    }
    debugPrint('Backup: Added $attachmentsCount attachments, $itemCount items');

    // Create app_settings.json with comprehensive settings
    final appSettings = {
      'onboarding_done': await Prefs.getOnboardingDone(),
      'payment_methods': await Prefs.getPaymentMethods(),
      'language': await Prefs.getLanguage(),
      'dark_mode': await Prefs.getDarkMode(),
      'notifications_enabled': await Prefs.getNotificationsEnabled(),
      'remind_30_days': await Prefs.getRemind30Days(),
      'remind_7_days': await Prefs.getRemind7Days(),
      'remind_on_expiry_day': await Prefs.getRemindOnExpiryDay(),
      'reminder_lead_time_days': await Prefs.getReminderLeadTimeDays(),
      'reminder_time_hour': await Prefs.getReminderTimeHour(),
      'reminder_time_minute': await Prefs.getReminderTimeMinute(),
      'app_lock_enabled': await Prefs.getAppLockEnabled(),
      'cloud_export_enabled': await Prefs.getCloudExportEnabled(),
      'cloud_encryption_enabled': await Prefs.getCloudEncryptionEnabled(),
      // Note: We don't backup cloud folder URI/path (security)
      // Note: We don't backup encryption password/key (security)
    };
    final appSettingsJson = utf8.encode(json.encode(appSettings));
    archive.addFile(ArchiveFile(
        'app_settings.json', appSettingsJson.length, appSettingsJson));
    debugPrint('Backup: Added app_settings.json');

    // Create backup_metadata.json with extended information
    final metadata = BackupMetadata(
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      backupType: backupType,
      itemCount: itemCount,
      attachmentCount: attachmentsCount,
      appVersion: '1.0.0',
      schemaVersion: 4,
      isAutoBackup: isAutoBackup,
    );
    final metadataJson = utf8.encode(json.encode(metadata.toJson()));
    archive.addFile(
        ArchiveFile('backup_metadata.json', metadataJson.length, metadataJson));

    // Create manifest (legacy, keep for compatibility)
    final manifest = {
      'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'schemaVersion': 4,
      'appVersion': '1.0.0',
      'attachmentsCount': attachmentsCount,
      'dbFileName': dbFileName,
    };
    final manifestJson = utf8.encode(json.encode(manifest));
    archive.addFile(
        ArchiveFile(manifestFileName, manifestJson.length, manifestJson));

    // Encode ZIP
    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);
    if (zipBytes == null || zipBytes.isEmpty) {
      throw Exception('Failed to create backup archive');
    }

    // Validate ZIP header
    if (zipBytes.length < 4 || zipBytes[0] != 0x50 || zipBytes[1] != 0x4B) {
      throw Exception('Invalid ZIP format: missing PK header');
    }

    return Uint8List.fromList(zipBytes);
  }

  /// Rotate backups atomically: current → prev, temp → current
  static Future<void> _rotateBackups(Directory backupDir) async {
    final currentFile = File(p.join(backupDir.path, currentBackupFile));
    final prevFile = File(p.join(backupDir.path, prevBackupFile));
    final tempFile = File(p.join(backupDir.path, tempBackupFile));

    // Move current to prev (replace old prev)
    if (await currentFile.exists()) {
      await currentFile.rename(prevFile.path);
      debugPrint('Backup: Rotated current → prev');
    }

    // Move temp to current
    if (await tempFile.exists()) {
      await tempFile.rename(currentFile.path);
      debugPrint('Backup: Rotated temp → current');
    }
  }

  /// Get the directory where item attachments are stored
  static Future<Directory> getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// Share/export backup - creates temp copy in cache and shares it
  /// NEVER shares from Downloads or public storage
  /// Share backup file to cloud, email, or external storage
  /// Returns true if file was shared successfully, false if user cancelled
  static Future<bool> shareBackup() async {
    final backupDir = await getBackupDirectory();
    final currentFile = File(p.join(backupDir.path, currentBackupFile));

    if (!await currentFile.exists()) {
      throw Exception('No backup file exists to share. Create a backup first.');
    }

    // Create temp copy in cache directory (will be cleaned up automatically)
    final cacheDir = await getTemporaryDirectory();
    final tempShareFile = File(p.join(cacheDir.path, currentBackupFile));

    await currentFile.copy(tempShareFile.path);
    debugPrint('Export: Copied to cache for sharing');

    // Share the temp file
    final result = await Share.shareXFiles(
      [XFile(tempShareFile.path)],
      text: 'Garantie Safe Backup - ${DateTime.now().toLocal()}',
    );

    // Check if user actually shared (not cancelled)
    if (result.status == ShareResultStatus.success) {
      // Track export time only if successful
      await Prefs.setLastExportedAt(DateTime.now().millisecondsSinceEpoch);
      debugPrint('Export: Shared successfully');
      return true;
    } else {
      debugPrint('Export: Cancelled by user (${result.status})');
      return false;
    }
  }

  /// Export backup as bytes (for cloud backup service)
  /// Returns backup file bytes, or null if no backup exists
  static Future<List<int>?> exportBackupBytes() async {
    final backupDir = await getBackupDirectory();
    final currentFile = File(p.join(backupDir.path, currentBackupFile));

    if (!await currentFile.exists()) {
      return null;
    }

    return await currentFile.readAsBytes();
  }

  /// Export backup to cloud folder (simplified approach)
  /// User shares the file and can save to cloud manually
  /// Returns true if file was shared successfully, false if user cancelled
  static Future<bool> exportToCloudFolder() async {
    try {
      // Use the existing shareBackup functionality
      // User can save to Google Drive, iCloud Drive, etc. from share sheet
      final success = await shareBackup();

      if (success) {
        // Track cloud export time and clear errors only if successful
        await Prefs.setCloudExportLastAt(DateTime.now().millisecondsSinceEpoch);
        await Prefs.setCloudExportLastError(null);
        debugPrint('Cloud export: Shared successfully');
      }

      return success;
    } catch (e) {
      // Track error for UI display
      await Prefs.setCloudExportLastError(e.toString());
      debugPrint('Cloud export failed: $e');
      rethrow;
    }
  }

  /// Auto-export to cloud if enabled (called after snapshot creation)
  static Future<void> tryAutoExportToCloud() async {
    try {
      final enabled = await Prefs.getCloudExportEnabled();
      if (!enabled) {
        debugPrint('Cloud export: Disabled');
        return;
      }

      final folderPath = await Prefs.getCloudExportFolderPath();
      if (folderPath == null || folderPath.isEmpty) {
        debugPrint('Cloud export: Not configured (no folder selected)');
        return;
      }

      debugPrint('Cloud export: Auto-export triggered');

      // Perform actual cloud backup
      final success = await CloudBackupService.performCloudBackup();

      if (success) {
        debugPrint('Cloud export: Successfully written to cloud folder');
        // Cleanup old backups in background
        CloudBackupService.cleanupOldBackups().catchError((e) {
          debugPrint('Cloud cleanup failed: $e');
        });
      } else {
        debugPrint('Cloud export: Failed - see error in CloudBackupService');
      }
    } catch (e) {
      // Never fail snapshot creation due to cloud export errors
      debugPrint('Cloud export check failed: $e');
      await Prefs.setCloudExportLastError(e.toString());
    }
  }

  /// Check if cloud export is properly configured
  static Future<bool> isCloudExportConfigured() async {
    final enabled = await Prefs.getCloudExportEnabled();
    // In full implementation, would also check for folder URI
    return enabled;
  }

  /// Get cloud export status for UI display
  static Future<Map<String, dynamic>> getCloudExportStatus() async {
    return {
      'enabled': await Prefs.getCloudExportEnabled(),
      'lastExportAt': await Prefs.getCloudExportLastAt(),
      'lastError': await Prefs.getCloudExportLastError(),
    };
  }

  /// Check if internal backup exists (current or prev)
  static Future<bool> hasInternalBackup() async {
    try {
      final backupDir = await getBackupDirectory();
      final currentFile = File(p.join(backupDir.path, currentBackupFile));
      final prevFile = File(p.join(backupDir.path, prevBackupFile));

      final currentExists =
          await currentFile.exists() && await currentFile.length() > 0;
      final prevExists = await prevFile.exists() && await prevFile.length() > 0;

      return currentExists || prevExists;
    } catch (e) {
      debugPrint('Error checking internal backup: $e');
      return false;
    }
  }

  /// Get list of all available snapshots for restore chooser
  static Future<List<SnapshotInfo>> getAvailableSnapshots() async {
    try {
      final backupDir = await getBackupDirectory();
      final List<SnapshotInfo> snapshots = [];

      // Add current
      final currentFile = File(p.join(backupDir.path, currentBackupFile));
      if (await currentFile.exists()) {
        final stat = await currentFile.stat();
        final metadata = await _readBackupMetadata(currentFile);
        snapshots.add(SnapshotInfo(
          name: 'Latest',
          filename: currentBackupFile,
          filePath: currentFile.path,
          type: SnapshotType.current,
          date: stat.modified,
          size: stat.size,
          metadata: metadata,
          isEmpty: metadata?.itemCount == 0,
        ));
      }

      // Add prev
      final prevFile = File(p.join(backupDir.path, prevBackupFile));
      if (await prevFile.exists()) {
        final stat = await prevFile.stat();
        final metadata = await _readBackupMetadata(prevFile);
        snapshots.add(SnapshotInfo(
          name: 'Previous',
          filename: prevBackupFile,
          filePath: prevFile.path,
          type: SnapshotType.previous,
          date: stat.modified,
          size: stat.size,
          metadata: metadata,
        ));
      }

      // Add all versioned snapshots
      final files = await backupDir.list().toList();
      for (final entity in files) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);

        SnapshotType? type;
        String displayName = name;
        DateTime? snapshotDate;

        if (name.startsWith('daily_') && name.endsWith('.gsbackup')) {
          type = SnapshotType.daily;
          // Parse date from filename: daily_YYYY-MM-DD.gsbackup
          final dateStr = name.substring(6, name.length - 9);
          try {
            final parts = dateStr.split('-');
            snapshotDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } catch (e) {
            debugPrint('Error parsing daily snapshot date: $e');
          }
        } else if (name.startsWith('weekly_') && name.endsWith('.gsbackup')) {
          type = SnapshotType.weekly;
          // Parse week from filename: weekly_YYYY-WW.gsbackup
          final weekStr = name.substring(7, name.length - 9);
          try {
            final parts = weekStr.split('-');
            final year = int.parse(parts[0]);
            final week = int.parse(parts[1]);
            // Approximate date - first day of that ISO week
            snapshotDate = _getDateFromISOWeek(year, week);
          } catch (e) {
            debugPrint('Error parsing weekly snapshot date: $e');
          }
        } else if (name.startsWith('monthly_') && name.endsWith('.gsbackup')) {
          type = SnapshotType.monthly;
          // Parse month from filename: monthly_YYYY-MM.gsbackup
          final monthStr = name.substring(8, name.length - 9);
          try {
            final parts = monthStr.split('-');
            snapshotDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              1,
            );
          } catch (e) {
            debugPrint('Error parsing monthly snapshot date: $e');
          }
        }

        if (type != null) {
          final stat = await entity.stat();
          final metadata = await _readBackupMetadata(entity);
          snapshots.add(SnapshotInfo(
            name: displayName,
            filename: name,
            filePath: entity.path,
            type: type,
            date: snapshotDate ?? stat.modified,
            size: stat.size,
            metadata: metadata,
          ));
        }
      }

      // Calculate recommendations
      _calculateRecommendations(snapshots);

      // Sort: recommended first, then current, prev, then by date descending
      snapshots.sort((a, b) {
        if (a.isRecommended && !b.isRecommended) return -1;
        if (!a.isRecommended && b.isRecommended) return 1;
        if (a.type == SnapshotType.current) return -1;
        if (b.type == SnapshotType.current) return 1;
        if (a.type == SnapshotType.previous) return -1;
        if (b.type == SnapshotType.previous) return 1;
        return b.date.compareTo(a.date);
      });

      return snapshots;
    } catch (e) {
      debugPrint('Error listing snapshots: $e');
      return [];
    }
  }

  /// Calculate which snapshot should be recommended
  static void _calculateRecommendations(List<SnapshotInfo> snapshots) {
    // Find current and previous snapshots
    final current =
        snapshots.where((s) => s.type == SnapshotType.current).firstOrNull;
    final previous =
        snapshots.where((s) => s.type == SnapshotType.previous).firstOrNull;

    // If current is empty and previous has items, recommend previous
    if (current != null && previous != null) {
      if (current.isEmpty && (previous.metadata?.itemCount ?? 0) > 0) {
        final index = snapshots.indexOf(previous);
        snapshots[index] = SnapshotInfo(
          name: previous.name,
          filename: previous.filename,
          filePath: previous.filePath,
          type: previous.type,
          date: previous.date,
          size: previous.size,
          metadata: previous.metadata,
          isRecommended: true,
          isEmpty: false,
        );
        return;
      }
    }

    // Otherwise, recommend the most recent non-empty snapshot (excluding current if empty)
    final candidates = snapshots.where((s) {
      if (s.type == SnapshotType.current && s.isEmpty) return false;
      return (s.metadata?.itemCount ?? 0) > 0;
    }).toList();

    if (candidates.isNotEmpty) {
      // Sort by date descending
      candidates.sort((a, b) => b.date.compareTo(a.date));
      final recommended = candidates.first;

      // Only mark as recommended if it's not current
      if (recommended.type != SnapshotType.current) {
        final index = snapshots.indexOf(recommended);
        snapshots[index] = SnapshotInfo(
          name: recommended.name,
          filename: recommended.filename,
          filePath: recommended.filePath,
          type: recommended.type,
          date: recommended.date,
          size: recommended.size,
          metadata: recommended.metadata,
          isRecommended: true,
          isEmpty: false,
        );
      }
    }
  }

  /// Get date from ISO week number
  static DateTime _getDateFromISOWeek(int year, int week) {
    // January 4th is always in week 1
    final jan4 = DateTime(year, 1, 4);
    final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
    return week1Monday.add(Duration(days: (week - 1) * 7));
  }

  /// Get count of available snapshots by type
  static Future<Map<String, int>> getSnapshotCounts() async {
    final snapshots = await getAvailableSnapshots();
    return {
      'current': snapshots.where((s) => s.type == SnapshotType.current).length,
      'previous':
          snapshots.where((s) => s.type == SnapshotType.previous).length,
      'daily': snapshots.where((s) => s.type == SnapshotType.daily).length,
      'weekly': snapshots.where((s) => s.type == SnapshotType.weekly).length,
      'monthly': snapshots.where((s) => s.type == SnapshotType.monthly).length,
      'total': snapshots.length,
    };
  }

  /// Restore from specific snapshot by file path
  static Future<void> restoreFromSnapshot(String snapshotFilePath) async {
    await restoreBackup(backupFilePath: snapshotFilePath);
  }

  /// Restore from internal backup (current, fallback to prev if fails)
  static Future<void> restoreInternalBackup() async {
    final backupDir = await getBackupDirectory();
    final currentFile = File(p.join(backupDir.path, currentBackupFile));
    final prevFile = File(p.join(backupDir.path, prevBackupFile));

    // Try current backup first
    if (await currentFile.exists()) {
      try {
        debugPrint('Restore: Attempting from current backup...');
        await restoreBackup(backupFilePath: currentFile.path);
        debugPrint('Restore: Success from current backup');
        return;
      } catch (e) {
        debugPrint('Restore: Current backup failed: $e');
        // Fall through to try prev
      }
    }

    // Fallback to prev backup
    if (await prevFile.exists()) {
      debugPrint('Restore: Attempting from previous backup...');
      await restoreBackup(backupFilePath: prevFile.path);
      debugPrint('Restore: Success from previous backup');
      return;
    }

    throw Exception('No internal backup found');
  }

  /// Restore from backup file path or bytes
  static Future<void> restoreBackup(
      {String? backupFilePath, List<int>? backupBytes}) async {
    if (backupFilePath == null && backupBytes == null) {
      throw Exception('Either backupFilePath or backupBytes must be provided');
    }

    List<int> bytes;
    if (backupBytes != null) {
      bytes = backupBytes;
    } else {
      final backupFile = File(backupFilePath!);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }
      bytes = await backupFile.readAsBytes();
    }

    if (bytes.isEmpty) {
      throw Exception('Backup file is empty');
    }

    // Validate ZIP header
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw Exception('Invalid backup file: not a valid ZIP archive');
    }

    // Decode archive
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (e) {
      throw Exception('Failed to decode backup file: $e');
    }

    // Verify manifest and DB
    final manifestFile =
        archive.files.where((f) => f.name == manifestFileName).firstOrNull;
    if (manifestFile == null) {
      throw Exception('Invalid backup: manifest.json missing');
    }

    final dbArchiveFile =
        archive.files.where((f) => f.name == 'db/$dbFileName').firstOrNull;
    if (dbArchiveFile == null) {
      throw Exception('Invalid backup: database file missing');
    }

    // Mark restore as in progress - prevents database access
    final dbManager = DatabaseManager.instance;
    dbManager.setRestoring(true);

    try {
      // Close database
      debugPrint('Restore: Closing database...');
      await dbManager.closeDatabase();

      // Restore files
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDir.path, dbFileName);
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));

      // Delete existing database
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Clear existing attachments
      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
      }
      await attachmentsDir.create(recursive: true);

      // Extract database
      final dbData = dbArchiveFile.content as List<int>;
      await dbFile.writeAsBytes(dbData, flush: true);
      debugPrint('Restore: Wrote database (${dbData.length} bytes)');

      // Extract attachments
      int restoredAttachments = 0;
      for (final file in archive.files) {
        if (file.name.startsWith('attachments/') && file.isFile) {
          final filename = p.basename(file.name);
          final attachmentPath = p.join(attachmentsDir.path, filename);
          final attachmentFile = File(attachmentPath);
          final data = file.content as List<int>;
          await attachmentFile.writeAsBytes(data, flush: true);
          restoredAttachments++;
        }
      }
      debugPrint('Restore: Restored $restoredAttachments attachments');

      // Restore app settings (new format) or prefs (legacy format)
      final appSettingsFile =
          archive.files.where((f) => f.name == 'app_settings.json').firstOrNull;
      final prefsFile =
          archive.files.where((f) => f.name == 'prefs.json').firstOrNull;

      if (appSettingsFile != null) {
        // New format: comprehensive app_settings.json
        final settingsContent =
            utf8.decode(appSettingsFile.content as List<int>);
        final settings = json.decode(settingsContent) as Map<String, dynamic>;
        await _restoreAppSettings(settings);
        debugPrint('Restore: App settings restored (new format)');
      } else if (prefsFile != null) {
        // Legacy format: prefs.json
        final prefsContent = utf8.decode(prefsFile.content as List<int>);
        final prefs = json.decode(prefsContent) as Map<String, dynamic>;
        await _restoreAppSettings(prefs);
        debugPrint('Restore: App settings restored (legacy format)');
      }

      // Reopen database with fresh instance
      debugPrint('Restore: Reopening database...');
      await dbManager.reopenDatabase();

      // Reschedule all warranty notifications for restored items
      debugPrint(
          'Restore: Rescheduling notifications for all restored items...');
      await WarrantyNotificationScheduler.rescheduleAllActiveItems();
      debugPrint('Restore: Notifications rescheduled');

      // Mark data as changed to schedule a new backup 24h from now
      await markDataChanged(reason: 'restore_completed');

      // Update restore timestamp
      await Prefs.setLastRestoreAt(DateTime.now().millisecondsSinceEpoch);

      debugPrint('Restore: Complete!');
    } finally {
      // Always clear restore flag
      dbManager.setRestoring(false);
    }
  }

  /// Restore app settings from backup
  /// Handles both new app_settings.json and legacy prefs.json formats
  /// Note: Does NOT restore cloud folder URI/path or encryption keys (security)
  static Future<void> _restoreAppSettings(Map<String, dynamic> settings) async {
    // Onboarding
    if (settings.containsKey('onboarding_done')) {
      await Prefs.setOnboardingDone(settings['onboarding_done'] as bool);
    }

    // Payment methods
    if (settings.containsKey('payment_methods')) {
      final methods =
          (settings['payment_methods'] as List?)?.cast<String>() ?? [];
      await Prefs.setPaymentMethods(methods);
    }

    // Language
    if (settings.containsKey('language')) {
      await Prefs.setLanguage(settings['language'] as String?);
    }

    // Dark mode
    if (settings.containsKey('dark_mode')) {
      await Prefs.setDarkMode(settings['dark_mode'] as bool? ?? false);
    }

    // Notification settings
    if (settings.containsKey('notifications_enabled')) {
      await Prefs.setNotificationsEnabled(
          settings['notifications_enabled'] as bool? ?? true);
    }
    if (settings.containsKey('remind_30_days')) {
      await Prefs.setRemind30Days(settings['remind_30_days'] as bool? ?? true);
    }
    if (settings.containsKey('remind_7_days')) {
      await Prefs.setRemind7Days(settings['remind_7_days'] as bool? ?? true);
    }
    if (settings.containsKey('remind_on_expiry_day')) {
      await Prefs.setRemindOnExpiryDay(
          settings['remind_on_expiry_day'] as bool? ?? true);
    }
    if (settings.containsKey('reminder_lead_time_days')) {
      await Prefs.setReminderLeadTimeDays(
          settings['reminder_lead_time_days'] as int? ?? 7);
    }
    if (settings.containsKey('reminder_time_hour')) {
      await Prefs.setReminderTimeHour(
          settings['reminder_time_hour'] as int? ?? 9);
    }
    if (settings.containsKey('reminder_time_minute')) {
      await Prefs.setReminderTimeMinute(
          settings['reminder_time_minute'] as int? ?? 0);
    }

    // Security settings
    if (settings.containsKey('app_lock_enabled')) {
      await Prefs.setAppLockEnabled(
          settings['app_lock_enabled'] as bool? ?? true);
    }

    // Cloud backup settings (enabled flag only, not folder paths)
    if (settings.containsKey('cloud_export_enabled')) {
      await Prefs.setCloudExportEnabled(
          settings['cloud_export_enabled'] as bool? ?? false);
    }
    if (settings.containsKey('cloud_encryption_enabled')) {
      await Prefs.setCloudEncryptionEnabled(
          settings['cloud_encryption_enabled'] as bool? ?? true);
    }

    debugPrint('Restore: App settings restored');
  }

  /// Get backup status summary for UI
  static Future<Map<String, dynamic>> getBackupStatus() async {
    final dirty = await Prefs.getBackupDirty();
    final lastChangeAt = await Prefs.getBackupLastChangeAt();
    final nextDueAt = await Prefs.getBackupNextDueAt();
    final lastSuccessAt = await Prefs.getBackupLastSuccessAt();
    final lastError = await Prefs.getBackupLastError();
    final hasBackup = await hasInternalBackup();
    final snapshotCounts = await getSnapshotCounts();

    return {
      'dirty': dirty,
      'lastChangeAt': lastChangeAt,
      'nextDueAt': nextDueAt,
      'lastSuccessAt': lastSuccessAt,
      'lastError': lastError,
      'hasBackup': hasBackup,
      'snapshotCounts': snapshotCounts,
    };
  }

  /// Get backup health status for UI display
  static Future<BackupHealth> getBackupHealth() async {
    final hasBackup = await hasInternalBackup();
    final lastError = await Prefs.getBackupLastError();

    // Attention: No internal backup or errors exist
    if (!hasBackup || (lastError != null && lastError.isNotEmpty)) {
      return BackupHealth.attention;
    }

    // Check cloud backup status
    final cloudEnabled = await Prefs.getCloudExportEnabled();
    final cloudLastAt = await Prefs.getCloudExportLastAt();

    if (cloudEnabled && cloudLastAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceCloudBackup = (now - cloudLastAt) / (1000 * 60 * 60 * 24);

      // Protected: Has internal backup AND recent cloud backup (<30 days)
      if (daysSinceCloudBackup < 30) {
        return BackupHealth.protected;
      }
    }

    // Partial: Has internal backup but no cloud or outdated cloud (>30 days)
    return BackupHealth.partial;
  }

  /// Get cloud backup age in days (null if never backed up)
  static Future<int?> getCloudBackupAgeDays() async {
    final cloudLastAt = await Prefs.getCloudExportLastAt();
    if (cloudLastAt == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSince = (now - cloudLastAt) / (1000 * 60 * 60 * 24);
    return daysSince.floor();
  }

  /// Check if a backup is compatible with the current app version
  static Future<String> checkBackupCompatibility(
      BackupMetadata metadata) async {
    // Check format version
    if (metadata.backupFormatVersion > 1) {
      return 'This backup was created with a newer app version. Please update the app.';
    }

    // Check schema version
    if (metadata.schemaVersion > 4) {
      return 'This backup was created with a newer database version. Please update the app.';
    } else if (metadata.schemaVersion < 4) {
      return 'This backup was created with an older app version (v${metadata.appVersion}). It may be missing some features.';
    }

    // All good
    return 'compatible';
  }
}

/// Snapshot types for versioned backups
enum SnapshotType {
  current,
  previous,
  daily,
  weekly,
  monthly,
}

/// Backup metadata stored inside each backup ZIP
class BackupMetadata {
  final int createdAt;
  final String backupType;
  final int itemCount;
  final int attachmentCount;
  final String appVersion;
  final int schemaVersion;
  final bool isAutoBackup;
  final int backupFormatVersion;

  BackupMetadata({
    required this.createdAt,
    required this.backupType,
    required this.itemCount,
    required this.attachmentCount,
    required this.appVersion,
    required this.schemaVersion,
    required this.isAutoBackup,
    this.backupFormatVersion = 1,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      createdAt: json['createdAt'] as int? ?? 0,
      backupType: json['backupType'] as String? ?? 'unknown',
      itemCount: json['itemCount'] as int? ?? 0,
      attachmentCount: json['attachmentCount'] as int? ?? 0,
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      schemaVersion: json['schemaVersion'] as int? ?? 4,
      isAutoBackup: json['isAutoBackup'] as bool? ?? false,
      backupFormatVersion: json['backupFormatVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt,
        'backupType': backupType,
        'itemCount': itemCount,
        'attachmentCount': attachmentCount,
        'appVersion': appVersion,
        'schemaVersion': schemaVersion,
        'isAutoBackup': isAutoBackup,
        'backupFormatVersion': backupFormatVersion,
      };
}

/// Information about a backup snapshot
class SnapshotInfo {
  final String name;
  final String filename;
  final String filePath;
  final SnapshotType type;
  final DateTime date;
  final int size;
  final BackupMetadata? metadata;
  final bool isRecommended;
  final bool isEmpty;

  SnapshotInfo({
    required this.name,
    required this.filename,
    required this.filePath,
    required this.type,
    required this.date,
    required this.size,
    this.metadata,
    this.isRecommended = false,
    this.isEmpty = false,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.day}.${date.month}.${date.year}';
  }

  /// Human-friendly title for display
  String get displayTitle {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    switch (type) {
      case SnapshotType.current:
        return 'Latest';
      case SnapshotType.previous:
        return 'Previous';
      case SnapshotType.daily:
        // Check if it's yesterday
        if (date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day) {
          return 'Yesterday';
        }
        // Otherwise show readable date
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
      case SnapshotType.weekly:
        // Check if it's last week
        final weekAgo = now.subtract(const Duration(days: 7));
        if (date.isAfter(weekAgo)) {
          return 'Last week';
        }
        // Otherwise show week label
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        // Find the Monday of that week
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return 'Week of ${monday.day} ${monthNames[monday.month - 1]} ${monday.year}';
      case SnapshotType.monthly:
        final monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${monthNames[date.month - 1]} ${date.year}';
    }
  }

  /// Subtitle for display showing item count and other info
  String get displaySubtitle {
    if (metadata == null) {
      return '$formattedDate • $formattedSize';
    }

    final itemText = metadata!.itemCount == 1
        ? '1 warranty'
        : '${metadata!.itemCount} warranties';
    final attachmentText = metadata!.attachmentCount == 1
        ? '1 attachment'
        : '${metadata!.attachmentCount} attachments';

    if (type == SnapshotType.current) {
      return '$itemText • $attachmentText • Current state';
    }

    return '$itemText • $attachmentText • $formattedSize';
  }
}
