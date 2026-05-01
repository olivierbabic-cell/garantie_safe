import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/backup_service.dart';

/// Real cloud backup service that writes backup files to user-selected cloud folders
/// Supports Google Drive, iCloud Drive, and any cloud-synced folder
class CloudBackupService {
  /// Setup cloud backup by letting user select a folder
  /// Returns true if setup succeeded, false if cancelled
  static Future<bool> setupCloudBackup() async {
    try {
      // Let user pick a directory where backups will be saved
      // This can be a Google Drive folder, iCloud Drive folder, or any synced folder
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder for cloud backups',
        lockParentWindow: true,
      );

      if (selectedDirectory == null) {
        debugPrint('Cloud backup setup cancelled by user');
        return false;
      }

      // Verify we can write to the selected directory
      final testFile =
          File(path.join(selectedDirectory, '.garantie_safe_test'));
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        debugPrint('Cannot write to selected folder: $e');
        throw Exception(
            'Cannot write to selected folder. Please choose a different folder.');
      }

      // Store the selected folder path
      await Prefs.setCloudExportFolderPath(selectedDirectory);
      await Prefs.setCloudExportEnabled(true);
      await Prefs.setCloudExportLastError(null);

      debugPrint('Cloud backup configured: $selectedDirectory');
      return true;
    } catch (e) {
      debugPrint('Cloud backup setup failed: $e');
      await Prefs.setCloudExportLastError(e.toString());
      rethrow;
    }
  }

  /// Check if cloud backup is properly configured
  static Future<bool> isConfigured() async {
    final enabled = await Prefs.getCloudExportEnabled();
    final folderPath = await Prefs.getCloudExportFolderPath();

    if (!enabled || folderPath == null || folderPath.isEmpty) {
      return false;
    }

    // Verify folder still exists and is accessible
    try {
      final dir = Directory(folderPath);
      return await dir.exists();
    } catch (e) {
      debugPrint('Cloud folder no longer accessible: $e');
      return false;
    }
  }

  /// Disable cloud backup and clear configuration
  static Future<void> disable() async {
    await Prefs.setCloudExportEnabled(false);
    await Prefs.setCloudExportFolderPath(null);
    await Prefs.setCloudExportLastError(null);
    debugPrint('Cloud backup disabled');
  }

  /// Perform cloud backup by writing backup file to configured folder
  /// Returns true if successful, false otherwise
  static Future<bool> performCloudBackup() async {
    try {
      final folderPath = await Prefs.getCloudExportFolderPath();
      if (folderPath == null || folderPath.isEmpty) {
        throw Exception('Cloud folder not configured');
      }

      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        throw Exception('Cloud folder no longer exists: $folderPath');
      }

      // Get the latest backup file
      final backupBytes = await BackupService.exportBackupBytes();
      if (backupBytes == null) {
        throw Exception('No backup available to export');
      }

      // Create timestamped filename
      final timestamp = DateTime.now();
      final filename =
          'GarantieSafe_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.gsbackup';

      final backupFile = File(path.join(folderPath, filename));

      // Write backup to cloud folder
      await backupFile.writeAsBytes(backupBytes);

      // Track success
      await Prefs.setCloudExportLastAt(DateTime.now().millisecondsSinceEpoch);
      await Prefs.setCloudExportLastError(null);

      debugPrint('Cloud backup written successfully: ${backupFile.path}');
      return true;
    } catch (e) {
      debugPrint('Cloud backup failed: $e');
      await Prefs.setCloudExportLastError(e.toString());
      return false;
    }
  }

  /// Get cloud backup status for UI display
  static Future<Map<String, dynamic>> getStatus() async {
    final enabled = await Prefs.getCloudExportEnabled();
    final folderPath = await Prefs.getCloudExportFolderPath();
    final lastExportAt = await Prefs.getCloudExportLastAt();
    final lastError = await Prefs.getCloudExportLastError();
    final configured = await isConfigured();

    return {
      'enabled': enabled,
      'configured': configured,
      'folderPath': folderPath,
      'folderName': folderPath != null ? path.basename(folderPath) : null,
      'lastExportAt': lastExportAt,
      'lastError': lastError,
    };
  }

  /// Clean up old cloud backup files (keep last N backups)
  static Future<void> cleanupOldBackups({int keepCount = 10}) async {
    try {
      final folderPath = await Prefs.getCloudExportFolderPath();
      if (folderPath == null) return;

      final dir = Directory(folderPath);
      if (!await dir.exists()) return;

      // Find all .gsbackup files
      final backupFiles = await dir
          .list()
          .where((entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.gsbackup'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      backupFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // Delete older backups beyond keepCount
      if (backupFiles.length > keepCount) {
        for (var i = keepCount; i < backupFiles.length; i++) {
          try {
            await backupFiles[i].delete();
            debugPrint('Deleted old cloud backup: ${backupFiles[i].path}');
          } catch (e) {
            debugPrint('Failed to delete old backup: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old backups: $e');
    }
  }
}
