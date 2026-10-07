import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show databaseFactoryMemory;

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/l10n/app_strings.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final weight in [400, 500, 600, 700]) {
    final bytes = File('assets/fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<LighthouseController> _pumpPhone(
  WidgetTester tester,
  String name, {
  String language = 'de',
}) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final controller = LighthouseController(
    LighthouseDatabase.withFactory(databaseFactoryMemory, name),
    deviceLanguage: () => language,
  );
  await tester.runAsync(() async {
    await controller.initialize();
    await controller.setQuickEntryOnOpen(false);
  });

  await tester.pumpWidget(LighthouseApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadRoboto);

  group('habit days for screen readers (#40)', () {
    testWidgets('say habit, day and whether it is done', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = await _pumpPhone(tester, 'a11y-compact');
      await _openTab(tester, Icons.grid_view_outlined);

      final today = find.bySemanticsLabel('Water, heute');
      expect(today, findsOneWidget);
      expect(
        tester.getSemantics(today),
        matchesSemantics(
          label: 'Water, heute',
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Water, gestern'), findsOneWidget);

      // Ticking it is announced as the new state.
      await tester.tap(today);
      await tester.pumpAndSettle();
      expect(
        controller.isHabitCompleted(habitId: 'water', date: controller.today),
        isTrue,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Water, heute')),
        matchesSemantics(
          label: 'Water, heute',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a day still to come is disabled in the month grid', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = await _pumpPhone(tester, 'a11y-grid');
      await _openTab(tester, Icons.grid_view_outlined);
      await tester.tap(find.byTooltip('Monat'));
      await tester.pumpAndSettle();

      final today = controller.today;
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      if (tomorrow.month != today.month) {
        return; // Last day of the month: no future day in this grid.
      }
      final label = const AppStrings(
        'de',
      ).habitDayLabel('Water', tomorrow, today);
      final cell = find.bySemanticsLabel(label);
      await tester.ensureVisible(cell);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(cell),
        matchesSemantics(
          label: label,
          hint: 'Zukünftige Tage sind gesperrt.',
          isButton: true,
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });

    test('labels read naturally in both languages', () {
      final today = DateTime(2026, 9, 30);
      const de = AppStrings('de');
      const en = AppStrings('en');

      expect(de.habitDayLabel('Water', today, today), 'Water, heute');
      expect(
        de.habitDayLabel('Water', DateTime(2026, 9, 29), today),
        'Water, gestern',
      );
      expect(
        de.habitDayLabel('Water', DateTime(2026, 9, 22), today),
        'Water, Dienstag, 22. September',
      );
      expect(en.habitDayLabel('Water', today, today), 'Water, today');
      expect(
        en.habitDayLabel('Water', DateTime(2026, 10, 1), today),
        'Water, Thursday, October 1',
      );
    });
  });

  group('Flutter accessibility guidelines on every tab', () {
    final tabs = {
      'Good Things': Icons.auto_awesome_outlined,
      'Habits': Icons.grid_view_outlined,
      'Review': Icons.insights_outlined,
      'Settings': Icons.settings_outlined,
    };

    for (final MapEntry(key: name, value: icon) in tabs.entries) {
      testWidgets(name, (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpPhone(tester, 'a11y-guidelines-$name');
        if (icon != Icons.auto_awesome_outlined) {
          await _openTab(tester, icon); // Good Things is already open.
        }

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  });

  testWidgets('month grid: every cell is labelled, text has contrast', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpPhone(tester, 'a11y-grid-guidelines');
    await _openTab(tester, Icons.grid_view_outlined);
    await tester.tap(find.byTooltip('Monat'));
    await tester.pumpAndSettle();

    // Cell size is a deliberate trade-off here (the whole month in view);
    // the default Gestern / Heute list has the full 48 dp targets.
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
