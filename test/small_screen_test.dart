import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

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

Future<void> _pump320(
  WidgetTester tester,
  String name,
  double textScale,
) async {
  tester.view.physicalSize = const Size(320 * 2, 568 * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
}

Future<void> _openTab(WidgetTester tester, IconData icon) async {
  // The same icons also appear on some pages; tap the one in the bar.
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

  // Any overflow while laying out a tab fails the test on its own.
  for (final scale in const [1.0, 1.3]) {
    testWidgets('all tabs lay out without overflow at 320 px, text ×$scale', (
      tester,
    ) async {
      await _pump320(tester, 'small-tabs-$scale', scale);

      await _openTab(tester, Icons.grid_view_outlined);
      await _openTab(tester, Icons.insights_outlined);
      await _openTab(tester, Icons.settings_outlined);
      await _openTab(tester, Icons.auto_awesome_outlined);
    });
  }

  testWidgets('"Einstellungen" fits in the bottom bar', (tester) async {
    await _pump320(tester, 'small-nav', 1.0);

    final label = tester.getRect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Einstellungen'),
      ),
    );
    // Each of the 4 slots is 80 px. Browsers draw text a pixel or two wider
    // than tests do, so demand a little slack rather than an exact fit.
    expect(label.width, lessThanOrEqualTo(76));
  });

  testWidgets('habit names stay on one line', (tester) async {
    await _pump320(tester, 'small-habits', 1.0);
    await _openTab(tester, Icons.grid_view_outlined);

    // The room left for the name next to the two day toggles.
    final nameArea = find
        .ancestor(of: find.text('Coffee'), matching: find.byType(Expanded))
        .first;
    expect(tester.getSize(nameArea).width, greaterThanOrEqualTo(90));
    expect(tester.getSize(find.text('Coffee')).height, lessThan(24));
  });

  testWidgets('Review keeps a usable progress bar', (tester) async {
    await _pump320(tester, 'small-review', 1.0);
    await _openTab(tester, Icons.insights_outlined);

    final bar = tester.getSize(find.byType(LinearProgressIndicator).first);
    expect(bar.width, greaterThan(40));
  });

  testWidgets('Settings cards are all full width', (tester) async {
    await _pump320(tester, 'small-settings', 1.0);
    await _openTab(tester, Icons.settings_outlined);

    await tester.drag(find.text('Backup'), const Offset(0, -500));
    await tester.pumpAndSettle();
    final language = find.ancestor(
      of: find.text('Sprache'),
      matching: find.byType(Card),
    );
    final backup = find.ancestor(
      of: find.text('Backup'),
      matching: find.byType(Card),
    );
    expect(tester.getSize(language).width, tester.getSize(backup).width);
  });
}
