/// Privacy policy and legal notice, shown in Settings.
///
/// The same texts are published on the web as `web/datenschutz.html` and
/// `web/impressum.html` (the stores need a public URL). When the contact
/// details below change, change them there too — a test keeps both in step.
library;

/// Who is responsible for the app. Placeholders in square brackets are
/// shown highlighted until they're filled in.
///
/// There is no hosting section: the app runs entirely on the user's device.
/// Once the web app or these pages are published somewhere, that host
/// processes IP addresses and logs and needs its own short section.
abstract final class LegalContact {
  static const String name = 'Robert Braun';
  static const String street = '[Straße Hausnummer]';
  static const String city = '[PLZ Ort]';
  static const String email = '[kontakt@beispiel.de]';
}

/// "Oktober 2026" / "October 2026": when the texts last changed.
const String legalLastUpdatedDe = 'Oktober 2026';
const String legalLastUpdatedEn = 'October 2026';

class LegalSection {
  const LegalSection(this.title, this.paragraphs, {this.bullets = const []});

  final String title;
  final List<String> paragraphs;

  /// Shown as a list after the first paragraph.
  final List<String> bullets;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.sections,
    this.summaryTitle,
    this.summary = const [],
  });

  final String title;
  final String lastUpdated;

  /// The "In short" box at the top, if any.
  final String? summaryTitle;
  final List<String> summary;
  final List<LegalSection> sections;
}

LegalDocument privacyPolicy(String languageCode) =>
    languageCode == 'en' ? _privacyEn : _privacyDe;

LegalDocument legalNotice(String languageCode) =>
    languageCode == 'en' ? _noticeEn : _noticeDe;

const _address =
    '${LegalContact.name}\n${LegalContact.street}\n${LegalContact.city}';

const _privacyDe = LegalDocument(
  title: 'Datenschutzerklärung',
  lastUpdated: 'Für die App „Lighthouse“ · Stand: $legalLastUpdatedDe',
  summaryTitle: 'Kurz gesagt',
  summary: [
    'Lighthouse funktioniert ohne Konto. Deine Einträge, Gewohnheiten und '
        'Einstellungen bleiben auf deinem Gerät.',
    'Wir betreiben keinen Server, der deine Einträge empfängt, speichert '
        'oder auswertet.',
    'Keine Werbung, kein Tracking, keine Analyse-Werkzeuge.',
  ],
  sections: [
    LegalSection('1. Verantwortlicher', [
      '$_address, Deutschland\nE-Mail: ${LegalContact.email}',
    ]),
    LegalSection(
      '2. Welche Daten die App verarbeitet – und wo',
      [
        'Damit Lighthouse funktioniert, speichert die App folgende Inhalte, '
            'die du selbst eingibst:',
        'Diese Daten werden ausschließlich lokal auf deinem Gerät '
            'gespeichert: in der App auf dem Speicher deines iPhones bzw. '
            'Android-Geräts, in der Web-App im Speicher deines Browsers '
            '(IndexedDB). Sie werden nicht an uns oder an Dritte übertragen. '
            'Wir haben keinen Zugriff darauf.',
        'Rechtsgrundlage ist, soweit überhaupt eine Verarbeitung durch uns '
            'vorliegt, Art. 6 Abs. 1 lit. b DSGVO. Das Speichern im Browser ist '
            'für die von dir gewünschte Funktion unbedingt erforderlich '
            '(§ 25 Abs. 2 Nr. 2 TDDDG). Cookies verwendet Lighthouse nicht.',
      ],
      bullets: [
        'deine „Good Things“ (kurze Texte mit Datum),',
        'deine Gewohnheiten und an welchen Tagen du sie abgehakt hast,',
        'Einstellungen, z. B. Sprache, Erscheinungsbild, Uhrzeit der '
            'Erinnerung und – falls du ihn einträgst – deinen Vornamen für die '
            'Begrüßung.',
      ],
    ),
    LegalSection('3. Backup-Dateien', [
      'Unter „Einstellungen → Backup“ kannst du alle Daten als eine Datei '
          'sichern. Den Speicherort wählst du selbst (z. B. „Dateien“, ein '
          'USB-Stick oder ein Cloud-Speicher deiner Wahl). Legst du die Datei '
          'bei einem Cloud-Anbieter ab, gelten dessen Datenschutzbestimmungen. '
          'Lighthouse selbst überträgt die Datei nirgendwohin.',
    ]),
    LegalSection('4. Erinnerungen und Berechtigungen', [
      'Wenn du die abendliche Erinnerung einschaltest, fragt die App nach der '
          'Berechtigung für Mitteilungen. Die Erinnerung wird lokal auf deinem '
          'Gerät geplant – es gibt keinen Push-Server. Auf Android darf die App '
          'dafür außerdem vibrieren und die geplante Erinnerung nach einem '
          'Neustart des Geräts wiederherstellen. Weitere Berechtigungen '
          '(Kontakte, Standort, Kamera, Mikrofon o. Ä.) nutzt Lighthouse nicht.',
    ]),
    LegalSection('5. Keine Analyse, keine Werbung, kein Tracking', [
      'Lighthouse enthält keine Analyse- oder Werbe-SDKs und keine '
          'Absturzberichte, die Daten an uns senden. Es findet kein Tracking im '
          'Sinne von Apples „App Tracking Transparency“ statt.',
    ]),
    LegalSection('6. App Store, Google Play und TestFlight', [
      'Wenn du Lighthouse über den App Store (inkl. TestFlight) oder Google '
          'Play lädst, verarbeiten Apple bzw. Google dabei Daten in eigener '
          'Verantwortung (z. B. Kauf- und Download-Informationen). Teilst du '
          'über dein Gerät Absturz- oder Nutzungsdaten mit Entwicklern, stellen '
          'Apple bzw. Google uns diese nur in zusammengefasster Form bereit. '
          'Näheres findest du in den Datenschutzhinweisen von Apple und Google.',
    ]),
    LegalSection('7. Kontakt per E-Mail', [
      'Wenn du uns schreibst, verwenden wir deine E-Mail-Adresse und deine '
          'Nachricht nur, um dein Anliegen zu beantworten (Art. 6 Abs. 1 lit. b '
          'bzw. f DSGVO), und löschen sie, sobald sie dafür nicht mehr nötig '
          'sind.',
    ]),
    LegalSection('8. Deine Daten löschen', [
      'Da alles auf deinem Gerät liegt, hast du die volle Kontrolle: Löschen '
          'in der App („Einstellungen → Alle lokalen Daten löschen“), App '
          'deinstallieren bzw. in der Web-App die Website-Daten im Browser '
          'löschen entfernt alle Einträge endgültig. Von dir gespeicherte '
          'Backup-Dateien löschst du selbst.',
    ]),
    LegalSection('9. Deine Rechte', [
      'Du hast das Recht auf Auskunft (Art. 15 DSGVO), Berichtigung (Art. 16), '
          'Löschung (Art. 17), Einschränkung der Verarbeitung (Art. 18), '
          'Datenübertragbarkeit (Art. 20) und Widerspruch (Art. 21). Wende dich '
          'dafür an die oben genannte Adresse. Außerdem kannst du dich bei einer '
          'Datenschutz-Aufsichtsbehörde beschweren, z. B. bei der Behörde '
          'deines Wohnorts. Bitte beachte: Deine Einträge liegen nicht bei uns '
          '– wir können dazu also keine Auskunft geben oder sie löschen.',
    ]),
    LegalSection('10. Änderungen', [
      'Wenn sich die App so ändert, dass Daten anders verarbeitet werden, '
          'passen wir diese Erklärung vorher an. Das Datum oben zeigt den '
          'aktuellen Stand.',
    ]),
  ],
);

const _privacyEn = LegalDocument(
  title: 'Privacy policy',
  lastUpdated: 'For the “Lighthouse” app · Last updated: $legalLastUpdatedEn',
  summaryTitle: 'In short',
  summary: [
    'Lighthouse works without an account. Your entries, habits and settings '
        'stay on your device.',
    'We run no server that receives, stores or analyses your entries.',
    'No ads, no tracking, no analytics.',
  ],
  sections: [
    LegalSection('Controller', [
      '$_address, Germany\nEmail: ${LegalContact.email}',
    ]),
    LegalSection('What the app stores', [
      'Your Good Things (short dated texts), your habits and the days you '
          'ticked them, and settings such as language, appearance, reminder '
          'time and, if you enter it, your first name for the greeting. All of '
          'this is stored only on your device (app storage, or IndexedDB in '
          'your browser for the web app). It is never sent to us or anyone '
          'else. No cookies are used.',
    ]),
    LegalSection('Backups', [
      'You can save all data as one file and choose where to keep it. If you '
          'store it with a cloud provider, their privacy terms apply.',
    ]),
    LegalSection('Reminders and permissions', [
      'The optional evening reminder asks for permission to send '
          'notifications. It is scheduled locally on your device; there is no '
          'push server. On Android the app may also vibrate and restore the '
          'scheduled reminder after a restart. No other permissions are used.',
    ]),
    LegalSection('No analytics, ads or tracking', [
      'Lighthouse contains no analytics, advertising or crash-reporting SDKs '
          'and does not track you.',
    ]),
    LegalSection('App stores', [
      'Apple (App Store, TestFlight) and Google (Google Play) process data '
          'about downloads under their own responsibility; see their privacy '
          'policies.',
    ]),
    LegalSection('Deleting your data and your rights', [
      'Deleting your data in the app (Settings → Delete all local data), '
          'uninstalling it, or clearing the site data in your browser removes '
          'everything permanently. You have the rights of access, '
          'rectification, erasure, restriction, portability and objection '
          'under the GDPR, and may lodge a complaint with a supervisory '
          'authority. Your entries are not stored with us, so we cannot access '
          'or delete them.',
    ]),
  ],
);

const _noticeDe = LegalDocument(
  title: 'Impressum',
  lastUpdated: 'Angaben für die App „Lighthouse“',
  sections: [
    LegalSection('Angaben gemäß § 5 DDG', ['$_address\nDeutschland']),
    LegalSection('Kontakt', ['E-Mail: ${LegalContact.email}']),
    LegalSection('Verantwortlich für den Inhalt', [
      '${LegalContact.name}, Anschrift wie oben',
    ]),
  ],
);

const _noticeEn = LegalDocument(
  title: 'Legal notice',
  lastUpdated: 'For the “Lighthouse” app',
  sections: [
    LegalSection('Provider', ['$_address\nGermany']),
    LegalSection('Contact', ['Email: ${LegalContact.email}']),
  ],
);
