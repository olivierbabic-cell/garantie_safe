import 'package:flutter/material.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/core/services/notification_service.dart';

/// Service for managing backup reminders
/// Shows notification every 30 days to remind users to export backups
class BackupReminderService {
  BackupReminderService._();

  static const int reminderIntervalDays = 30;
  static const String notificationChannelId = 'backup_reminders';
  static const String notificationChannelName = 'Backup Reminders';
  static const int notificationId = 9999; // Unique ID for backup reminders

  /// Check if backup reminder should be shown and show it if needed
  static Future<void> checkAndShowReminderIfNeeded() async {
    try {
      final lastShown = await Prefs.getBackupReminderLastShownAt();
      final now = DateTime.now().millisecondsSinceEpoch;

      // If never shown, or shown more than 30 days ago
      final shouldShow = lastShown == null ||
          (now - lastShown) > (reminderIntervalDays * 24 * 60 * 60 * 1000);

      if (shouldShow) {
        await _showBackupReminder();
        await Prefs.setBackupReminderLastShownAt(now);
        debugPrint('Backup reminder shown');
      } else {
        final nextShowDate = DateTime.fromMillisecondsSinceEpoch(
            lastShown + (reminderIntervalDays * 24 * 60 * 60 * 1000));
        debugPrint('Next backup reminder at: $nextShowDate');
      }
    } catch (e) {
      debugPrint('Backup reminder check failed: $e');
    }
  }

  /// Show backup reminder notification
  static Future<void> _showBackupReminder() async {
    try {
      await NotificationService.showNotification(
        id: notificationId,
        title: 'Keep your warranties safe',
        body:
            'Export a backup to your cloud storage to protect against device loss.',
        payload: 'backup_reminder',
      );
    } catch (e) {
      debugPrint('Failed to show backup reminder: $e');
    }
  }

  /// Cancel backup reminder notification
  static Future<void> cancelReminder() async {
    try {
      await NotificationService.cancel(notificationId);
    } catch (e) {
      debugPrint('Failed to cancel backup reminder: $e');
    }
  }

  /// Reset reminder (for testing or after user exports backup)
  static Future<void> resetReminder() async {
    await Prefs.setBackupReminderLastShownAt(
        DateTime.now().millisecondsSinceEpoch);
  }
}
