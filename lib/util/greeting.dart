import '../l10n/app_strings.dart';

/// A greeting that depends on the time of day and, when known, the user's name.
///
/// Examples: `Guten Morgen` · `Good evening, Robert`.
String greetingForTime(DateTime now, String name, AppStrings strings) {
  final hour = now.hour;

  final String base;
  if (hour >= 5 && hour < 12) {
    base = strings.greetingMorning;
  } else if (hour >= 12 && hour < 18) {
    base = strings.greetingDay;
  } else if (hour >= 18 && hour < 22) {
    base = strings.greetingEvening;
  } else {
    base = strings.greetingNight;
  }

  final trimmedName = name.trim();
  return trimmedName.isEmpty ? base : '$base, $trimmedName';
}
