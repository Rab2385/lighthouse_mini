import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/models/good_thing.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

/// Stores entries directly, so past dates beyond the app's own limits work.
Future<LighthouseController> _withEntries(
  String name,
  Map<DateTime, List<String>> entries,
) async {
  final database = LighthouseDatabase.withFactory(databaseFactoryMemory, name);
  var n = 0;
  for (final day in entries.entries) {
    for (final text in day.value) {
      n++;
      final created = day.key.add(Duration(hours: 20, minutes: n));
      await database.saveGoodThing(
        GoodThing(
          id: '$name-$n',
          date: day.key,
          text: text,
          createdAt: created,
          updatedAt: created,
        ),
      );
    }
  }
  final controller = LighthouseController(database);
  await controller.initialize();
  return controller;
}

void main() {
  test('prefers exactly one year ago', () async {
    final c = await _withEntries('year', {
      DateTime(2025, 9, 30): ['Mit Anna am See'],
      DateTime(2026, 8, 30): ['Ein Monat her'],
    });

    final memory = c.memoryFor(DateTime(2026, 9, 30))!;
    expect(memory.age, MemoryAge.year);
    expect(memory.entry.text, 'Mit Anna am See');
  });

  test('falls back to exactly one month ago', () async {
    final c = await _withEntries('month', {
      DateTime(2026, 8, 30): ['Ein Monat her'],
      DateTime(2026, 8, 29): ['Falscher Tag'],
    });

    final memory = c.memoryFor(DateTime(2026, 9, 30))!;
    expect(memory.age, MemoryAge.month);
    expect(memory.entry.text, 'Ein Monat her');
  });

  test('has nothing when neither day has an entry', () async {
    final c = await _withEntries('none', {
      DateTime(2026, 9, 29): ['Gestern'],
    });

    expect(c.memoryFor(DateTime(2026, 9, 30)), isNull);
  });

  test('skips days that did not exist (31.03. → no 31.02.)', () async {
    final c = await _withEntries('missing-day', {
      // What a naive "month - 1" would roll 31.02. over to.
      DateTime(2026, 3, 3): ['Rollover'],
    });

    expect(c.memoryFor(DateTime(2026, 3, 31)), isNull);
  });

  test('29.02. has a memory from the last leap day only via a month', () async {
    final c = await _withEntries('leap', {
      DateTime(2028, 1, 29): ['Januar'],
    });

    // 29.02.2027 doesn't exist, so the year step is skipped.
    final memory = c.memoryFor(DateTime(2028, 2, 29))!;
    expect(memory.age, MemoryAge.month);
  });

  test('keeps the same pick all day among several entries', () async {
    final c = await _withEntries('stable', {
      DateTime(2025, 9, 30): ['Eins', 'Zwei', 'Drei'],
    });

    final day = DateTime(2026, 9, 30);
    final first = c.memoryFor(day)!.entry.id;
    for (var i = 0; i < 5; i++) {
      expect(c.memoryFor(day)!.entry.id, first);
    }
  });

  test('can be dismissed for today and switched off', () async {
    final c = await _withEntries('dismiss', {
      DateTime.now().subtract(const Duration(days: 365)): ['Irgendwas'],
    });
    // Only meaningful if a year ago today has the entry (not on 29.02.).
    final hasMemory = c.todaysMemory != null;

    await c.dismissTodaysMemory();
    expect(c.todaysMemory, isNull);

    await c.setShowMemories(false);
    expect(c.showMemories, isFalse);
    expect(c.todaysMemory, isNull);
    expect(hasMemory || DateTime.now().month == 2, isTrue);
  });
}
