import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules the evening reminder on the device. Behind an interface so the
/// web build and tests use [NoReminderScheduler].
abstract class ReminderScheduler {
  /// Whether this platform can show scheduled notifications at all.
  bool get isSupported;

  /// Asks the system for permission to notify; true when granted.
  Future<bool> requestPermission();

  /// Replaces any planned reminders with one at each of [times].
  Future<void> schedule(
    List<DateTime> times, {
    required String title,
    required String body,
    required String channelName,
  });

  Future<void> cancelAll();
}

/// Web, desktop and tests: reminders aren't available.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(
    List<DateTime> times, {
    required String title,
    required String body,
    required String channelName,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Android and iOS, via flutter_local_notifications.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler._(this._plugin);

  /// Our notification ids — kept apart so only reminders are ever cancelled.
  static const int _firstId = 100;
  static const int _maxReminders = 14;

  final FlutterLocalNotificationsPlugin _plugin;

  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Sets the plugin up without asking for any permission yet — that only
  /// happens once the user switches the reminder on.
  static Future<ReminderScheduler> create() async {
    if (!platformSupported) {
      return const NoReminderScheduler();
    }

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      return LocalReminderScheduler._(plugin);
    } catch (error) {
      debugPrint('Lighthouse reminders unavailable: $error');
      return const NoReminderScheduler();
    }
  }

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> schedule(
    List<DateTime> times, {
    required String title,
    required String body,
    required String channelName,
  }) async {
    await cancelAll();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'evening_reminder',
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    for (final (index, time) in times.take(_maxReminders).indexed) {
      await _plugin.zonedSchedule(
        id: _firstId + index,
        // An absolute instant: the local wall-clock time, converted to UTC
        // for that very day, so daylight-saving changes are already applied
        // and no time-zone database is needed.
        scheduledDate: tz.TZDateTime.from(time.toUtc(), tz.UTC),
        notificationDetails: details,
        // Inexact is fine for a gentle evening nudge and needs no special
        // "exact alarm" permission on Android.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    for (var id = _firstId; id < _firstId + _maxReminders; id++) {
      await _plugin.cancel(id: id);
    }
  }
}
