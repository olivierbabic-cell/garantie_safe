import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  // Keys
  static const _kOnbDone = 'onboarding_done';
  static const _kDarkMode = 'settings_dark_mode';

  // Sprache: null => System, 'de' | 'en'
  static const _kLanguage = 'settings_language';

  // Payment Methods (Onboarding -> Item Edit)
  // WICHTIG: wir nutzen den bestehenden Key, damit deine alten Daten wieder erscheinen
  static const _kPaymentMethods = 'onb_payment_methods';

  // Optionaler Legacy-Key (falls du irgendwo schon "payment_methods" gespeichert hast)
  static const _kPaymentMethodsLegacy = 'payment_methods';

  // ===== Backup Settings =====
  static const _kBackupEnabled = 'backup_enabled';
  static const _kBackupLastRun =
      'backup_last_run'; // timestamp - DEPRECATED, use _kBackupLastSuccessAt
  static const _kBackupLocation =
      'backup_location'; // DEPRECATED - no longer used (fixed app-private)
  static const _kBackupDestType =
      'backup_dest_type'; // DEPRECATED - always appPrivate now
  static const _kBackupDestPath =
      'backup_dest_path'; // DEPRECATED - always appPrivate now
  static const _kBackupDestUri =
      'backup_dest_uri'; // DEPRECATED - reserved for future cloud export
  static const _kBackupDirty =
      'backup_dirty'; // bool - data changed since last backup
  static const _kBackupLastChangeAt =
      'backup_last_change_at'; // timestamp - when data last changed
  static const _kBackupNextDueAt =
      'backup_next_due_at'; // timestamp - when next backup is due
  static const _kBackupLastSuccessAt =
      'backup_last_success_at'; // timestamp - when last backup succeeded
  static const _kBackupLastError =
      'backup_last_error'; // string - last backup error message
  static const _kLastRestoreAt = 'last_restore_at'; // timestamp
  static const _kLastExportedAt = 'last_exported_at'; // timestamp

  // ===== Cloud Export Settings =====
  static const _kCloudExportEnabled =
      'cloud_export_enabled'; // bool - auto-export to cloud
  static const _kCloudExportFolderUri =
      'cloud_export_folder_uri'; // string - selected cloud folder URI
  static const _kCloudExportFolderPath =
      'cloud_export_folder_path'; // string - display path
  static const _kCloudExportLastAt =
      'cloud_export_last_at'; // timestamp - last cloud export time
  static const _kCloudExportLastError =
      'cloud_export_last_error'; // string - last cloud export error
  static const _kBackupReminderLastShownAt =
      'backup_reminder_last_shown_at'; // timestamp - last backup reminder shown
  static const _kCloudEncryptionEnabled =
      'cloud_encryption_enabled'; // bool - encrypt cloud backups

  // ===== Notification Settings =====
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kRemind30Days = 'remind_30_days';
  static const _kRemind7Days = 'remind_7_days';
  static const _kRemindOnExpiryDay = 'remind_on_expiry_day';
  static const _kReminderLeadTimeDays = 'reminder_lead_time_days'; // default 7
  static const _kReminderTimeHour = 'reminder_time_hour'; // default 9
  static const _kReminderTimeMinute = 'reminder_time_minute'; // default 0

  // ===== Security Settings =====
  static const _kAppLockEnabled = 'app_lock_enabled'; // default true

  // ===== Premium Settings =====
  static const _kPremiumUnlocked =
      'premium_unlocked'; // bool - premium unlocked
  static const _kPremiumUnlockSource =
      'premium_unlock_source'; // string - purchase/restore/debug
  static const _kPremiumLastCheckedAt =
      'premium_last_checked_at'; // timestamp - last store check
  static const _kDebugPremiumOverride =
      'debug_premium_override'; // bool? - manual debug override (null = no override, true/false = explicit)

  // ===== Onboarding =====
  static Future<bool> getOnboardingDone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kOnbDone) ?? false;
  }

  static Future<void> setOnboardingDone(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kOnbDone, v);
  }

  static Future<void> resetOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kOnbDone);
  }

  // ===== Dark Mode =====
  static Future<bool> getDarkMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kDarkMode, value);
  }

  // ===== Sprache =====
  static Future<String?> getLanguage() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLanguage); // 'de' | 'en' | null
  }

  static Future<void> setLanguage(String? code) async {
    final sp = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await sp.remove(_kLanguage); // null = System
    } else {
      await sp.setString(_kLanguage, code);
    }
  }

  /// Locale für MaterialApp:
  /// - null => Device-Sprache
  /// - Locale('de') / Locale('en') => fix
  static Future<Locale?> getPreferredLocale() async {
    final code = await getLanguage(); // 'de' | 'en' | null
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  // ===== Payment Methods =====
  static Future<List<String>> getPaymentMethods() async {
    final sp = await SharedPreferences.getInstance();

    // Primär (korrekter Key)
    final v = sp.getStringList(_kPaymentMethods);
    if (v != null && v.isNotEmpty) return v;

    // Fallback (legacy)
    final legacy = sp.getStringList(_kPaymentMethodsLegacy);
    if (legacy != null && legacy.isNotEmpty) {
      // einmal migrieren, damit alles wieder konsistent ist
      await sp.setStringList(_kPaymentMethods, legacy);
      return legacy;
    }

    return <String>[];
  }

  static Future<void> setPaymentMethods(List<String> methods) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kPaymentMethods, methods);
  }

  // ===== Backup Settings =====
  static Future<bool> getBackupEnabled() async {
    // Backup is always enabled (mandatory)
    return true;
  }

  static Future<void> setBackupEnabled(bool value) async {
    // Backup is always enabled - this is kept for compatibility
    // but always enforces true
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kBackupEnabled, true);
  }

  // Backup frequency removed - auto-backup always enabled after changes

  static Future<int?> getBackupLastRun() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kBackupLastRun);
  }

  static Future<void> setBackupLastRun(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBackupLastRun, timestamp);
  }

  // LEGACY - kept for migration only
  static Future<String?> getBackupLocation() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kBackupLocation);
  }

  static Future<void> setBackupLocation(String? path) async {
    final sp = await SharedPreferences.getInstance();
    if (path == null) {
      await sp.remove(_kBackupLocation);
    } else {
      await sp.setString(_kBackupLocation, path);
    }
  }

  // NEW: Backup destination type and path
  static Future<String?> getBackupDestType() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kBackupDestType);
  }

  static Future<void> setBackupDestType(String type) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBackupDestType, type);
  }

  static Future<String?> getBackupDestPath() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kBackupDestPath);
  }

  static Future<void> setBackupDestPath(String path) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBackupDestPath, path);
  }

  static Future<String?> getBackupDestUri() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kBackupDestUri);
  }

  static Future<void> setBackupDestUri(String uri) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBackupDestUri, uri);
  }

  static Future<void> clearBackupDestination() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kBackupDestType);
    await sp.remove(_kBackupDestPath);
    await sp.remove(_kBackupDestUri);
    await sp.remove(_kBackupLocation); // Clear legacy too
  }

  // ===== Export Tracking =====
  static Future<int?> getLastExportedAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kLastExportedAt);
  }

  static Future<void> setLastExportedAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kLastExportedAt, timestamp);
  }

  static Future<bool> getBackupDirty() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kBackupDirty) ?? false;
  }

  static Future<void> setBackupDirty(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kBackupDirty, value);
  }

  static Future<int?> getBackupLastChangeAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kBackupLastChangeAt);
  }

  static Future<void> setBackupLastChangeAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBackupLastChangeAt, timestamp);
  }

  static Future<int?> getBackupNextDueAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kBackupNextDueAt);
  }

  static Future<void> setBackupNextDueAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBackupNextDueAt, timestamp);
  }

  static Future<int?> getBackupLastSuccessAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kBackupLastSuccessAt);
  }

  static Future<void> setBackupLastSuccessAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBackupLastSuccessAt, timestamp);
  }

  static Future<String?> getBackupLastError() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kBackupLastError);
  }

  static Future<void> setBackupLastError(String? error) async {
    final sp = await SharedPreferences.getInstance();
    if (error == null) {
      await sp.remove(_kBackupLastError);
    } else {
      await sp.setString(_kBackupLastError, error);
    }
  }

  static Future<int?> getLastRestoreAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kLastRestoreAt);
  }

  static Future<void> setLastRestoreAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kLastRestoreAt, timestamp);
  }

  // ===== Notification Settings =====
  static Future<bool> getNotificationsEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kNotificationsEnabled) ?? true; // default: enabled
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kNotificationsEnabled, value);
  }

  static Future<bool> getRemind30Days() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRemind30Days) ?? true; // default: enabled
  }

  static Future<void> setRemind30Days(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRemind30Days, value);
  }

  static Future<bool> getRemind7Days() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRemind7Days) ?? true; // default: enabled
  }

  static Future<void> setRemind7Days(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRemind7Days, value);
  }

  static Future<bool> getRemindOnExpiryDay() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRemindOnExpiryDay) ?? true; // default: enabled
  }

  static Future<void> setRemindOnExpiryDay(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRemindOnExpiryDay, value);
  }

  // ===== New Simplified Notification Settings =====
  static Future<int> getReminderLeadTimeDays() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kReminderLeadTimeDays) ?? 7;
  }

  static Future<void> setReminderLeadTimeDays(int days) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kReminderLeadTimeDays, days);
  }

  static Future<int> getReminderTimeHour() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kReminderTimeHour) ?? 9;
  }

  static Future<void> setReminderTimeHour(int hour) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kReminderTimeHour, hour);
  }

  static Future<int> getReminderTimeMinute() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kReminderTimeMinute) ?? 0;
  }

  static Future<void> setReminderTimeMinute(int minute) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kReminderTimeMinute, minute);
  }

  // ===== Security Settings =====
  static Future<bool> getAppLockEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kAppLockEnabled) ?? true; // default: enabled
  }

  static Future<void> setAppLockEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAppLockEnabled, value);
  }

  // ===== Cloud Export Settings =====
  static Future<bool> getCloudExportEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kCloudExportEnabled) ?? false;
  }

  static Future<void> setCloudExportEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kCloudExportEnabled, value);
  }

  static Future<String?> getCloudExportFolderUri() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kCloudExportFolderUri);
  }

  static Future<void> setCloudExportFolderUri(String? uri) async {
    final sp = await SharedPreferences.getInstance();
    if (uri == null) {
      await sp.remove(_kCloudExportFolderUri);
    } else {
      await sp.setString(_kCloudExportFolderUri, uri);
    }
  }

  static Future<String?> getCloudExportFolderPath() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kCloudExportFolderPath);
  }

  static Future<void> setCloudExportFolderPath(String? path) async {
    final sp = await SharedPreferences.getInstance();
    if (path == null) {
      await sp.remove(_kCloudExportFolderPath);
    } else {
      await sp.setString(_kCloudExportFolderPath, path);
    }
  }

  static Future<int?> getCloudExportLastAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kCloudExportLastAt);
  }

  static Future<void> setCloudExportLastAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kCloudExportLastAt, timestamp);
  }

  static Future<String?> getCloudExportLastError() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kCloudExportLastError);
  }

  static Future<void> setCloudExportLastError(String? error) async {
    final sp = await SharedPreferences.getInstance();
    if (error == null) {
      await sp.remove(_kCloudExportLastError);
    } else {
      await sp.setString(_kCloudExportLastError, error);
    }
  }

  static Future<bool> getCloudEncryptionEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kCloudEncryptionEnabled) ?? true; // default ON
  }

  static Future<void> setCloudEncryptionEnabled(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kCloudEncryptionEnabled, enabled);
  }

  static Future<void> clearCloudExportSettings() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kCloudExportEnabled);
    await sp.remove(_kCloudExportFolderUri);
    await sp.remove(_kCloudExportFolderPath);
    await sp.remove(_kCloudExportLastAt);
    await sp.remove(_kCloudExportLastError);
  }

  // ===== Backup Reminder =====
  static Future<int?> getBackupReminderLastShownAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kBackupReminderLastShownAt);
  }

  static Future<void> setBackupReminderLastShownAt(int timestamp) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBackupReminderLastShownAt, timestamp);
  }

  // ===== Premium =====
  static Future<bool> getPremiumUnlocked() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kPremiumUnlocked) ?? false;
  }

  static Future<void> setPremiumUnlocked(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPremiumUnlocked, value);
  }

  static Future<String?> getPremiumUnlockSource() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kPremiumUnlockSource);
  }

  static Future<void> setPremiumUnlockSource(String? source) async {
    final sp = await SharedPreferences.getInstance();
    if (source == null) {
      await sp.remove(_kPremiumUnlockSource);
    } else {
      await sp.setString(_kPremiumUnlockSource, source);
    }
  }

  static Future<int?> getPremiumLastCheckedAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kPremiumLastCheckedAt);
  }

  static Future<void> setPremiumLastCheckedAt(int? timestamp) async {
    final sp = await SharedPreferences.getInstance();
    if (timestamp == null) {
      await sp.remove(_kPremiumLastCheckedAt);
    } else {
      await sp.setInt(_kPremiumLastCheckedAt, timestamp);
    }
  }

  // ===== Debug Premium Override =====
  // Manual debug override for testing free/premium modes in debug builds
  // null = no override (use real premium state)
  // true = force premium in debug
  // false = force free in debug
  static Future<bool?> getDebugPremiumOverride() async {
    final sp = await SharedPreferences.getInstance();
    if (!sp.containsKey(_kDebugPremiumOverride)) {
      return null; // No override set
    }
    return sp.getBool(_kDebugPremiumOverride);
  }

  static Future<void> setDebugPremiumOverride(bool? value) async {
    final sp = await SharedPreferences.getInstance();
    if (value == null) {
      await sp.remove(_kDebugPremiumOverride);
    } else {
      await sp.setBool(_kDebugPremiumOverride, value);
    }
  }
}
