import 'package:flutter/widgets.dart';
import 'package:garantie_safe/features/items/item.dart';
import 'package:garantie_safe/core/services/notification_service.dart';
import 'package:garantie_safe/core/prefs.dart';
import 'package:garantie_safe/features/items/items_repository.dart';
import 'package:garantie_safe/l10n/app_localizations.dart';

/// Scheduler for warranty expiry notifications
///
/// This service manages local notifications for warranty expiration reminders.
/// It ensures notifications are only scheduled for active (non-deleted) items.
///
/// Notification ID scheme (deterministic and unique):
/// - itemId * 10 + 1 = 30 days before expiry
/// - itemId * 10 + 2 = 7 days before expiry
/// - itemId * 10 + 3 = on expiry day
///
/// Example: Item #47 gets notification IDs: 471, 472, 473
class WarrantyNotificationScheduler {
  static const int _type30Days = 1;
  static const int _type7Days = 2;
  static const int _typeExpiryDay = 3;

  /// Generate notification ID for an item and type
  static int _generateNotificationId(int itemId, int type) {
    return itemId * 10 + type;
  }

  /// Schedule all enabled notifications for an item
  ///
  /// IMPORTANT: This should only be called for active (non-deleted) items.
  /// Deleted items should have their notifications cancelled instead.
  static Future<void> scheduleForItem(Item item) async {
    try {
      debugPrint(
          'WarrantyScheduler: Processing item ${item.id} "${item.title}"');

      // Safety check: Do not schedule for deleted items
      if (item.deletedAt != null) {
        debugPrint(
            'WarrantyScheduler: Item ${item.id} is deleted, cancelling notifications');
        await cancelForItem(item.id);
        return;
      }

      // If no expiry date, cancel any existing notifications
      if (item.expiryDate == null) {
        debugPrint(
            'WarrantyScheduler: No expiry date for item ${item.id}, cancelling notifications');
        await cancelForItem(item.id);
        return;
      }

      // Get user notification settings
      final settings = await _getNotificationSettings();

      // If notifications are disabled, cancel and return
      if (!settings.enabled) {
        debugPrint(
            'WarrantyScheduler: Notifications disabled globally, cancelling for item ${item.id}');
        await cancelForItem(item.id);
        return;
      }

      // Load localized strings for notifications
      final l10n = await _loadLocalizations();

      final expiryDateTime =
          DateTime.fromMillisecondsSinceEpoch(item.expiryDate!);
      final now = DateTime.now();

      int scheduledCount = 0;

      // Schedule 30 days before if enabled
      if (settings.remind30) {
        final reminderDate = expiryDateTime.subtract(const Duration(days: 30));
        final scheduledTime = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          settings.reminderHour,
          settings.reminderMinute,
        );

        if (scheduledTime.isAfter(now)) {
          await NotificationService.schedule(
            id: _generateNotificationId(item.id, _type30Days),
            title: l10n.notif_warranty_expiring_soon_title,
            body: l10n.notif_warranty_expires_in_days_body(item.title, 30),
            scheduledDateTime: scheduledTime,
            payload: 'item:${item.id}',
          );
          scheduledCount++;
          debugPrint(
              'WarrantyScheduler: Scheduled 30-day reminder for item ${item.id} at $scheduledTime');
        } else {
          debugPrint(
              'WarrantyScheduler: Skipped 30-day reminder for item ${item.id} (date in past)');
        }
      }

      // Schedule 7 days before if enabled
      if (settings.remind7) {
        final reminderDate = expiryDateTime.subtract(const Duration(days: 7));
        final scheduledTime = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          settings.reminderHour,
          settings.reminderMinute,
        );

        if (scheduledTime.isAfter(now)) {
          await NotificationService.schedule(
            id: _generateNotificationId(item.id, _type7Days),
            title: l10n.notif_warranty_expiring_soon_title,
            body: l10n.notif_warranty_expires_in_days_body(item.title, 7),
            scheduledDateTime: scheduledTime,
            payload: 'item:${item.id}',
          );
          scheduledCount++;
          debugPrint(
              'WarrantyScheduler: Scheduled 7-day reminder for item ${item.id} at $scheduledTime');
        } else {
          debugPrint(
              'WarrantyScheduler: Skipped 7-day reminder for item ${item.id} (date in past)');
        }
      }

      // Schedule on expiry day if enabled
      if (settings.remindOnDay) {
        final scheduledTime = DateTime(
          expiryDateTime.year,
          expiryDateTime.month,
          expiryDateTime.day,
          settings.reminderHour,
          settings.reminderMinute,
        );

        if (scheduledTime.isAfter(now)) {
          await NotificationService.schedule(
            id: _generateNotificationId(item.id, _typeExpiryDay),
            title: l10n.notif_warranty_expires_today_title,
            body: l10n.notif_warranty_expires_today_body(item.title),
            scheduledDateTime: scheduledTime,
            payload: 'item:${item.id}',
          );
          scheduledCount++;
          debugPrint(
              'WarrantyScheduler: Scheduled expiry-day reminder for item ${item.id} at $scheduledTime');
        } else {
          debugPrint(
              'WarrantyScheduler: Skipped expiry-day reminder for item ${item.id} (date in past)');
        }
      }

      if (scheduledCount == 0) {
        debugPrint(
            'WarrantyScheduler: No future notifications scheduled for item ${item.id} (all dates in past)');
      }

      final expiryDateStr =
          DateTime.fromMillisecondsSinceEpoch(item.expiryDate!)
              .toLocal()
              .toString()
              .split(' ')[0];
      debugPrint(
          'WarrantyScheduler: Scheduled notifications for item ${item.id} "${item.title}" (expiry: $expiryDateStr)');
    } catch (e) {
      debugPrint('WarrantyScheduler: Error scheduling for item ${item.id}: $e');
    }
  }

  /// Cancel all notifications for an item
  static Future<void> cancelForItem(int itemId) async {
    try {
      await NotificationService.cancel(
          _generateNotificationId(itemId, _type30Days));
      await NotificationService.cancel(
          _generateNotificationId(itemId, _type7Days));
      await NotificationService.cancel(
          _generateNotificationId(itemId, _typeExpiryDay));
      debugPrint('WarrantyScheduler: Cancelled notifications for item $itemId');
    } catch (e) {
      debugPrint('WarrantyScheduler: Error cancelling for item $itemId: $e');
    }
  }

  /// Reschedule notifications for all active items
  ///
  /// This method is called:
  /// - Once per day on app startup (to fix OS notification purges)
  /// - After backup restore (to rebuild notification state)
  ///
  /// IMPORTANT: This cancels ALL notifications first, then rebuilds.
  /// This app currently only uses notifications for warranty reminders,
  /// so cancelAll() is safe. If other notification types are added in the future,
  /// this logic must be updated to only cancel warranty-related notifications.
  static Future<void> rescheduleAllActiveItems() async {
    try {
      // Cancel all existing notifications (safe because this app only has warranty notifications)
      await NotificationService.cancelAll();

      // Get all active items (deleted_at IS NULL) - listItems already filters correctly
      final repo = ItemsRepository();
      final activeItems = await repo.listItems(limit: 5000);

      debugPrint(
          'WarrantyScheduler: Rescheduling ${activeItems.length} active items');

      // Schedule for each active item
      for (final item in activeItems) {
        await scheduleForItem(item);
      }

      debugPrint('WarrantyScheduler: Rescheduled all active items');
    } catch (e) {
      debugPrint('WarrantyScheduler: Error rescheduling all items: $e');
    }
  }

  /// Load AppLocalizations without BuildContext
  ///
  /// This method loads the correct localized strings based on the user's
  /// language preference stored in Prefs. It gracefully handles:
  /// - Missing language code (defaults to English)
  /// - Unsupported language codes (defaults to English)
  /// - Region codes (e.g., de_CH -> de, pt_BR -> fallback to en if pt not supported)
  ///
  /// Future-safe: Adding new languages only requires ARB file additions,
  /// no code changes needed here.
  static Future<AppLocalizations> _loadLocalizations() async {
    try {
      // Get language code from Prefs (e.g., 'en', 'de', 'de_CH', 'pt_BR')
      final rawLanguageCode = await Prefs.getLanguage() ?? 'en';

      // Normalize to base language code (extract before _ or -)
      // Examples: 'de_CH' -> 'de', 'pt_BR' -> 'pt', 'en-US' -> 'en'
      final normalizedLanguage = _normalizeLanguageCode(rawLanguageCode);

      // Load the correct AppLocalizations instance
      // lookupAppLocalizations will use the normalized language code
      return lookupAppLocalizations(Locale(normalizedLanguage));
    } catch (e) {
      // Fallback to English on any error (including unsupported language)
      debugPrint(
          'WarrantyScheduler: Failed to load localizations, using English: $e');
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  /// Normalize language code to base language
  ///
  /// Extracts the base language from region-specific codes and validates
  /// against supported app languages. Unsupported languages fall back to English.
  ///
  /// Supported languages: de, en
  ///
  /// Examples:
  /// - 'de' -> 'de'
  /// - 'de_CH' -> 'de'
  /// - 'de_AT' -> 'de'
  /// - 'en' -> 'en'
  /// - 'en_US' -> 'en'
  /// - 'en-GB' -> 'en'
  /// - 'pt_BR' -> 'en' (fallback, pt not supported)
  /// - 'es_MX' -> 'en' (fallback, es not supported)
  static String _normalizeLanguageCode(String rawCode) {
    // Supported languages in this app (must match ARB files)
    const supportedLanguages = ['de', 'en'];

    // Extract base language (before _ or -)
    final baseLanguage = rawCode.split(RegExp(r'[_-]'))[0].toLowerCase();

    // Check if supported, otherwise fallback to English
    if (supportedLanguages.contains(baseLanguage)) {
      return baseLanguage;
    }

    return 'en'; // Default fallback
  }

  /// Get notification settings from Prefs
  ///
  /// Centralized settings loader that fetches all notification preferences.
  static Future<_NotificationSettings> _getNotificationSettings() async {
    final enabled = await Prefs.getNotificationsEnabled();
    final remind30 = await Prefs.getRemind30Days();
    final remind7 = await Prefs.getRemind7Days();
    final remindOnDay = await Prefs.getRemindOnExpiryDay();
    final reminderHour = await Prefs.getReminderTimeHour();
    final reminderMinute = await Prefs.getReminderTimeMinute();

    return _NotificationSettings(
      enabled: enabled,
      remind30: remind30,
      remind7: remind7,
      remindOnDay: remindOnDay,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
  }
}

/// Internal class to hold notification settings
///
/// Centralizes all configuration needed for notification scheduling.
class _NotificationSettings {
  final bool enabled;
  final bool remind30;
  final bool remind7;
  final bool remindOnDay;
  final int reminderHour;
  final int reminderMinute;

  _NotificationSettings({
    required this.enabled,
    required this.remind30,
    required this.remind7,
    required this.remindOnDay,
    required this.reminderHour,
    required this.reminderMinute,
  });
}
