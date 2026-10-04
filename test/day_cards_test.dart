import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show databaseFactoryMemory;

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/l10n/app_strings.dart';
import 'package:lighthouse_mini/pages/good_things_page.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

Future<LighthouseController> _pumpPhone(
  WidgetTester tester,
  String name, {
  List<String> todayEntries = const [],
  Future<void> Function(LighthouseController controller)? setup,
}) async {
  tester.view.physicalSize = const Size(375 * 3, 667 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final controller = LighthouseController(
    LighthouseDatabase.withFactory(databaseFactoryMemory, name),
    deviceLanguage: () => 'de',
  );
  await tester.runAsync(() async {
    await controller.initialize();
    // Keep the start calm for these tests: no auto-focus from #17.
    await controller.setQuickEntryOnOpen(false);
    for (final text in todayEntries) {
      await controller.addGoodThing(date: controller.today, text: text);
    }
    await setup?.call(controller);
  });

  await tester.pumpWidget(LighthouseApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('only today shows an input field', (tester) async {
    await _pumpPhone(tester, 'cards-one-field');

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Was war heute gut?'), findsOneWidget);
  });

  testWidgets('an empty day is a single short line', (tester) async {
    final controller = await _pumpPhone(tester, 'cards-height');
    final today = controller.today;

    // Any other day of this month that is built on screen.
    final other = [for (var d = 1; d <= 31; d++) d]
        .where((d) => d != today.day)
        .map((d) => find.text(d.toString().padLeft(2, '0')))
        .firstWhere((f) => f.evaluate().isNotEmpty);

    // The card's own box, without the 8 px gap below it.
    final card = find
        .ancestor(of: other, matching: find.byType(DecoratedBox))
        .first;
    expect(tester.getSize(card).height, lessThan(70));
  });

  testWidgets('＋ opens that day with focus and closes the previous one', (
    tester,
  ) async {
    final controller = await _pumpPhone(tester, 'cards-open');
    final today = controller.today;

    // Two other days of this month right next to today, so they are on
    // screen whatever the date (on the 1st the list starts at the top).
    Finder addButtonOn(int offset) {
      final day = today.day > 2 ? today.day - offset : today.day + offset;
      // Built but possibly just above the viewport, hence skipOffstage.
      return find.descendant(
        of: find.byKey(
          ValueKey('${today.year}-${today.month}-$day'),
          skipOffstage: false,
        ),
        matching: find.byTooltip('Eintrag hinzufügen', skipOffstage: false),
        skipOffstage: false,
      );
    }

    await tester.ensureVisible(addButtonOn(1));
    await tester.pumpAndSettle();
    await tester.tap(addButtonOn(1));
    await tester.pumpAndSettle();

    // Opening scrolls that day to the top, which can push today's card just
    // out of view, so count the built fields rather than the visible ones.
    final fields = find.descendant(
      of: find.byType(GoodThingsPage, skipOffstage: false),
      matching: find.byType(TextField, skipOffstage: false),
      skipOffstage: false,
    );
    expect(fields, findsNWidgets(2)); // today + opened day
    final focused = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where((field) => field.focusNode.hasFocus);
    expect(focused, hasLength(1));

    await tester.ensureVisible(addButtonOn(2));
    await tester.pumpAndSettle();
    await tester.tap(addButtonOn(2));
    await tester.pumpAndSettle();
    expect(fields, findsNWidgets(2)); // still only two
  });

  testWidgets('swipe left deletes an entry, with undo', (tester) async {
    final controller = await _pumpPhone(
      tester,
      'cards-swipe',
      todayEntries: ['Kaffee am See'],
    );

    await tester.drag(find.text('Kaffee am See'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(controller.goodThings, isEmpty);
    expect(find.text('Rückgängig'), findsOneWidget);

    // The entry is back in memory at once; saving it runs in the background.
    await tester.tap(find.text('Rückgängig'));
    await tester.pump();
    expect(controller.goodThings.single.text, 'Kaffee am See');

    // Let the SnackBar time out before the test ends.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('the edit dialog can delete too', (tester) async {
    final controller = await _pumpPhone(
      tester,
      'cards-dialog-delete',
      todayEntries: ['Brot gebacken'],
    );

    await tester.tap(find.text('Brot gebacken'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(controller.goodThings, isEmpty);
  });

  group('status next to the weekday (#38)', () {
    // Any day line in the list, e.g. "Samstag · Good".
    // Built cards only; the list starts at today, so yesterday sits just
    // above the viewport.
    Finder statusLine(String text) => find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().endsWith(text),
      skipOffstage: false,
    );

    testWidgets('empty days show no "Good" or "Ahead"', (tester) async {
      await _pumpPhone(tester, 'cards-status-empty');

      expect(statusLine(' · Good'), findsNothing);
      expect(statusLine(' · Ahead'), findsNothing);
      expect(find.text('Heute'), findsWidgets);
    });

    testWidgets('a past day with entries shows how many', (tester) async {
      late DateTime day;
      await _pumpPhone(
        tester,
        'cards-status-past',
        setup: (controller) async {
          final today = controller.today;
          // Yesterday, or the day before on the 1st (then it's last month and
          // the 2nd stands in as a future day below instead).
          day = today.day > 1
              ? DateTime(today.year, today.month, today.day - 1)
              : DateTime(today.year, today.month, today.day + 1);
          await controller.addGoodThing(date: day, text: 'Radtour');
          await controller.addGoodThing(date: day, text: 'Anruf von Oma');
        },
      );

      final isPast = day.isBefore(DateTime.now());
      expect(
        statusLine(isPast ? ' · 2 Einträge' : ' · Ahead · 2'),
        findsOneWidget,
      );
    });

    testWidgets('a coming day with an entry is marked Ahead', (tester) async {
      late DateTime day;
      await _pumpPhone(
        tester,
        'cards-status-ahead',
        setup: (controller) async {
          final today = controller.today;
          day = DateTime(today.year, today.month, today.day + 1);
          await controller.addGoodThing(date: day, text: 'Konzert');
        },
      );

      if (day.month != DateTime.now().month) {
        // Last day of the month: tomorrow lives on the next page.
        return;
      }
      expect(statusLine(' · Ahead · 1'), findsOneWidget);
      expect(statusLine(' · 1 Eintrag'), findsNothing);
    });

    test('entry counts read naturally', () {
      expect(const AppStrings('de').entryCount(1), '1 Eintrag');
      expect(const AppStrings('de').entryCount(3), '3 Einträge');
      expect(const AppStrings('en').entryCount(1), '1 entry');
      expect(const AppStrings('en').entryCount(3), '3 entries');
    });
  });
}
