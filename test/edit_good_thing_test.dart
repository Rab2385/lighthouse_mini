import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

void main() {
  testWidgets(
    'editing a Good Thing and saving does not throw the _dependents assertion',
    (tester) async {
      final database = LighthouseDatabase.withFactory(
        databaseFactoryMemory,
        'edit_test.db',
      );
      final controller = LighthouseController(database);
      await controller.initialize();
      await controller.addGoodThing(
        date: controller.today,
        text: 'Original entry',
      );

      await tester.pumpWidget(LighthouseApp(controller: controller));
      await tester.pumpAndSettle();

      // Open the edit dialog from the saved entry line.
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      // Change the text and save.
      await tester.enterText(find.byType(TextField).last, 'Edited entry');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Edited entry'), findsOneWidget);
    },
  );
}
