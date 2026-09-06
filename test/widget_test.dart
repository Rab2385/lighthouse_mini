import 'package:flutter_test/flutter_test.dart';

import 'package:lighthouse_mini/models/good_thing.dart';
import 'package:lighthouse_mini/models/habit.dart';
import 'package:lighthouse_mini/l10n/app_strings.dart';
import 'package:lighthouse_mini/util/greeting.dart';

void main() {
  test('GoodThing survives a toMap/fromMap round trip', () {
    final original = GoodThing(
      id: 'gt-1',
      date: DateTime(2026, 9, 6),
      text: 'Sonne genossen',
      createdAt: DateTime(2026, 9, 6, 8, 30),
      updatedAt: DateTime(2026, 9, 6, 8, 30),
    );

    final restored = GoodThing.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.date, original.date);
    expect(restored.text, original.text);
    expect(restored.createdAt, original.createdAt);
    expect(restored.updatedAt, original.updatedAt);
  });

  test('Habit survives a toMap/fromMap round trip', () {
    final original = Habit(
      id: 'h-1',
      name: 'Reading',
      emoji: '📖',
      description: '30 minutes',
      isArchived: false,
      sortOrder: 2,
      createdAt: DateTime(2026, 1, 1),
    );

    final restored = Habit.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.emoji, original.emoji);
    expect(restored.description, original.description);
    expect(restored.isArchived, original.isArchived);
    expect(restored.sortOrder, original.sortOrder);
    expect(restored.createdAt, original.createdAt);
  });

  test('Habit.fromMap falls back to defaults for missing fields', () {
    final restored = Habit.fromMap({
      'id': 'h-2',
      'name': 'Water',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });

    expect(restored.emoji, '✓');
    expect(restored.description, '');
    expect(restored.isArchived, false);
    expect(restored.sortOrder, 0);
  });

  group('greetingForTime', () {
    const de = AppStrings('de');
    const en = AppStrings('en');
    DateTime at(int hour) => DateTime(2026, 9, 6, hour);

    test('changes with the time of day', () {
      expect(greetingForTime(at(7), '', de), 'Guten Morgen');
      expect(greetingForTime(at(13), '', de), 'Guten Tag');
      expect(greetingForTime(at(20), '', de), 'Guten Abend');
      expect(greetingForTime(at(2), '', de), 'Gute Nacht');
    });

    test('boundaries fall on the later greeting', () {
      expect(greetingForTime(at(5), '', de), 'Guten Morgen');
      expect(greetingForTime(at(12), '', de), 'Guten Tag');
      expect(greetingForTime(at(18), '', de), 'Guten Abend');
      expect(greetingForTime(at(22), '', de), 'Gute Nacht');
      expect(greetingForTime(at(4), '', de), 'Gute Nacht');
    });

    test('appends the name when one is set', () {
      expect(greetingForTime(at(7), 'Robert', de), 'Guten Morgen, Robert');
      expect(greetingForTime(at(7), '  Robert  ', de), 'Guten Morgen, Robert');
      expect(greetingForTime(at(7), '   ', de), 'Guten Morgen');
    });

    test('uses the English table', () {
      expect(greetingForTime(at(7), '', en), 'Good morning');
      expect(greetingForTime(at(20), 'Robert', en), 'Good evening, Robert');
    });
  });
}
