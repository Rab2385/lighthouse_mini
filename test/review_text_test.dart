import 'package:flutter_test/flutter_test.dart';

import 'package:lighthouse_mini/l10n/app_strings.dart';
import 'package:lighthouse_mini/models/good_thing.dart';
import 'package:lighthouse_mini/util/review_text.dart';

GoodThing _entry(String text, DateTime date, int minute) {
  final created = DateTime(date.year, date.month, date.day, 20, minute);
  return GoodThing(
    id: text,
    date: date,
    text: text,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final entries = [
    _entry('Lange mit Papa telefoniert', DateTime(2026, 9, 27), 1),
    _entry('Sonnenuntergang am Fluss', DateTime(2026, 9, 29), 0),
    _entry('Brot selbst gebacken', DateTime(2026, 9, 27), 5),
  ];

  test('lists newest day first, a day in writing order (German)', () {
    expect(
      goodThingsAsText(
        periodLabel: 'September 2026',
        entries: entries,
        strings: const AppStrings('de'),
      ),
      'Good Things · September 2026\n'
      'Di., 29.09. – Sonnenuntergang am Fluss\n'
      'So., 27.09. – Lange mit Papa telefoniert\n'
      'So., 27.09. – Brot selbst gebacken',
    );
  });

  test('uses the English day format', () {
    expect(
      goodThingsAsText(
        periodLabel: 'September 2026',
        entries: entries.take(1).toList(),
        strings: const AppStrings('en'),
      ),
      'Good Things · September 2026\n'
      'Sun, 09/27 – Lange mit Papa telefoniert',
    );
  });

  test('is just the heading when there is nothing to copy', () {
    expect(
      goodThingsAsText(
        periodLabel: '2026',
        entries: const [],
        strings: const AppStrings('de'),
      ),
      'Good Things · 2026',
    );
  });
}
