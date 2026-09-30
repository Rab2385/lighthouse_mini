import 'dart:convert';

import '../models/good_thing.dart';
import '../models/habit.dart';

/// Shown in backups so a file can later be traced to the version that wrote
/// it. Keep in step with `version:` in pubspec.yaml.
const String kAppVersion = '0.1.0';

/// Why a file can't be restored. [reason] picks the user-facing message.
enum BackupProblem { notJson, notLighthouse, tooNew, damaged }

class BackupException implements Exception {
  const BackupException(this.reason, [this.detail]);

  final BackupProblem reason;
  final String? detail;

  @override
  String toString() =>
      'BackupException($reason${detail == null ? '' : ': $detail'})';
}

/// Everything the app stores, as plain maps — the unit that is written to and
/// read from a backup file, and swapped in one database transaction.
class BackupData {
  const BackupData({
    required this.goodThings,
    required this.habits,
    required this.habitEntries,
    required this.settings,
  });

  /// Raw records, exactly as stored.
  final List<Map<String, Object?>> goodThings;
  final List<Map<String, Object?>> habits;

  /// `{key, habitId, date}` per marked habit day.
  final List<Map<String, Object?>> habitEntries;
  final Map<String, Object?> settings;

  int get goodThingCount => goodThings.length;
  int get habitCount => habits.length;
}

/// A validated backup file, ready to preview and restore.
class Backup {
  const Backup({
    required this.createdAt,
    required this.appVersion,
    required this.data,
  });

  static const String appId = 'lighthouse_mini';

  /// The newest file format this app can read.
  static const int formatVersion = 1;

  final DateTime createdAt;
  final String appVersion;
  final BackupData data;

  /// `lighthouse-backup-2026-09-30.json`
  static String fileNameFor(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'lighthouse-backup-${date.year}-${two(date.month)}-${two(date.day)}.json';
  }

  String encode() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appId,
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'data': {
        'goodThings': data.goodThings,
        'habits': data.habits,
        'habitEntries': data.habitEntries,
        'settings': data.settings,
      },
    });
  }

  /// Parses and fully validates [source]. Throws [BackupException] and never
  /// returns a half-valid backup, so nothing is touched unless all of it is
  /// readable.
  static Backup decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (error) {
      throw BackupException(BackupProblem.notJson, error.message);
    }

    if (json is! Map<String, Object?> || json['app'] != appId) {
      throw const BackupException(BackupProblem.notLighthouse);
    }

    final version = json['formatVersion'];
    if (version is! int || version < 1) {
      throw const BackupException(BackupProblem.damaged, 'formatVersion');
    }
    if (version > formatVersion) {
      throw BackupException(BackupProblem.tooNew, '$version');
    }

    try {
      final data = json['data']! as Map<String, Object?>;

      final goodThings = _records(data['goodThings']);
      final habits = _records(data['habits']);
      final habitEntries = _records(data['habitEntries']);
      final settings = Map<String, Object?>.from(
        (data['settings'] ?? const <String, Object?>{}) as Map,
      );

      // Every record must load in the app, or the restore is refused.
      for (final record in goodThings) {
        GoodThing.fromMap(record);
      }
      for (final record in habits) {
        Habit.fromMap(record);
      }
      for (final entry in habitEntries) {
        entry['key']! as String;
        entry['habitId']! as String;
        DateTime.parse(entry['date']! as String);
      }

      return Backup(
        createdAt: DateTime.parse(json['createdAt']! as String),
        appVersion: json['appVersion'] as String? ?? '?',
        data: BackupData(
          goodThings: goodThings,
          habits: habits,
          habitEntries: habitEntries,
          settings: settings,
        ),
      );
    } on BackupException {
      rethrow;
    } catch (error) {
      throw BackupException(BackupProblem.damaged, '$error');
    }
  }

  static List<Map<String, Object?>> _records(Object? value) {
    return [
      for (final item in (value ?? const <Object?>[]) as List)
        Map<String, Object?>.from(item as Map),
    ];
  }
}

/// Whether to nudge the user to save a backup.
///
/// Measured from the last backup, or — never backed up — from the first
/// entry, so a fresh install is never nagged. Once dismissed it stays quiet
/// for a week.
bool shouldRemindAboutBackup({
  required DateTime now,
  required DateTime? lastBackupAt,
  required DateTime? firstEntryAt,
  required DateTime? dismissedAt,
  Duration after = const Duration(days: 30),
  Duration snooze = const Duration(days: 7),
}) {
  final since = lastBackupAt ?? firstEntryAt;

  if (since == null || now.difference(since) < after) {
    return false;
  }

  return dismissedAt == null || now.difference(dismissedAt) >= snooze;
}
