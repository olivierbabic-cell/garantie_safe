import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'backup_service.dart';

/// Background task names
class BackgroundTasks {
  static const backupCheck = 'com.garantiesafe.backup_check';
}

/// Background task dispatcher - called by WorkManager in isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');

    try {
      switch (task) {
        case BackgroundTasks.backupCheck:
          // Run snapshot if dirty flag is set
          final ranSnapshot = await BackupService.runSnapshotIfDirty();
          debugPrint(
              'Background snapshot check: ${ranSnapshot ? "snapshot created" : "not dirty"}');
          break;
        default:
          debugPrint('Unknown background task: $task');
      }

      return Future.value(true);
    } catch (e, st) {
      debugPrint('Background task error: $e\n$st');
      return Future.value(false);
    }
  });
}

/// Background task setup and registration
class BackgroundTaskManager {
  /// Initialize WorkManager and register periodic tasks
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Register periodic backup check (every 6 hours)
      // This complements app start/resume checks
      await Workmanager().registerPeriodicTask(
        'backup-check-periodic',
        BackgroundTasks.backupCheck,
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      debugPrint('Background tasks registered successfully');
    } catch (e) {
      debugPrint('Failed to initialize background tasks: $e');
      // Don't throw - background tasks are best-effort
    }
  }

  /// Cancel all background tasks (for testing/reset)
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('All background tasks cancelled');
    } catch (e) {
      debugPrint('Failed to cancel background tasks: $e');
    }
  }
}
