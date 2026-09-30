import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

Future<LighthouseController> _pumpPhone(
  WidgetTester tester,
  String name, {
  List<String> todayEntries = const [],
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
    await _pumpPhone(tester, 'cards-open');

    final addButtons = find.byTooltip('Eintrag hinzufügen');
    await tester.ensureVisible(addButtons.last);
    await tester.pumpAndSettle();
    await tester.tap(addButtons.last);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2)); // today + opened day
    final focused = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where((field) => field.focusNode.hasFocus);
    expect(focused, hasLength(1));

    final another = find.byTooltip('Eintrag hinzufügen').first;
    await tester.ensureVisible(another);
    await tester.pumpAndSettle();
    await tester.tap(another);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2)); // still only two
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
}
