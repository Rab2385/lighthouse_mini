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
  String get saveFailed => _p(
    'Konnte nicht gespeichert werden. Bitte erneut versuchen.',
    "Couldn't save. Please try again.",
  );

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
  String get hintToday => _p('Was war heute gut?', 'What was good today?');
  String get hintPast => _p('Was war gut?', 'What was good?');
  String get hintAhead =>
      _p('Worauf freust du dich?', 'What are you looking forward to?');
  String get addEntry => _p('Eintrag hinzufügen', 'Add entry');
  String get saveWithEnter => _p('Mit Enter speichern', 'Save with Enter');
  String get statusToday => _p('Heute', 'Today');
  String get statusAhead => _p('Ahead', 'Ahead');
  String get statusGood => _p('Good', 'Good');
  String entryCount(int n) => _en
      ? (n == 1 ? '1 entry' : '$n entries')
      : (n == 1 ? '1 Eintrag' : '$n Einträge');
  String aheadEntriesUntil(String date) => _p(
    'Ahead-Einträge sind bis $date möglich.',
    'Ahead entries are possible until $date.',
  );

  // ---- Habits ------------------------------------------------------
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
  String get newHabit => _p('Neuer Habit', 'New habit');
  String get editHabit => _p('Habit bearbeiten', 'Edit habit');
  String get createHabit => _p('Habit anlegen', 'Create habit');
  String get name => _p('Name', 'Name');
  String get habitNameHint => _p('Zum Beispiel Lesen', 'For example Reading');
  String get emoji => 'Emoji';
  String get symbol => _p('Symbol', 'Symbol');
  String get searchSymbol => _p('Symbol suchen …', 'Search symbol …');
  String get noSymbolMatch =>
      _p('Kein passendes Symbol.', 'No matching symbol.');
  String get emojiCatActivity => _p('Bewegung', 'Activity');
  String get emojiCatFood => _p('Essen & Trinken', 'Food & drink');
  String get emojiCatHealth => _p('Gesundheit', 'Health');
  String get emojiCatWork => _p('Arbeit & Ziele', 'Work & goals');
  String get emojiCatMind => _p('Geist & Kreativität', 'Mind & creativity');
  String get emojiCatHome => _p('Zuhause', 'Home');
  String get emojiCatNature => _p('Natur', 'Nature');
  String get archivedHabits => _p('Archivierte Habits', 'Archived habits');
  String get noArchivedHabits =>
      _p('Keine archivierten Habits.', 'No archived habits.');
  String habitArchived(String name) =>
      _p('„$name" archiviert.', '“$name” archived.');
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

  /// "Water, heute" / "Water, Dienstag, 29. September": one habit on one
  /// day, for screen readers and the grid's tooltips.
  String habitDayLabel(String habit, DateTime date, DateTime today) {
    final diff = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
    if (diff == 0) {
      return '$habit, ${_p('heute', 'today')}';
    }
    if (diff == 1) {
      return '$habit, ${_p('gestern', 'yesterday')}';
    }
    final weekday = weekdaysLong[date.weekday - 1];
    final month = monthNames[date.month - 1];
    return _en
        ? '$habit, $weekday, $month ${date.day}'
        : '$habit, $weekday, ${date.day}. $month';
  }

  // ---- Review ------------------------------------------------------
  String get recurringEntries =>
      _p('Wiederkehrende Einträge', 'Recurring entries');
  String get noRecurring => _p(
    'Noch keine wiederkehrenden Texte in diesem Zeitraum.',
    'No recurring texts in this period yet.',
  );
  String get yearCard => _p('Das Jahr', 'The year');
  String get heatLess => _p('weniger', 'less');
  String get heatMore => _p('mehr', 'more');
  String yearCellLabel(String name, DateTime month, int done, int days) {
    final monthName = monthNames[month.month - 1];
    if (days == 0) {
      return _p('$name, $monthName: noch offen', '$name, $monthName: not yet');
    }
    return _p(
      '$name, $monthName: $done von $days Tagen',
      '$name, $monthName: $done of $days days',
    );
  }

  String get rangeThisMonth => _p('Monat', 'Month');
  String rangeLastDays(int n) => _p('$n Tage', '$n days');
  String get pickRange => _p('Zeitraum wählen', 'Choose range');
  String rangeDays(int n) =>
      _en ? (n == 1 ? '$n day' : '$n days') : (n == 1 ? '$n Tag' : '$n Tage');
  String daysElapsedOfRange(int elapsed, int total) =>
      _p('$elapsed von $total Tagen', '$elapsed of $total days');

  // ---- Settings ------------------------------------------------------
  String get settingsSubtitle => _p(
    'Sprache, Aussehen, Name und lokale Daten.',
    'Language, appearance, name and local data.',
  );
  String get language => _p('Sprache', 'Language');
  String get appearance => _p('Aussehen', 'Appearance');
  String get appearanceSubtitle => _p(
    'Folgt dem Hell/Dunkel des Handys – oder immer hell bzw. dunkel.',
    "Follows your phone's light/dark setting – or always light or dark.",
  );
  String get themeSystem => 'System';
  String get themeLight => _p('Hell', 'Light');
  String get themeDark => _p('Dunkel', 'Dark');
  String get yourName => _p('Dein Name', 'Your name');
  String get yourNameSubtitle => _p(
    'Wird für die persönliche Begrüßung auf der Good-Things-Seite genutzt.',
    'Used for the personal greeting on the Good Things page.',
  );
  String get nameHint => _p('Zum Beispiel Robert', 'For example Robert');
  String get nameSaved => _p('Name gespeichert.', 'Name saved.');
  String get privacy => _p('Privatsphäre', 'Privacy');
  String get privacyPolicy => _p('Datenschutzerklärung', 'Privacy policy');
  String get legalNotice => _p('Impressum', 'Legal notice');
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

  // ---- Evening reminder ------------------------------------------
  String get reminderCardTitle => _p('Tägliche Erinnerung', 'Daily reminder');
  String get reminderCardText => _p(
    'Eine ruhige Nachricht am Abend – nur, wenn du heute noch nichts '
        'eingetragen hast.',
    "One calm message in the evening – only if you haven't written anything "
        'today.',
  );
  String get reminderUnsupported => _p(
    'Erinnerungen gibt es in der App für Android und iOS.',
    'Reminders are available in the Android and iOS app.',
  );
  String get reminderPermissionDenied => _p(
    'Benachrichtigungen sind für Lighthouse ausgeschaltet. Du kannst sie in '
        'den Systemeinstellungen erlauben.',
    'Notifications are turned off for Lighthouse. You can allow them in the '
        'system settings.',
  );
  String reminderAt(String time) => _p('Um $time', 'At $time');
  String get reminderTitle => _p('Was war heute gut?', 'What was good today?');
  String get reminderBody => _p('Ein Satz reicht.', 'One sentence is enough.');
  String get reminderChannel => _p('Abend-Erinnerung', 'Evening reminder');

  // ---- Memories ----------------------------------------------------
  String get memoryYearAgo => _p('Heute vor einem Jahr', 'A year ago today');
  String get memoryMonthAgo => _p('Heute vor einem Monat', 'A month ago today');
  String get showMemoriesTitle =>
      _p('Erinnerungen an frühere Einträge', 'Memories from earlier entries');
  String get showMemoriesSubtitle => _p(
    'Zeigt oben einen Eintrag von heute vor einem Jahr oder Monat.',
    'Shows an entry from a year or a month ago today at the top.',
  );
  String get helpersTitle => _p('Kleine Helfer', 'Little helpers');
  String get quickEntryTitle =>
      _p('Beim Öffnen direkt schreiben', 'Start typing when opening');
  String get quickEntrySubtitle => _p(
    'Auf dem Handy ist das Feld für heute gleich bereit – solange heute '
        'noch nichts eingetragen ist.',
    "On a phone, today's field is ready right away – as long as nothing is "
        'written for today yet.',
  );
  String get shortcutAdd => _p('Good Thing eintragen', 'Add a Good Thing');
  String get shortcutHabits => _p('Habits von heute', "Today's habits");

  // ---- Review: Good Things ------------------------------------------
  String get copyAsText => _p('Als Text kopieren', 'Copy as text');
  String get copied => _p('Kopiert.', 'Copied.');
  String get noGoodThingsInRange => _p(
    'Noch keine Good Things in diesem Zeitraum.',
    'No Good Things in this period yet.',
  );
  String showAll(int n) => _p('Alle $n anzeigen', 'Show all $n');
  String get showLess => _p('Weniger anzeigen', 'Show less');

  // ---- Backup ------------------------------------------------------
  String get backup => 'Backup';
  String get backupText => _p(
    'Deine Einträge liegen nur auf diesem Gerät. Sichere sie ab und zu als '
        'Datei – z. B. in deiner Cloud oder per Mail an dich selbst.',
    'Your entries live only on this device. Save them as a file now and '
        'then – for example to your cloud or by mail to yourself.',
  );
  String get backupTextWeb => _p(
    'Im Browser können Daten verloren gehen, wenn Websitedaten gelöscht '
        'werden oder der Speicher knapp wird.',
    'In a browser, data can be lost when site data is cleared or storage '
        'runs low.',
  );
  String get backupSave => _p('Backup speichern', 'Save backup');
  String get backupRestore => _p('Wiederherstellen', 'Restore');
  String lastBackup(String date) =>
      _p('Letztes Backup: $date', 'Last backup: $date');
  String get noBackupYet =>
      _p('Noch kein Backup gespeichert.', 'No backup saved yet.');
  String backupCounts(int goodThings, int habits) =>
      '$goodThings Good Things · $habits Habits';
  String get backupSaved => _p('Backup gespeichert.', 'Backup saved.');
  String get backupRestoreQ =>
      _p('Backup wiederherstellen?', 'Restore backup?');
  String backupRestoreText(String date, String counts, String current) => _p(
    'Backup vom $date · $counts.\n\n'
        'Deine aktuellen Daten ($current) werden ersetzt. Der aktuelle Stand '
        'wird vorher gesichert und lässt sich zurückholen.',
    'Backup from $date · $counts.\n\n'
        'Your current data ($current) will be replaced. It is kept as a '
        'safety copy first, so you can bring it back.',
  );
  String get backupRestored =>
      _p('Backup wiederhergestellt.', 'Backup restored.');
  String get backupUndoRestore =>
      _p('Vorherigen Stand zurückholen', 'Bring back previous data');
  String get backupUndone =>
      _p('Vorheriger Stand wiederhergestellt.', 'Previous data brought back.');
  String get backupNotLighthouse => _p(
    'Diese Datei ist kein Lighthouse-Backup.',
    'This file is not a Lighthouse backup.',
  );
  String get backupTooNew => _p(
    'Dieses Backup stammt aus einer neueren App-Version. Bitte aktualisiere '
        'Lighthouse.',
    'This backup was made by a newer version. Please update Lighthouse.',
  );
  String get backupDamaged => _p(
    'Das Backup ist beschädigt und wurde nicht geladen. Deine Daten sind '
        'unverändert.',
    'The backup is damaged and was not loaded. Your data is unchanged.',
  );
  String get backupFailed => _p(
    'Das hat nicht geklappt. Deine Daten sind unverändert.',
    "That didn't work. Your data is unchanged.",
  );
  String backupReminder(int days) =>
      _p('Letztes Backup vor $days Tagen', 'Last backup $days days ago');
  String get backupReminderNever => _p(
    'Deine Einträge sind noch nicht gesichert',
    'Your entries have no backup yet',
  );
  String get backupNow => _p('Jetzt sichern', 'Back up now');
  String get dismiss => _p('Ausblenden', 'Dismiss');

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

  /// "Di., 29.09." / "Tue, 09/29" — a day without its year.
  String dayLabel(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    final weekday = weekdaysShort[date.weekday - 1];
    return _en
        ? '$weekday, ${two(date.month)}/${two(date.day)}'
        : '$weekday., ${two(date.day)}.${two(date.month)}.';
  }

  String formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return _en
        ? '${two(date.month)}/${two(date.day)}/${date.year}'
        : '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  String monthAndYear(DateTime date) =>
      '${monthNames[date.month - 1]} ${date.year}';

  /// "Sep. 2026" / "Sep 2026" — for very narrow phone headers.
  String shortMonthAndYear(DateTime date) {
    final name = monthNames[date.month - 1];
    final short = name.length <= 4
        ? name
        : '${name.substring(0, 3)}${_en ? '' : '.'}';
    return '$short ${date.year}';
  }
}
