import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service that owns the FlutterLocalNotificationsPlugin instance.
/// Initialise once in main.dart via [ReminderService.init()].
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _readingChannelId = 'readora_reading_reminders';
  static const String _friendPostChannelId = 'readora_friend_posts';

  // Notification IDs
  static const int readingTimeId = 1001;
  static const int readingGoalId = 1002;
  static const int friendPostBaseId = 2000; // +index for each post

  // ─────────────────────────────────────────────────────────────
  //  INITIALISATION
  // ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      print("Failed to set local timezone location, falling back to UTC: $e");
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channels
    if (!kIsWeb) {
      // Platform check only if not web
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _readingChannelId,
            'Reading Reminders',
            description: 'Daily reading time & goal reminders',
            importance: Importance.high,
          ));

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _friendPostChannelId,
            'Friend Posts',
            description: 'Notifications when a friend posts',
            importance: Importance.defaultImportance,
          ));

      // Request permission on Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  READING TIME REMINDER  (daily at user-picked time)
  // ─────────────────────────────────────────────────────────────
  Future<void> scheduleReadingTimeReminder(TimeOfDay time) async {
    await _plugin.cancel(readingTimeId); // cancel any existing

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      readingTimeId,
      '📖 Time to Read!',
      'Your daily reading time has arrived. Open Readora and dive in!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _readingChannelId,
          'Reading Reminders',
          channelDescription: 'Daily reading time & goal reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  Future<void> cancelReadingTimeReminder() async {
    await _plugin.cancel(readingTimeId);
  }

  // ─────────────────────────────────────────────────────────────
  //  READING GOAL REMINDER  (daily at 8 PM if enabled)
  // ─────────────────────────────────────────────────────────────
  Future<void> scheduleReadingGoalReminder(TimeOfDay time) async {
    await _plugin.cancel(readingGoalId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      readingGoalId,
      '🎯 Reading Goal Reminder',
      "Don't forget to complete today's reading goal!",
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _readingChannelId,
          'Reading Reminders',
          channelDescription: 'Daily reading time & goal reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReadingGoalReminder() async {
    await _plugin.cancel(readingGoalId);
  }

  // ─────────────────────────────────────────────────────────────
  //  FRIEND POST NOTIFICATION  (instant local notification)
  // ─────────────────────────────────────────────────────────────
  Future<void> showFriendPostNotification({
    required String friendName,
    required String postPreview,
    int index = 0,
  }) async {
    await _plugin.show(
      friendPostBaseId + index,
      '📝 $friendName posted',
      postPreview.length > 80
          ? '${postPreview.substring(0, 80)}...'
          : postPreview,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _friendPostChannelId,
          'Friend Posts',
          channelDescription: 'Notifications when a friend posts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // Cancel all reminders
  Future<void> cancelAll() async => _plugin.cancelAll();

  // Show a test notification immediately
  Future<void> showTestNotification() async {
    await _plugin.show(
      999, // Unique test ID
      '📖 Readora Test Reminder',
      'This is a test notification from Readora! Reminders are working correctly.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _readingChannelId,
          'Reading Reminders',
          channelDescription: 'Daily reading time & goal reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
