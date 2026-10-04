import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show databaseFactoryMemory;

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';
import 'package:lighthouse_mini/widgets/page_title.dart';

/// Measure with the real font — the default test font draws every glyph as
/// a full-width block.
Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final weight in [400, 500, 600, 700]) {
    final bytes = File('assets/fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<LighthouseController> _pump320(WidgetTester tester, String name) async {
  tester.view.physicalSize = const Size(320 * 2, 568 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final controller = LighthouseController(
    LighthouseDatabase.withFactory(databaseFactoryMemory, name),
    deviceLanguage: () => 'de',
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

  testWidgets('the Habits page is called like its tab (#39)', (tester) async {
    await _pump320(tester, 'titles-habits');
    await _openTab(tester, Icons.grid_view_outlined);

    expect(
      find.descendant(
        of: find.byType(PageTitle),
        matching: find.text('Habits'),
      ),
      findsOneWidget,
    );
    expect(find.text('Habit Tracker'), findsNothing);
  });

  testWidgets('a whole year in Review is just "2026" (#39)', (tester) async {
    final controller = await _pump320(tester, 'titles-year');
    final year = controller.today.year;
    await _openTab(tester, Icons.insights_outlined);

    final yearChip = find.text('$year');
    await tester.ensureVisible(yearChip);
    await tester.pumpAndSettle();
    await tester.tap(yearChip);
    await tester.pumpAndSettle();

    final subtitle = find.textContaining('$year · ');
    expect(subtitle, findsOneWidget);
    expect(find.textContaining('01.01.$year'), findsNothing);
    // One line even on a 320 px phone.
    expect(tester.getSize(subtitle).height, lessThan(24));

    // A month keeps its name.
    await tester.ensureVisible(find.text('Monat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monat'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        '${controller.strings.monthNames[controller.today.month - 1]} $year',
      ),
      findsOneWidget,
    );
  });
}
