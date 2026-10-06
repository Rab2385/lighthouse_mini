import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards for things the stores check on upload, which no other test sees.
void main() {
  group('iOS privacy manifest', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    test('exists and declares no tracking and no collected data', () {
      final text = manifest.readAsStringSync();
      expect(text, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
      expect(
        text,
        contains('<key>NSPrivacyCollectedDataTypes</key>\n\t<array/>'),
      );
      expect(text, contains('NSPrivacyAccessedAPICategoryFileTimestamp'));
    });

    test('is copied into the app bundle', () {
      // Without the Resources entry Xcode never ships the file.
      expect(
        RegExp(
          r'/\* PrivacyInfo\.xcprivacy in Resources \*/,',
        ).allMatches(project),
        hasLength(1),
      );
    });
  });

  test('iOS bundle name is "Lighthouse"', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      contains('<key>CFBundleName</key>\n\t<string>Lighthouse</string>'),
    );
  });

  test('privacy policy and imprint ship with the web app', () {
    for (final page in ['web/datenschutz.html', 'web/impressum.html']) {
      final html = File(page).readAsStringSync();
      expect(html, contains('<html lang="de">'), reason: page);
      // Self-contained: no fonts or scripts from other servers.
      expect(html, isNot(contains('<script')), reason: page);
      expect(html, isNot(contains('fonts.googleapis')), reason: page);
    }
  });
}
