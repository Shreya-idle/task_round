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
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await android?.createNotificationChannel(channel);
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
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

    final now = DateTime.now();
    if (!scheduledAt.isAfter(now)) {
      if (kDebugMode) {
        debugPrint('NotificationService: reminder time is in the past — skipped');
      }
      return false;
    }

    final tzTime = tz.TZDateTime(
      tz.local,
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      scheduledAt.hour,
      scheduledAt.minute,
      scheduledAt.second,
    );

    if (!tzTime.isAfter(tz.TZDateTime.now(tz.local))) {
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
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      if (kDebugMode) {
        debugPrint('NotificationService: scheduled #$notificationId at $tzTime');
      }
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: exact schedule failed — $e');
      }
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return true;
      } on Exception catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('NotificationService: schedule failed — $fallbackError');
        }
        return false;
      }
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> syncTaskReminders(List<Task> tasks) async {
    if (!_initialized) await initialize();

    for (final task in tasks) {
      final id = notificationIdFromTaskId(task.id);
      await cancelReminder(id);

      if (task.reminderAt != null &&
          !task.isCompleted &&
          task.reminderAt!.isAfter(DateTime.now())) {
        await scheduleTaskReminder(
          notificationId: id,
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
