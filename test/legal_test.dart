import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show databaseFactoryMemory;

import 'package:lighthouse_mini/app/lighthouse_app.dart';
import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/legal/legal_texts.dart';
import 'package:lighthouse_mini/pages/legal_page.dart';
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

Future<void> _openSettings(
  WidgetTester tester,
  String name, {
  String language = 'de',
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(320 * 2, 568 * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.settings_outlined),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapLink(WidgetTester tester, String label) async {
  final link = find.text(label);
  await tester.ensureVisible(link);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadRoboto);

  group('in Settings', () {
    testWidgets('the privacy policy opens and closes again', (tester) async {
      await _openSettings(tester, 'legal-privacy');

      await _tapLink(tester, 'Datenschutzerklärung');
      expect(find.byType(LegalPage), findsOneWidget);
      expect(find.text('Kurz gesagt'), findsOneWidget);
      expect(find.text('1. Verantwortlicher'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LegalPage), findsNothing);
    });

    testWidgets('the legal notice opens', (tester) async {
      await _openSettings(tester, 'legal-notice');

      await _tapLink(tester, 'Impressum');
      expect(find.text('Angaben gemäß § 5 DDG'), findsOneWidget);
    });

    testWidgets('both follow the app language', (tester) async {
      await _openSettings(tester, 'legal-en', language: 'en');

      await _tapLink(tester, 'Privacy policy');
      expect(find.text('In short'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await _tapLink(tester, 'Legal notice');
      expect(find.text('Provider'), findsOneWidget);
    });

    testWidgets('the policy fits a 320 px phone with large text', (
      tester,
    ) async {
      await _openSettings(tester, 'legal-small', textScale: 1.3);

      await _tapLink(tester, 'Datenschutzerklärung');
      // Any overflow while scrolling through fails the test on its own.
      await tester.fling(find.byType(ListView), const Offset(0, -6000), 3000);
      await tester.pumpAndSettle();
      expect(find.text('11. Änderungen'), findsOneWidget);
    });
  });

  group('texts', () {
    test('every section has a title and text, in both languages', () {
      for (final language in ['de', 'en']) {
        for (final document in [
          privacyPolicy(language),
          legalNotice(language),
        ]) {
          expect(document.sections, isNotEmpty);
          for (final section in document.sections) {
            expect(section.title.trim(), isNotEmpty);
            expect(section.paragraphs, isNotEmpty);
          }
        }
      }
    });

    test('the web pages carry the same contact details as the app', () {
      // The stores link to the web pages, the app shows its own copy: fill
      // in the details in lib/legal/legal_texts.dart and in both pages.
      final privacy = File('web/datenschutz.html').readAsStringSync();
      final notice = File('web/impressum.html').readAsStringSync();

      for (final value in [
        LegalContact.name,
        LegalContact.street,
        LegalContact.city,
        LegalContact.email,
      ]) {
        expect(privacy, contains(value), reason: 'datenschutz.html: $value');
        expect(notice, contains(value), reason: 'impressum.html: $value');
      }
      expect(privacy, contains(LegalContact.host));
      expect(privacy, contains(LegalContact.logDays));
    });
  });
}
