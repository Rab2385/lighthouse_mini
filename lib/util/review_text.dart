import '../l10n/app_strings.dart';
import '../models/good_thing.dart';

/// Good Things of a period as plain text, one line per entry, newest day
/// first — for pasting into a note, a letter or a message.
///
/// ```
/// Good Things · September 2026
/// Di., 29.09. – Sonnenuntergang am Fluss
/// So., 27.09. – Lange mit Papa telefoniert
/// ```
String goodThingsAsText({
  required String periodLabel,
  required List<GoodThing> entries,
  required AppStrings strings,
}) {
  final lines = [
    '${strings.goodThings} · $periodLabel',
    for (final entry in newestDayFirst(entries))
      '${strings.dayLabel(entry.date)} – ${entry.text}',
  ];

  return lines.join('\n');
}

/// Newest day first; within a day in the order they were written.
List<GoodThing> newestDayFirst(List<GoodThing> entries) {
  return [...entries]..sort((a, b) {
    final byDay = b.date.compareTo(a.date);
    return byDay != 0 ? byDay : a.createdAt.compareTo(b.createdAt);
  });
}
