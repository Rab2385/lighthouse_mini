import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/services/reminder_scheduler.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';
import 'package:lighthouse_mini/util/reminder_plan.dart';

/// Records what would be scheduled on a phone.
class _FakeScheduler implements ReminderScheduler {
  _FakeScheduler({this.granted = true});

  final bool granted;
  List<DateTime> planned = [];
  String? lastTitle;

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> schedule(
    List<DateTime> times, {
    required String title,
    required String body,
    required String channelName,
  }) async {
    planned = times;
    lastTitle = title;
  }

  @override
  Future<void> cancelAll() async => planned = [];
}

Future<LighthouseController> _controller(
  String name,
  ReminderScheduler scheduler,
) async {
  final controller = LighthouseController(
    LighthouseDatabase.withFactory(databaseFactoryMemory, name),
    reminders: scheduler,
    deviceLanguage: () => 'de',
  );
  await controller.initialize();
  return controller;
}

void main() {
  group('plan', () {
    List<DateTime> plan(DateTime now, {bool wroteToday = false}) =>
        reminderTimes(now: now, hour: 20, minute: 30, wroteToday: wroteToday);

    test('the next 7 evenings, starting today', () {
      final times = plan(DateTime(2026, 9, 30, 9));
      expect(times, hasLength(7));
      expect(times.first, DateTime(2026, 9, 30, 20, 30));
      expect(times.last, DateTime(2026, 10, 6, 20, 30));
    });

    test('skips today once something was written', () {
      final times = plan(DateTime(2026, 9, 30, 9), wroteToday: true);
      expect(times, hasLength(6));
      expect(times.first, DateTime(2026, 10, 1, 20, 30));
    });

    test('skips today once the time has passed', () {
      final times = plan(DateTime(2026, 9, 30, 21));
      expect(times.first, DateTime(2026, 10, 1, 20, 30));
    });

    test('keeps the local wall-clock time across a DST change', () {
      // Europe: clocks go back on 25.10.2026.
      final times = plan(DateTime(2026, 10, 23, 9));
      expect(times.map((t) => (t.hour, t.minute)).toSet(), {(20, 30)});
    });
  });

  group('controller', () {
    test('off by default — nothing planned', () async {
      final scheduler = _FakeScheduler();
      final c = await _controller('rem-off', scheduler);

      expect(c.reminderEnabled, isFalse);
      expect(scheduler.planned, isEmpty);
    });

    test('switching on plans reminders; writing today drops tonight', () async {
      final scheduler = _FakeScheduler();
      final c = await _controller('rem-on', scheduler);

      expect(await c.setReminderEnabled(true), isTrue);
      final before = scheduler.planned.length;
      expect(before, greaterThanOrEqualTo(6));

      await c.addGoodThing(date: c.today, text: 'Kaffee');
      expect(
        scheduler.planned.any((t) => DateUtils.isSameDay(t, c.today)),
        isFalse,
      );
      expect(scheduler.lastTitle, 'Was war heute gut?');

      await c.setReminderEnabled(false);
      expect(scheduler.planned, isEmpty);
    });

    test('stays off when notifications are not allowed', () async {
      final c = await _controller('rem-denied', _FakeScheduler(granted: false));

      expect(await c.setReminderEnabled(true), isFalse);
      expect(c.reminderEnabled, isFalse);
    });

    test('the time is kept and used', () async {
      final scheduler = _FakeScheduler();
      final c = await _controller('rem-time', scheduler);
      await c.setReminderEnabled(true);
      await c.setReminderMinutes(19 * 60 + 5);

      expect(c.reminderMinutes, 19 * 60 + 5);
      expect(
        scheduler.planned.every((t) => t.hour == 19 && t.minute == 5),
        isTrue,
      );
    });

    test('is never offered where it can\'t work', () async {
      final c = await _controller('rem-web', const NoReminderScheduler());
      expect(c.reminderSupported, isFalse);
      expect(c.reminderEnabled, isFalse);
    });
  });
}

class DateUtils {
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
