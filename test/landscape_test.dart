import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';
import 'package:lighthouse_mini/widgets/month_header.dart';

Future<void> _pump(WidgetTester tester, Size size, String name) async {
  tester.view.physicalSize = size * 2;
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
}

/// Measure with the real font: the default test font draws every glyph as
/// a full-width block, which would make every label far wider than it is.
Future<void> _loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final weight in [400, 500, 600, 700]) {
    final bytes = File('assets/fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);

  for (final size in const [Size(667, 375), Size(844, 390)]) {
    group('phone landscape ${size.width.toInt()}×${size.height.toInt()}', () {
      testWidgets('uses the rail, not the bottom bar', (tester) async {
        await _pump(tester, size, 'land-rail-${size.width}');

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });

      testWidgets('keeps the header to one line', (tester) async {
        await _pump(tester, size, 'land-header-${size.width}');

        final header = find.byType(MonthHeader).first;
        expect(tester.getSize(header).height, lessThanOrEqualTo(60));
      });

      testWidgets('shows at least 4 habit rows in the month grid', (
        tester,
      ) async {
        await _pump(tester, size, 'land-habits-${size.width}');

        await tester.tap(find.byIcon(Icons.grid_view_outlined));
        await tester.pumpAndSettle();

        // Default habits, fully on screen.
        final visible = ['Work', 'Coffee', 'Water', 'Coding', 'Sport'].where((
          name,
        ) {
          final finder = find.text(name);
          if (finder.evaluate().isEmpty) return false;
          final rect = tester.getRect(finder.first);
          return rect.bottom <= size.height;
        });
        expect(visible.length, greaterThanOrEqualTo(4));
      });
    });
  }

  testWidgets('portrait phone keeps the bottom bar', (tester) async {
    await _pump(tester, const Size(375, 667), 'portrait-bar');

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
