/// A greeting that depends on the time of day and, when known, the user's name.
///
/// Examples: `Guten Morgen` · `Guten Abend, Robert`.
String greetingForTime(DateTime now, String name) {
  final trimmedName = name.trim();
  final hour = now.hour;

  final String base;
  if (hour >= 5 && hour < 12) {
    base = 'Guten Morgen';
  } else if (hour >= 12 && hour < 18) {
    base = 'Guten Tag';
  } else if (hour >= 18 && hour < 22) {
    base = 'Guten Abend';
  } else {
    base = 'Gute Nacht';
  }

  return trimmedName.isEmpty ? base : '$base, $trimmedName';
}
