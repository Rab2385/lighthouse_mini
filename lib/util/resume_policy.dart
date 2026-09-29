import 'package:flutter/widgets.dart' show AppLifecycleState;

/// Decides when coming back to the app should jump the view back to today.
///
/// Only a real trip to the background counts (`hidden` / `paused`). A pulled
/// down notification shade, Control Center or a system dialog only makes the
/// app `inactive` and must not throw away what the user was looking at.
class ResumePolicy {
  ResumePolicy({this.awayThreshold = const Duration(minutes: 10)});

  /// Being away at least this long lands on today again.
  final Duration awayThreshold;

  DateTime? _leftAt;

  /// Feed every lifecycle change in. Returns true when the caller should go
  /// back to today; [now] is only a parameter so this can be tested.
  bool onStateChanged(AppLifecycleState state, {DateTime? now}) {
    final time = now ?? DateTime.now();

    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // hidden precedes paused; keep the earlier moment.
        _leftAt ??= time;
        return false;
      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;

        if (leftAt == null) {
          return false;
        }

        final dayChanged =
            leftAt.year != time.year ||
            leftAt.month != time.month ||
            leftAt.day != time.day;

        return dayChanged || time.difference(leftAt) >= awayThreshold;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        return false;
    }
  }
}
