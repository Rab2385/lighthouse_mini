/// When the evening reminder should fire next.
///
/// The next [days] evenings at [hour]:[minute], skipping today if something
/// was already written today or the time has passed. Planning a whole week
/// ahead means reminders keep working when the app isn't opened for a few
/// days — and simply stop after a week, so it never nags forever.
List<DateTime> reminderTimes({
  required DateTime now,
  required int hour,
  required int minute,
  required bool wroteToday,
  int days = 7,
}) {
  return [
    for (var offset = 0; offset < days; offset++)
      if (offset > 0 || !wroteToday)
        DateTime(now.year, now.month, now.day + offset, hour, minute),
  ].where((time) => time.isAfter(now)).toList();
}
