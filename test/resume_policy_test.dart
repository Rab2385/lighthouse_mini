import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

import 'package:lighthouse_mini/util/resume_policy.dart';

void main() {
  final morning = DateTime(2026, 9, 29, 9, 0);

  bool leaveAndReturn(
    ResumePolicy policy,
    DateTime leftAt,
    DateTime backAt, {
    bool background = true,
  }) {
    policy.onStateChanged(AppLifecycleState.inactive, now: leftAt);
    if (background) {
      policy.onStateChanged(AppLifecycleState.hidden, now: leftAt);
      policy.onStateChanged(AppLifecycleState.paused, now: leftAt);
    }
    return policy.onStateChanged(AppLifecycleState.resumed, now: backAt);
  }

  test('notification shade (inactive only) keeps the view', () {
    final policy = ResumePolicy();
    final back = morning.add(const Duration(hours: 2));

    expect(leaveAndReturn(policy, morning, back, background: false), isFalse);
  });

  test('a short trip to the background keeps the view', () {
    final policy = ResumePolicy();
    final back = morning.add(const Duration(minutes: 3));

    expect(leaveAndReturn(policy, morning, back), isFalse);
  });

  test('ten minutes or more away goes back to today', () {
    final policy = ResumePolicy();
    final back = morning.add(const Duration(minutes: 10));

    expect(leaveAndReturn(policy, morning, back), isTrue);
  });

  test('a new day goes back to today even after a minute', () {
    final policy = ResumePolicy();
    final beforeMidnight = DateTime(2026, 9, 29, 23, 59, 30);
    final afterMidnight = DateTime(2026, 9, 30, 0, 0, 20);

    expect(leaveAndReturn(policy, beforeMidnight, afterMidnight), isTrue);
  });

  test('each resume is judged on its own trip away', () {
    final policy = ResumePolicy();

    expect(
      leaveAndReturn(policy, morning, morning.add(const Duration(hours: 1))),
      isTrue,
    );

    final later = morning.add(const Duration(hours: 2));
    expect(
      leaveAndReturn(policy, later, later.add(const Duration(minutes: 1))),
      isFalse,
    );
  });
}
