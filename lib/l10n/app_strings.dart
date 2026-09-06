import 'package:flutter/widgets.dart';

/// All user-facing strings, in German and English.
///
/// One method per string, both translations inline, so adding a language later
/// only means widening [_p] and the name lists.
class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  static const List<String> supportedCodes = ['de', 'en'];

  bool get _en => languageCode == 'en';
  String _p(String de, String en) => _en ? en : de;

  Locale get locale => Locale(languageCode);

  String get languageName => _p('Deutsch', 'English');

  // ---- App / navigation ------------------------------------------------------
  String get goodThings => 'Good Things';
  String get habits => 'Habits';
  String get review => 'Review';
  String get settings => _p('Einstellungen', 'Settings');
  String get navGood => _p('Good', 'Good');

  // ---- Shared actions ------------------------------------------------------
  String get cancel => _p('Abbrechen', 'Cancel');
  String get save => _p('Speichern', 'Save');
  String get close => _p('Schließen', 'Close');
  String get edit => _p('Bearbeiten', 'Edit');
  String get delete => _p('Löschen', 'Delete');
  String get archive => _p('Archivieren', 'Archive');
  String get restore => _p('Wiederherstellen', 'Restore');
  String get today => _p('Heute', 'Today');
  String get yesterday => _p('Gestern', 'Yesterday');
  String get undo => _p('Rückgängig', 'Undo');

  // ---- Month header ------------------------------------------------------
  String get previousMonth => _p('Vorheriger Monat', 'Previous month');
  String get nextMonth => _p('Nächster Monat', 'Next month');

  // ---- Good Things ------------------------------------------------------
  String get goodThingsGreetingHint => _p(
    'Schnell eintragen. Mit Enter speichern.',
    'Jot it down. Press Enter to save.',
  );
  String get searchGoodThings =>
      _p('Good Things durchsuchen …', 'Search Good Things …');
  String get clearSearch => _p('Suche löschen', 'Clear search');
  String noEntriesFound(String query) => _p(
    'Keine Einträge für „$query" gefunden.',
    'No entries found for “$query”.',
  );
  String get editEntry => _p('Eintrag bearbeiten', 'Edit entry');
  String get goodThingLabel => 'Good Thing';
  String get entryDeleted => _p('Eintrag gelöscht.', 'Entry deleted.');
  String get writeSomethingGood =>
      _p('Etwas Gutes aufschreiben …', 'Write something good …');
  String get saveWithEnter => _p('Mit Enter speichern', 'Save with Enter');
  String get statusToday => _p('Heute', 'Today');
  String get statusAhead => _p('Ahead', 'Ahead');
  String get statusGood => _p('Good', 'Good');
  String aheadEntriesUntil(String date) => _p(
    'Ahead-Einträge sind bis $date möglich.',
    'Ahead entries are possible until $date.',
  );

  // ---- Habits ------------------------------------------------------
  String get habitTracker => _p('Habit Tracker', 'Habit Tracker');
  String get habitsCompactHint => _p(
    'Gestern und heute – ein Tippen genügt.',
    'Yesterday and today – one tap.',
  );
  String get habitsMonthHint =>
      _p('Der ganze Monat zum Nachtragen.', 'The whole month for catching up.');
  String get habitsRotateHint => _p(
    'Quer halten zeigt den ganzen Monat.',
    'Turn sideways for the whole month.',
  );
  String get compact => _p('Kompakt', 'Compact');
  String get month => _p('Monat', 'Month');
  String get archiveButton => _p('Archiv', 'Archive');
  String get habitButton => 'Habit';
  String get noActiveHabits =>
      _p('Noch keine aktiven Habits.', 'No active habits yet.');
  String get addHabit => _p('Habit hinzufügen', 'Add habit');
  String get editHabit => _p('Habit bearbeiten', 'Edit habit');
  String get name => _p('Name', 'Name');
  String get habitNameHint => _p('Zum Beispiel Reading', 'For example Reading');
  String get emoji => 'Emoji';
  String get description => _p('Beschreibung', 'Description');
  String get habitDescriptionHint =>
      _p('Was bedeutet die Markierung?', 'What does the mark mean?');
  String get archivedHabits => _p('Archivierte Habits', 'Archived habits');
  String get noArchivedHabits =>
      _p('Keine archivierten Habits.', 'No archived habits.');
  String get deleteForever => _p('Endgültig löschen', 'Delete permanently');
  String get deleteForeverQ => _p('Endgültig löschen?', 'Delete permanently?');
  String deleteHabitMarkings(String name) => _p(
    'Alle Markierungen von "$name" werden gelöscht.',
    'All marks for "$name" will be deleted.',
  );
  String get manageHabit => _p('Habit verwalten', 'Manage habit');
  String get habitColumn => 'Habit';
  String get totalColumn => _p('Gesamt', 'Total');
  String nThisMonth(int n) => _p('$n diesen Monat', '$n this month');
  String get futureDaysLocked =>
      _p('Zukünftige Tage sind gesperrt.', 'Future days are locked.');
  String get removeMark => _p('Markierung entfernen', 'Remove mark');
  String get markDay => _p('Tag markieren', 'Mark day');

  // ---- Review ------------------------------------------------------
  String get reviewGood => 'Good Things';
  String get daysWithEntries => _p('Tage mit Einträgen', 'Days with entries');
  String get ahead => 'Ahead';
  String get activeHabits => _p('Aktive Habits', 'Active habits');
  String get recurringEntries =>
      _p('Wiederkehrende Einträge', 'Recurring entries');
  String get noRecurring => _p(
    'Noch keine wiederkehrenden Texte in diesem Zeitraum.',
    'No recurring texts in this period yet.',
  );
  String get thisMonth => _p('Dieser Monat', 'This month');
  String get last7Days => _p('Letzte 7 Tage', 'Last 7 days');
  String get last30Days => _p('Letzte 30 Tage', 'Last 30 days');
  String get thisYear => _p('Dieses Jahr', 'This year');
  String get pickRange => _p('Zeitraum wählen', 'Choose range');
  String pickedRange(String label) => _p('Zeitraum: $label', 'Range: $label');
  String rangeDays(int n) =>
      _en ? (n == 1 ? '$n day' : '$n days') : (n == 1 ? '$n Tag' : '$n Tage');

  // ---- Settings ------------------------------------------------------
  String get settingsSubtitle => _p(
    'Sprache, Aussehen, Name und lokale Daten.',
    'Language, appearance, name and local data.',
  );
  String get language => _p('Sprache', 'Language');
  String get darkMode => 'Dark Mode';
  String get darkModeSubtitle =>
      _p('Ruhiges dunkles Petrol-Design.', 'Calm dark petrol design.');
  String get yourName => _p('Dein Name', 'Your name');
  String get yourNameSubtitle => _p(
    'Wird für die persönliche Begrüßung auf der Good-Things-Seite genutzt.',
    'Used for the personal greeting on the Good Things page.',
  );
  String get nameHint => _p('Zum Beispiel Robert', 'For example Robert');
  String get nameSaved => _p('Name gespeichert.', 'Name saved.');
  String get privacy => _p('Privatsphäre', 'Privacy');
  String get privacyText => _p(
    'Alle Einträge werden derzeit nur lokal auf diesem Gerät '
        'gespeichert. Es werden keine Journaltexte an einen Server '
        'übertragen.',
    'All entries are currently stored only locally on this device. '
        'No journal text is sent to a server.',
  );
  String get dangerZone => _p('Gefahrenzone', 'Danger zone');
  String get dangerZoneText => _p(
    'Löscht alle lokalen Daten dieser Lighthouse-Installation.',
    'Deletes all local data of this Lighthouse installation.',
  );
  String get clearAllData =>
      _p('Alle lokalen Daten löschen', 'Delete all local data');
  String get clearAllDataQ =>
      _p('Alle lokalen Daten löschen?', 'Delete all local data?');
  String get clearAllDataText => _p(
    'Good Things, Habit-Markierungen, eigene Habits und Einstellungen '
        'werden dauerhaft gelöscht. Dieser Schritt kann nicht rückgängig '
        'gemacht werden.',
    'Good Things, habit marks, your habits and settings will be deleted '
        'permanently. This step cannot be undone.',
  );
  String get deleteEverything => _p('Alles löschen', 'Delete everything');
  String get localDataDeleted =>
      _p('Lokale Daten wurden gelöscht.', 'Local data was deleted.');

  // ---- Greeting ------------------------------------------------------
  String get greetingMorning => _p('Guten Morgen', 'Good morning');
  String get greetingDay => _p('Guten Tag', 'Hello');
  String get greetingEvening => _p('Guten Abend', 'Good evening');
  String get greetingNight => _p('Gute Nacht', 'Good night');

  // ---- Names ------------------------------------------------------
  List<String> get monthNames => _en
      ? const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ]
      : const [
          'Januar',
          'Februar',
          'März',
          'April',
          'Mai',
          'Juni',
          'Juli',
          'August',
          'September',
          'Oktober',
          'November',
          'Dezember',
        ];

  List<String> get weekdaysLong => _en
      ? const [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ]
      : const [
          'Montag',
          'Dienstag',
          'Mittwoch',
          'Donnerstag',
          'Freitag',
          'Samstag',
          'Sonntag',
        ];

  List<String> get weekdaysShort => _en
      ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  String formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return _en
        ? '${two(date.month)}/${two(date.day)}/${date.year}'
        : '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  String monthAndYear(DateTime date) =>
      '${monthNames[date.month - 1]} ${date.year}';
}
