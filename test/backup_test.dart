import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/data/backup.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

Future<LighthouseController> _controller(String name) async {
  final controller = LighthouseController(
    LighthouseDatabase.withFactory(databaseFactoryMemory, name),
  );
  await controller.initialize();
  return controller;
}

/// A controller with a bit of everything: entries, a marked habit, settings.
Future<LighthouseController> _filled(String name) async {
  final controller = await _controller(name);
  await controller.addGoodThing(date: controller.today, text: 'Kaffee am See');
  await controller.addGoodThing(
    date: controller.today.subtract(const Duration(days: 3)),
    text: 'Brot gebacken',
  );
  await controller.toggleHabit(
    habitId: controller.habits.first.id,
    date: controller.today,
  );
  await controller.setLanguage('en');
  await controller.setUserName('Robert');
  return controller;
}

void main() {
  group('file format', () {
    test('survives a save → load round trip into a fresh install', () async {
      final source = await _filled('rt-source');
      final encoded = (await source.createBackup()).encode();

      final target = await _controller('rt-target');
      await target.restoreBackup(Backup.decode(encoded));

      expect(
        target.goodThings.map((e) => (e.id, e.text, e.date, e.createdAt)),
        unorderedEquals(
          source.goodThings.map((e) => (e.id, e.text, e.date, e.createdAt)),
        ),
      );
      expect(target.habits.map((h) => h.id), source.habits.map((h) => h.id));
      expect(
        target.isHabitCompleted(
          habitId: source.habits.first.id,
          date: source.today,
        ),
        isTrue,
      );
      expect(target.languageCode, 'en');
      expect(target.userName, 'Robert');
    });

    test('records the app version from pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*([^+\s]+)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1);

      expect(kAppVersion, version, reason: 'update kAppVersion in backup.dart');
    });

    test('names the file after the day it was made', () {
      expect(
        Backup.fileNameFor(DateTime(2026, 9, 3, 21, 5)),
        'lighthouse-backup-2026-09-03.json',
      );
    });

    test('leaves this device\'s backup history out of the file', () async {
      final controller = await _filled('device-only');
      await controller.markBackupSaved(DateTime(2026, 9, 1));
      await controller.dismissBackupReminder();

      final json =
          jsonDecode((await controller.createBackup()).encode()) as Map;
      final settings = (json['data'] as Map)['settings'] as Map;

      expect(settings.containsKey('lastBackupAt'), isFalse);
      expect(settings.containsKey('backupReminderDismissedAt'), isFalse);
      expect(settings['language'], 'en');
    });
  });

  group('validation refuses', () {
    Matcher problem(BackupProblem reason) => throwsA(
      isA<BackupException>().having((e) => e.reason, 'reason', reason),
    );

    Future<Map<String, Object?>> validJson() async {
      final controller = await _filled('valid-${DateTime.now().microsecond}');
      return jsonDecode((await controller.createBackup()).encode())
          as Map<String, Object?>;
    }

    test('text that is not JSON', () {
      expect(() => Backup.decode('hello'), problem(BackupProblem.notJson));
    });

    test('JSON from somewhere else', () {
      expect(
        () => Backup.decode('{"app": "other", "formatVersion": 1}'),
        problem(BackupProblem.notLighthouse),
      );
    });

    test('a file from a newer app version', () async {
      final json = await validJson()
        ..['formatVersion'] = 2;
      expect(
        () => Backup.decode(jsonEncode(json)),
        problem(BackupProblem.tooNew),
      );
    });

    test('a damaged record', () async {
      final json = await validJson();
      final goodThings = (json['data']! as Map)['goodThings'] as List;
      (goodThings.first as Map).remove('text');

      expect(
        () => Backup.decode(jsonEncode(json)),
        problem(BackupProblem.damaged),
      );
    });
  });

  group('restore', () {
    test('replaces everything, and undo brings the old data back', () async {
      final backupSource = await _controller('restore-source');
      await backupSource.addGoodThing(
        date: backupSource.today,
        text: 'from the backup',
      );
      final backup = Backup.decode(
        (await backupSource.createBackup()).encode(),
      );

      final device = await _filled('restore-device');
      final before = device.goodThings.map((e) => e.text).toSet();

      await device.restoreBackup(backup);

      expect(device.goodThings.map((e) => e.text), ['from the backup']);
      expect(device.languageCode, 'de');
      expect(device.hasSafetyBackup, isTrue);
      expect(device.lastBackupAt, backup.createdAt);

      await device.undoRestore();

      expect(device.goodThings.map((e) => e.text).toSet(), before);
      expect(device.languageCode, 'en');
      expect(device.hasSafetyBackup, isFalse);
    });

    test('keeps the result after a restart', () async {
      final source = await _filled('persist-source');
      final backup = Backup.decode((await source.createBackup()).encode());

      final database = LighthouseDatabase.withFactory(
        databaseFactoryMemory,
        'persist-target',
      );
      final target = LighthouseController(database);
      await target.initialize();
      await target.restoreBackup(backup);

      final restarted = LighthouseController(database);
      await restarted.initialize();

      expect(restarted.goodThings, hasLength(2));
      expect(restarted.hasSafetyBackup, isTrue);
    });
  });

  group('backup reminder', () {
    final now = DateTime(2026, 9, 30, 20);

    bool remind({
      DateTime? lastBackupAt,
      DateTime? firstEntryAt,
      DateTime? dismissedAt,
    }) {
      return shouldRemindAboutBackup(
        now: now,
        lastBackupAt: lastBackupAt,
        firstEntryAt: firstEntryAt,
        dismissedAt: dismissedAt,
      );
    }

    test('never shows for an empty install', () {
      expect(remind(), isFalse);
    });

    test('waits 30 days after the first entry', () {
      expect(
        remind(firstEntryAt: now.subtract(const Duration(days: 29))),
        isFalse,
      );
      expect(
        remind(firstEntryAt: now.subtract(const Duration(days: 30))),
        isTrue,
      );
    });

    test('counts from the last backup once there is one', () {
      final longAgo = now.subtract(const Duration(days: 200));
      expect(
        remind(
          firstEntryAt: longAgo,
          lastBackupAt: now.subtract(const Duration(days: 5)),
        ),
        isFalse,
      );
      expect(
        remind(
          firstEntryAt: longAgo,
          lastBackupAt: now.subtract(const Duration(days: 34)),
        ),
        isTrue,
      );
    });

    test('stays quiet for a week after being dismissed', () {
      final old = now.subtract(const Duration(days: 60));
      expect(
        remind(
          lastBackupAt: old,
          dismissedAt: now.subtract(const Duration(days: 6)),
        ),
        isFalse,
      );
      expect(
        remind(
          lastBackupAt: old,
          dismissedAt: now.subtract(const Duration(days: 7)),
        ),
        isTrue,
      );
    });
  });
}
