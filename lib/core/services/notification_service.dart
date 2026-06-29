import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task Reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsGranted = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders for upcoming tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await android?.createNotificationChannel(channel);

      final notificationGranted =
          await android?.requestNotificationsPermission() ?? false;
      await android?.requestExactAlarmsPermission();

      _permissionsGranted = notificationGranted;
    } else {
      _permissionsGranted = true;
    }

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      if (kDebugMode) {
        debugPrint('NotificationService: timezone set to $timeZoneName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: timezone fallback — $e');
      }
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<bool> scheduleTaskReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized) await initialize();
    if (!_permissionsGranted && kDebugMode) {
      debugPrint('NotificationService: notification permission not granted');
    }

    final tzTime = _toLocalTz(scheduledAt);
    if (!tzTime.isAfter(tz.TZDateTime.now(tz.local))) {
      if (kDebugMode) {
        debugPrint('NotificationService: reminder time is in the past — skipped');
      }
      return false;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for upcoming tasks',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await cancelReminder(notificationId);

    final modes = [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];

    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzTime,
          details,
          androidScheduleMode: mode,
        );
        if (kDebugMode) {
          debugPrint(
            'NotificationService: scheduled #$notificationId at $tzTime ($mode)',
          );
        }
        return true;
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: $mode failed — $e');
        }
      }
    }

    return false;
  }

  tz.TZDateTime _toLocalTz(DateTime dateTime) {
    return tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> syncTaskReminders(List<Task> tasks) async {
    if (!_initialized) await initialize();

    for (final task in tasks) {
      if (task.reminderAt == null || task.isCompleted) {
        await cancelReminder(notificationIdFromTaskId(task.id));
        continue;
      }

      if (task.reminderAt!.isAfter(DateTime.now())) {
        await scheduleTaskReminder(
          notificationId: notificationIdFromTaskId(task.id),
          title: 'Task reminder',
          body: task.title,
          scheduledAt: task.reminderAt!,
        );
      }
    }
  }

  int notificationIdFromTaskId(String taskId) {
    return taskId.hashCode.abs() % 2147483647;
  }
}
