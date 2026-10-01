import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show databaseFactoryMemory;

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/l10n/app_strings.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';
import 'package:lighthouse_mini/util/year_heatmap.dart';

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final weight in [400, 500, 600, 700]) {
    final bytes = File('assets/fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<LighthouseController> _controller(String name) async {
  final controller = LighthouseController(
    LighthouseDatabase.withFactory(databaseFactoryMemory, name),
    deviceLanguage: () => 'de',
  );
  await controller.initialize();
  await controller.setQuickEntryOnOpen(false);
  return controller;
}

/// Opens Review on a 320 × 568 phone and selects the year chip.
Future<LighthouseController> _openYear(
  WidgetTester tester,
  String name, {
  double textScale = 1.0,
  Future<void> Function(LighthouseController)? setup,
}) async {
  tester.view.physicalSize = const Size(320 * 2, 568 * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  late LighthouseController controller;
  await tester.runAsync(() async {
    controller = await _controller(name);
    await setup?.call(controller);
  });

  await tester.pumpWidget(LighthouseApp(controller: controller));
  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.insights_outlined),
    ),
  );
  await tester.pumpAndSettle();
  // On a 320 px phone the year chip starts scrolled out of view.
  final yearChip = find.text('${controller.today.year}');
  await tester.ensureVisible(yearChip);
  await tester.pumpAndSettle();
  await tester.tap(yearChip);
  await tester.pumpAndSettle();
  return controller;
}

Finder _box(String message) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == message,
);

void main() {
  group('heatLevel', () {
    test('steps at 25, 50 and 75 %', () {
      expect(heatLevel(0, 30), 0);
      expect(heatLevel(1, 30), 1);
      expect(heatLevel(7, 28), 2); // exactly 25 %
      expect(heatLevel(14, 28), 3); // exactly 50 %
      expect(heatLevel(20, 28), 3);
      expect(heatLevel(21, 28), 4); // exactly 75 %
      expect(heatLevel(31, 31), 4);
    });

    test('a month without scored days is empty', () {
      expect(heatLevel(0, 0), 0);
      expect(heatLevel(3, 0), 0);
    });
  });

  group('scoredDaysInMonth', () {
    final today = DateTime(2026, 9, 30, 21, 15);

    test('whole month once it is over', () {
      expect(scoredDaysInMonth(DateTime(2026, 2), today), 28);
      expect(scoredDaysInMonth(DateTime(2026, 8), today), 31);
    });

    test('up to today in the current month', () {
      expect(scoredDaysInMonth(DateTime(2026, 9), DateTime(2026, 9, 12)), 12);
      expect(scoredDaysInMonth(DateTime(2026, 9), today), 30);
    });

    test('nothing for months still ahead', () {
      expect(scoredDaysInMonth(DateTime(2026, 10), today), 0);
    });
  });

  test('goodThingDaysInRange counts days, not entries', () async {
    final controller = await _controller('year-days');
    final today = controller.today;
    await controller.addGoodThing(date: today, text: 'one');
    await controller.addGoodThing(date: today, text: 'two');
    await controller.addGoodThing(
      date: today.subtract(const Duration(days: 1)),
      text: 'three',
    );

    expect(
      controller.goodThingDaysInRange(
        today.subtract(const Duration(days: 40)),
        today,
      ),
      2,
    );
  });

  group('year card', () {
    setUpAll(_loadRoboto);

    testWidgets('only shows for the year chip', (tester) async {
      await _openYear(tester, 'year-card-visible');
      expect(find.text('Das Jahr'), findsOneWidget);

      await tester.ensureVisible(find.text('Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monat'));
      await tester.pumpAndSettle();
      expect(find.text('Das Jahr'), findsNothing);
    });

    testWidgets('scores the current month up to today', (tester) async {
      final controller = await _openYear(
        tester,
        'year-card-score',
        setup: (controller) async {
          await controller.toggleHabit(
            habitId: 'water',
            date: controller.today,
          );
          await controller.addGoodThing(date: controller.today, text: 'Tee');
        },
      );
      final today = controller.today;
      final month = const AppStrings('de').monthNames[today.month - 1];

      expect(_box('Water, $month: 1 von ${today.day} Tagen'), findsOneWidget);
      expect(
        _box('Good Things, $month: 1 von ${today.day} Tagen'),
        findsOneWidget,
      );
      if (today.month < 12) {
        final next = const AppStrings('de').monthNames[today.month];
        expect(_box('Water, $next: noch offen'), findsOneWidget);
      }
    });

    testWidgets('tapping a month shows that month in Review', (tester) async {
      final controller = await _openYear(tester, 'year-card-tap');
      final year = controller.today.year;

      await tester.tap(_box('Good Things, Januar: 0 von 31 Tagen'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Januar $year'), findsOneWidget);
      expect(find.text('Das Jahr'), findsNothing);
    });

    for (final scale in const [1.0, 1.3]) {
      testWidgets('fits a 320 px phone, text ×$scale', (tester) async {
        await _openYear(tester, 'year-card-small-$scale', textScale: scale);

        // Twelve boxes still get a tappable width next to each other.
        final box = tester.getSize(
          find
              .descendant(
                of: _box('Good Things, Januar: 0 von 31 Tagen'),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(box.width, greaterThanOrEqualTo(14));

        await tester.drag(find.text('Das Jahr'), const Offset(0, -600));
        await tester.pumpAndSettle();
      });
    }
  });
}
