/// How dark a month box in the Review year card is: 0 (nothing) to 4.
///
/// Based on the share of [days] that were [done]: under 25 %, under 50 %,
/// under 75 %, 75 % or more.
int heatLevel(int done, int days) {
  if (days <= 0 || done <= 0) {
    return 0;
  }

  final share = done / days;

  if (share < 0.25) {
    return 1;
  }
  if (share < 0.5) {
    return 2;
  }
  if (share < 0.75) {
    return 3;
  }
  return 4;
}

/// The days of [month] a year box is scored against: the whole month once
/// it's over, the days up to [today] in the current month, and none for a
/// month that hasn't started — so the year never looks "missed" ahead of time.
int scoredDaysInMonth(DateTime month, DateTime today) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  final day = DateTime(today.year, today.month, today.day);

  if (day.isBefore(first)) {
    return 0;
  }
  if (day.isAfter(last)) {
    return last.day;
  }
  return day.day;
}
