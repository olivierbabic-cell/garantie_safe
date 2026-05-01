import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification system and timezone
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Set local timezone to Europe/Zurich as default
      // tz.local will use this after initializeTimeZones
      tz.setLocalLocation(tz.getLocation('Europe/Zurich'));

      debugPrint('NotificationService: Local timezone set to Europe/Zurich');

      // Android initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request manually
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Initialization error: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to item details if needed
  }

  /// Request notification permissions (iOS + Android 13+)
  static Future<bool> requestPermissionsIfNeeded() async {
    try {
      // iOS permissions
      final bool? iosGranted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Android 13+ permissions
      final bool? androidGranted = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      final granted = iosGranted ?? androidGranted ?? true;
      debugPrint('NotificationService: Permissions granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('NotificationService: Permission request error: $e');
      return false;
    }
  }

  /// Check if permissions are granted
  static Future<bool> arePermissionsGranted() async {
    try {
      // Check iOS
      final iosGranted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();

      // Check Android
      final androidGranted = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();

      // If either platform returns a value, use it; otherwise assume granted
      if (iosGranted != null && iosGranted.isEnabled) {
        return true;
      }
      return androidGranted ?? true;
    } catch (e) {
      debugPrint('NotificationService: Check permissions error: $e');
      return false;
    }
  }

  /// Schedule a notification at a specific time
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'warranty_expiry',
        'Warranty Expiry',
        channelDescription: 'Notifications for warranty expiration reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
          'NotificationService: Scheduled notification $id for $scheduledDateTime');
    } catch (e) {
      debugPrint('NotificationService: Schedule error: $e');
    }
  }

  /// Show an immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
    String channelName = 'General Notifications',
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'General app notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('NotificationService: Showed notification $id');
    } catch (e) {
      debugPrint('NotificationService: Show notification error: $e');
    }
  }

  /// Cancel a specific notification
  static Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('NotificationService: Cancelled notification $id');
    } catch (e) {
      debugPrint('NotificationService: Cancel error: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      debugPrint('NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('NotificationService: Cancel all error: $e');
    }
  }

  /// Get list of pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('NotificationService: Get pending notifications error: $e');
      return [];
    }
  }
}
