import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

LighthouseDatabase _db(String name) =>
    LighthouseDatabase.withFactory(databaseFactoryMemory, name);

Future<LighthouseController> _open(
  LighthouseDatabase database, {
  String device = 'de',
}) async {
  final controller = LighthouseController(
    database,
    deviceLanguage: () => device,
  );
  await controller.initialize();
  return controller;
}

void main() {
  group('language', () {
    test('follows an English phone', () async {
      final c = await _open(_db('lang-en'), device: 'en');
      expect(c.languageCode, 'en');
    });

    test(
      'falls back to German for a language the app does not speak',
      () async {
        final c = await _open(_db('lang-fr'), device: 'fr');
        expect(c.languageCode, 'de');
      },
    );

    test('keeps following the phone until a language is picked', () async {
      final database = _db('lang-follow');
      await _open(database, device: 'de');

      final later = await _open(database, device: 'en');
      expect(later.languageCode, 'en');
    });

    test('a picked language wins over the phone — even the same one', () async {
      final database = _db('lang-picked');
      final first = await _open(database, device: 'en');
      await first.setLanguage('en');

      final phoneNowGerman = await _open(database, device: 'de');
      expect(phoneNowGerman.languageCode, 'en');
    });

    test('"Alles löschen" goes back to following the phone', () async {
      final c = await _open(_db('lang-clear'), device: 'en');
      await c.setLanguage('de');
      await c.clearAllData();
      expect(c.languageCode, 'en');
    });
  });

  group('theme', () {
    test('follows the system on a new install', () async {
      final c = await _open(_db('theme-new'));
      expect(c.themePreference, ThemePreference.system);
    });

    test('old dark-mode switch: on → dark, off → light', () async {
      final on = _db('theme-old-on');
      await on.saveSetting('darkMode', true);
      expect((await _open(on)).themePreference, ThemePreference.dark);

      final off = _db('theme-old-off');
      await off.saveSetting('darkMode', false);
      expect((await _open(off)).themePreference, ThemePreference.light);
    });

    test('a chosen theme is saved and survives a restart', () async {
      final database = _db('theme-save');
      final c = await _open(database);
      await c.setThemePreference(ThemePreference.light);

      expect((await _open(database)).themePreference, ThemePreference.light);
    });

    test('the new setting wins over the old switch', () async {
      final database = _db('theme-both');
      await database.saveSetting('darkMode', true);
      final c = await _open(database);
      await c.setThemePreference(ThemePreference.system);

      expect((await _open(database)).themePreference, ThemePreference.system);
    });
  });
}
