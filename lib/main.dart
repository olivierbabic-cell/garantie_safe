// lib/main.dart
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:garantie_safe/l10n/app_localizations.dart';
import 'package:garantie_safe/theme/app_theme.dart';
import 'package:garantie_safe/branding/app_brand.dart';
import 'package:garantie_safe/core/security/app_lock_gate.dart';
import 'package:garantie_safe/core/locale_controller.dart';
import 'package:garantie_safe/core/backup_service.dart';
import 'package:garantie_safe/core/background_tasks.dart';
import 'package:garantie_safe/core/db/app_db.dart';
import 'package:garantie_safe/core/db/database_manager.dart';
import 'package:garantie_safe/core/services/notification_service.dart';
import 'package:garantie_safe/core/services/warranty_notification_scheduler.dart';
import 'package:garantie_safe/core/services/backup_reminder_service.dart';
import 'package:garantie_safe/features/items/items_repository.dart';
import 'package:garantie_safe/features/payments/payment_method_service.dart';
import 'package:garantie_safe/features/premium/premium_service.dart';

// Screens
import 'home/home_screen.dart';
import 'features/onboarding/onboarding_start_screen.dart';
import 'features/items/items_list_screen.dart';
import 'features/scan_ocr/scan_stub_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/notifications_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.init();

  // Initialize notification service
  await NotificationService.init();

  // Migrate old PIN users to device lock
  await _migrateSecuritySettings();

  // Initialize database first to ensure schema is correct
  await _initializeDatabase();

  // Initialize payment methods system (migrate from prefs if needed)
  await _initializePaymentMethods();

  // Initialize premium service (handles silent restore in background)
  await _initializePremium();

  // Initialize background tasks for periodic backup checks
  await BackgroundTaskManager.initialize();

  // Run maintenance tasks in background (non-blocking)
  // These run asynchronously and don't delay app startup
  unawaited(_checkAutoBackup());
  unawaited(_purgeOldDeletedItems());
  unawaited(_checkBackupReminder());

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // Run notification resync after app is launched (non-blocking for faster startup)
  // This ensures notifications are up-to-date without delaying the UI
  unawaited(_rescheduleNotificationsOnce());
}

/// Migrate users with custom PIN to device lock
Future<void> _migrateSecuritySettings() async {
  try {
    final sp = await SharedPreferences.getInstance();
    final securityType = sp.getString('security_type');

    if (securityType == 'pin') {
      // Migrate custom PIN to device lock
      await sp.setString('security_type', 'device');
      await sp.remove('security_pin'); // Remove old PIN
      debugPrint('Migrated custom PIN user to device lock');
    }
  } catch (e) {
    debugPrint('Security migration failed: $e');
  }
}

/// Initialize database and run schema guard
Future<void> _initializeDatabase() async {
  try {
    // This triggers database open and schema guard via DatabaseManager
    await DatabaseManager.instance.getDatabase();
    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }
}

/// Initialize payment methods system (migrate from SharedPreferences)
Future<void> _initializePaymentMethods() async {
  try {
    await PaymentMethodService.instance.initialize();
    debugPrint('Payment methods initialized successfully');
  } catch (e) {
    debugPrint('Payment methods initialization error: $e');
  }
}

/// Initialize premium service (silent restore in background if needed)
Future<void> _initializePremium() async {
  try {
    await PremiumService.instance.init();
    debugPrint('Premium service initialized successfully');
  } catch (e) {
    debugPrint('Premium service initialization error: $e');
  }
}

Future<void> _checkAutoBackup() async {
  try {
    // Run snapshot routine if dirty flag is set
    await BackupService.runSnapshotIfDirty();
  } catch (e) {
    // Silently fail - don't block app startup
    debugPrint('Auto-snapshot check failed: $e');
  }
}

Future<void> _purgeOldDeletedItems() async {
  try {
    final repo = ItemsRepository();
    final purgedCount = await repo.purgeOldDeletedItems();
    if (purgedCount > 0) {
      debugPrint('Purged $purgedCount old deleted items');
    }
  } catch (e) {
    debugPrint('Purge old items failed: $e');
  }
}

/// Check and show backup reminder if needed (every 30 days)
Future<void> _checkBackupReminder() async {
  try {
    await BackupReminderService.checkAndShowReminderIfNeeded();
  } catch (e) {
    debugPrint('Backup reminder check failed: $e');
  }
}

/// Reschedule all notifications once per app start (runs in background after app launch).
/// Uses a guard to prevent duplicate rescheduling within 24 hours.
/// This runs asynchronously after app launch to avoid delaying startup.
Future<void> _rescheduleNotificationsOnce() async {
  try {
    final sp = await SharedPreferences.getInstance();
    const key = 'notifications_rescheduled_on_startup';
    final lastReschedule = sp.getInt(key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Only reschedule once per day to avoid excessive rescheduling
    const oneDayMs = 24 * 60 * 60 * 1000;
    if (now - lastReschedule < oneDayMs) {
      debugPrint('Notifications already rescheduled today');
      return;
    }

    debugPrint('Rescheduling all active item notifications...');
    await WarrantyNotificationScheduler.rescheduleAllActiveItems();
    await sp.setInt(key, now);
    debugPrint('Notifications rescheduled successfully');
  } catch (e) {
    debugPrint('Notification reschedule failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: AppBrand.current.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,

          // null => System
          locale: locale,

          // gen-l10n
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // optional: de_CH -> de fallback
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale == null) return supportedLocales.first;
            for (final s in supportedLocales) {
              if (s.languageCode == deviceLocale.languageCode) return s;
            }
            return supportedLocales.first;
          },

          home: const _StartGate(),
          routes: {
            '/home': (_) => const AppLockGate(child: HomeScreen()),
            '/onboarding': (_) => const OnboardingStartScreen(),
            '/items': (_) => const ItemsListScreen(),
            '/scan': (_) => const ScanStubScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/notifications': (_) => const NotificationsSettingsScreen(),
          },
        );
      },
    );
  }
}

class _StartGate extends StatefulWidget {
  const _StartGate();

  @override
  State<_StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<_StartGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // Check if database exists with data - this is the source of truth
    // If DB exists, we skip onboarding (handles OS backup restores)
    final hasDb = await AppDb.hasDatabaseWithData();

    if (hasDb) {
      // Database exists with data - go directly to home
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    // No active database - check if snapshots exist for restore options
    // This handles cases where OS backup restored snapshots but not active DB
    // OnboardingStartScreen will show restore options if snapshots exist
    await BackupService.hasInternalBackup(); // Warmup check

    if (!mounted) return;

    // Navigate to onboarding
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
