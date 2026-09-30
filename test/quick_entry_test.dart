import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

LighthouseController _controller(String name) => LighthouseController(
  LighthouseDatabase.withFactory(databaseFactoryMemory, name),
);

bool _anyFieldFocused(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .any((field) => field.focusNode.hasFocus);

Future<void> _pumpPhoneApp(
  WidgetTester tester,
  LighthouseController controller,
) async {
  tester.view.physicalSize = const Size(375 * 3, 667 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(LighthouseApp(controller: controller));
  await tester.pumpAndSettle();
}

void main() {
  group('rules', () {
    test('only while today is empty and the setting is on', () async {
      final c = _controller('qe-rules');
      await c.initialize();
      expect(c.shouldStartWithQuickEntry, isTrue);

      await c.setQuickEntryOnOpen(false);
      expect(c.shouldStartWithQuickEntry, isFalse);

      await c.setQuickEntryOnOpen(true);
      await c.addGoodThing(date: c.today, text: 'schon geschrieben');
      expect(c.shouldStartWithQuickEntry, isFalse);
    });

    test('shortcut ids map to actions', () {
      expect(AppAction.fromId('add'), AppAction.addGoodThing);
      expect(AppAction.fromId('habits'), AppAction.habits);
      expect(AppAction.fromId('nope'), isNull);
      expect(AppAction.fromId(null), isNull);
    });
  });

  group('on a phone', () {
    testWidgets('opens with today\'s field focused', (tester) async {
      final controller = _controller('qe-phone');
      await tester.runAsync(controller.initialize);

      await _pumpPhoneApp(tester, controller);

      expect(_anyFieldFocused(tester), isTrue);
    });

    testWidgets('does not pop up a keyboard once today has an entry', (
      tester,
    ) async {
      final controller = _controller('qe-phone-written');
      await tester.runAsync(() async {
        await controller.initialize();
        await controller.addGoodThing(date: controller.today, text: 'Kaffee');
      });

      await _pumpPhoneApp(tester, controller);

      expect(_anyFieldFocused(tester), isFalse);
    });

    testWidgets('the habits shortcut opens the Habits tab', (tester) async {
      final controller = _controller('qe-habits');
      await tester.runAsync(() async {
        await controller.initialize();
        await controller.setQuickEntryOnOpen(false);
      });

      await _pumpPhoneApp(tester, controller);
      controller.requestAction(AppAction.habits);
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 1);
    });
  });
}
