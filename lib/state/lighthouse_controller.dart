import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/widgets.dart' show Locale;

import '../data/backup.dart';
import '../data/lighthouse_database.dart';
import '../l10n/app_strings.dart';
import '../models/good_thing.dart';
import '../models/habit.dart';
import '../services/reminder_scheduler.dart';
import '../util/greeting.dart';
import '../util/reminder_plan.dart';

class LighthouseController extends ChangeNotifier {
  LighthouseController(
    this._database, {
    this._reminders = const NoReminderScheduler(),
    this._deviceLanguage = _platformLanguage,
  });

  final ReminderScheduler _reminders;

  /// The phone's language code, e.g. 'en'. Injectable for tests.
  final String Function() _deviceLanguage;

  static String _platformLanguage() =>
      PlatformDispatcher.instance.locale.languageCode;

  static const String _themeModeKey = 'themeMode';

  static const String _reminderEnabledKey = 'reminderEnabled';
  static const String _reminderMinutesKey = 'reminderMinutes';

  /// 20:30 — after the day, before bed.
  static const int defaultReminderMinutes = 20 * 60 + 30;

  /// Settings key marking that the starter habits were created once, so an
  /// intentionally empty habit list stays empty on the next launch.
  static const String _defaultHabitsSeededKey = 'defaultHabitsSeeded';

  static const String _quickEntryOnOpenKey = 'quickEntryOnOpen';
  static const String _showMemoriesKey = 'showMemories';
  static const String _memoryDismissedOnKey = 'memoryDismissedOn';

  static const String _lastBackupAtKey = 'lastBackupAt';
  static const String _backupReminderDismissedAtKey =
      'backupReminderDismissedAt';

  /// Settings that describe this device's backup history rather than the
  /// user's data, so they are not written into backup files.
  static const Set<String> _deviceOnlySettings = {
    _lastBackupAtKey,
    _backupReminderDismissedAtKey,
    _memoryDismissedOnKey,
  };

  final LighthouseDatabase _database;

  final StreamController<Object> _saveErrors =
      StreamController<Object>.broadcast();

  final StreamController<AppAction> _actions =
      StreamController<AppAction>.broadcast();

  /// Requests to jump somewhere — from a home-screen shortcut or from
  /// opening the app — for the shell and the pages to act on.
  Stream<AppAction> get actions => _actions.stream;

  /// Emits whenever a change could not be written to local storage. The
  /// in-memory change has already been rolled back by then.
  Stream<Object> get saveErrors => _saveErrors.stream;

  final List<GoodThing> _goodThings = [];
  final List<Habit> _habits = [];
  final Set<String> _completedHabitKeys = {};

  ThemePreference _themePreference = ThemePreference.system;
  String _userName = '';
  bool _habitCompactView = true;
  String _languageCode = 'de';

  /// False while the language simply follows the phone.
  bool _languageChosen = false;
  int _idCounter = 0;
  DateTime? _lastBackupAt;
  DateTime? _backupReminderDismissedAt;
  bool _hasSafetyBackup = false;
  bool _showMemories = true;
  bool _quickEntryOnOpen = true;
  bool _reminderEnabled = false;
  int _reminderMinutes = defaultReminderMinutes;
  String? _memoryDismissedOn;

  /// System (follow the phone), always light or always dark.
  ThemePreference get themePreference => _themePreference;
  String get userName => _userName;
  String get languageCode => _languageCode;

  /// The active translation table.
  AppStrings get strings => AppStrings(_languageCode);

  /// Locale for `MaterialApp`, so the Material date pickers etc. match.
  Locale get appLocale => Locale(_languageCode);

  /// Whether the habit tracker shows the compact "Gestern / Heute" list
  /// (true) or the full month grid (false).
  bool get habitCompactView => _habitCompactView;

  /// A greeting for the current time of day, personalised with [userName]
  /// when one has been set in the settings.
  String get greeting => greetingForTime(DateTime.now(), _userName, strings);

  List<GoodThing> get goodThings {
    return List<GoodThing>.unmodifiable(_goodThings);
  }

  List<Habit> get habits {
    final result = List<Habit>.from(_habits)
      ..sort((first, second) {
        final sortComparison = first.sortOrder.compareTo(second.sortOrder);

        if (sortComparison != 0) {
          return sortComparison;
        }

        return first.createdAt.compareTo(second.createdAt);
      });

    return List<Habit>.unmodifiable(result);
  }

  List<Habit> get activeHabits {
    return habits.where((habit) => !habit.isArchived).toList();
  }

  List<Habit> get archivedHabits {
    return habits.where((habit) => habit.isArchived).toList();
  }

  DateTime get today => _dateOnly(DateTime.now());

  DateTime get maximumFutureDate {
    final current = today;
    final nextMonth = current.month == 12 ? 1 : current.month + 1;
    final nextYear = current.month == 12 ? current.year + 1 : current.year;

    final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;

    return DateTime(
      nextYear,
      nextMonth,
      math.min(current.day, lastDayOfNextMonth),
    );
  }

  DateTime get maximumFutureMonth {
    final maximum = maximumFutureDate;
    return DateTime(maximum.year, maximum.month);
  }

  Future<void> initialize() async {
    _goodThings
      ..clear()
      ..addAll(await _database.loadGoodThings());

    _habits
      ..clear()
      ..addAll(await _database.loadHabits());

    _completedHabitKeys
      ..clear()
      ..addAll(await _database.loadHabitCompletionKeys());

    final settings = await _database.loadSettings();
    _themePreference = _themeFromSettings(settings);
    _userName = (settings['userName'] as String? ?? '').trim();
    _habitCompactView = settings['habitCompactView'] as bool? ?? true;
    _lastBackupAt = _parseDate(settings[_lastBackupAtKey]);
    _backupReminderDismissedAt = _parseDate(
      settings[_backupReminderDismissedAtKey],
    );
    _hasSafetyBackup = await _database.loadSafetyBackup() != null;
    _showMemories = settings[_showMemoriesKey] as bool? ?? true;
    _quickEntryOnOpen = settings[_quickEntryOnOpenKey] as bool? ?? true;
    _reminderEnabled = settings[_reminderEnabledKey] as bool? ?? false;
    _reminderMinutes =
        settings[_reminderMinutesKey] as int? ?? defaultReminderMinutes;
    _memoryDismissedOn = settings[_memoryDismissedOnKey] as String?;

    final storedLanguage = settings['language'] as String?;
    _languageChosen = AppStrings.supportedCodes.contains(storedLanguage);
    _languageCode = _languageChosen ? storedLanguage! : _languageFromDevice();

    final defaultsSeeded = settings[_defaultHabitsSeededKey] as bool? ?? false;

    if (!defaultsSeeded) {
      // Installs from before the flag existed: any stored data means this is
      // not a first launch, so an empty habit list was the user's choice.
      final isFirstLaunch =
          _habits.isEmpty && _goodThings.isEmpty && _completedHabitKeys.isEmpty;

      if (isFirstLaunch) {
        await _createDefaultHabits();
      } else {
        await _database.saveSetting(_defaultHabitsSeededKey, true);
      }
    }

    notifyListeners();
    await _planReminders();
  }

  @override
  void dispose() {
    _saveErrors.close();
    _actions.close();
    super.dispose();
  }

  bool canAddGoodThingForDate(DateTime date) {
    return !_dateOnly(date).isAfter(maximumFutureDate);
  }

  List<GoodThing> goodThingsForDate(DateTime date) {
    final result =
        _goodThings.where((entry) {
          return _isSameDay(entry.date, date);
        }).toList()..sort(
          (first, second) => first.createdAt.compareTo(second.createdAt),
        );

    return result;
  }

  List<GoodThing> goodThingsForMonth(DateTime month) {
    final result = _goodThings.where((entry) {
      return entry.date.year == month.year && entry.date.month == month.month;
    }).toList()..sort((first, second) => first.date.compareTo(second.date));

    return result;
  }

  /// Good Things whose date falls within [start] .. [end] (both inclusive,
  /// day precision), sorted by date.
  List<GoodThing> goodThingsInRange(DateTime start, DateTime end) {
    final from = _dateOnly(start);
    final to = _dateOnly(end);

    final result = _goodThings.where((entry) {
      final date = _dateOnly(entry.date);
      return !date.isBefore(from) && !date.isAfter(to);
    }).toList()..sort((first, second) => first.date.compareTo(second.date));

    return result;
  }

  /// Number of distinct days in [start] .. [end] (both inclusive) with at
  /// least one Good Thing.
  int goodThingDaysInRange(DateTime start, DateTime end) {
    return goodThingsInRange(
      start,
      end,
    ).map((entry) => _dateOnly(entry.date)).toSet().length;
  }

  /// Number of days in [start] .. [end] (both inclusive) on which [habitId]
  /// is marked complete.
  int habitCompletionsInRange({
    required String habitId,
    required DateTime start,
    required DateTime end,
  }) {
    final from = _dateOnly(start);
    final to = _dateOnly(end);

    if (to.isBefore(from)) {
      return 0;
    }

    var total = 0;

    for (var offset = 0; ; offset++) {
      final date = DateTime(from.year, from.month, from.day + offset);

      if (date.isAfter(to)) {
        break;
      }

      if (isHabitCompleted(habitId: habitId, date: date)) {
        total++;
      }
    }

    return total;
  }

  List<GoodThing> searchGoodThings(String query) {
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      return const [];
    }

    final result = _goodThings.where((entry) {
      return entry.text.toLowerCase().contains(cleanQuery);
    }).toList()..sort((first, second) => second.date.compareTo(first.date));

    return result;
  }

  List<String> suggestionsFor(String query, {int limit = 4}) {
    if (_goodThings.isEmpty) {
      return const [];
    }

    final normalizedQuery = query.trim().toLowerCase();
    final statistics = <String, _SuggestionStatistics>{};

    for (final entry in _goodThings) {
      final normalizedText = entry.text.trim().toLowerCase();

      if (normalizedText.isEmpty) {
        continue;
      }

      final existing = statistics[normalizedText];

      if (existing == null) {
        statistics[normalizedText] = _SuggestionStatistics(
          text: entry.text.trim(),
          count: 1,
          lastUsed: entry.updatedAt,
        );
      } else {
        statistics[normalizedText] = existing.copyWith(
          text: entry.updatedAt.isAfter(existing.lastUsed)
              ? entry.text.trim()
              : existing.text,
          count: existing.count + 1,
          lastUsed: entry.updatedAt.isAfter(existing.lastUsed)
              ? entry.updatedAt
              : existing.lastUsed,
        );
      }
    }

    final candidates =
        statistics.values.where((suggestion) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return suggestion.text.toLowerCase().contains(normalizedQuery);
        }).toList()..sort((first, second) {
          if (normalizedQuery.isNotEmpty) {
            final firstStarts = first.text.toLowerCase().startsWith(
              normalizedQuery,
            );
            final secondStarts = second.text.toLowerCase().startsWith(
              normalizedQuery,
            );

            if (firstStarts != secondStarts) {
              return firstStarts ? -1 : 1;
            }
          }

          final countComparison = second.count.compareTo(first.count);

          if (countComparison != 0) {
            return countComparison;
          }

          return second.lastUsed.compareTo(first.lastUsed);
        });

    return candidates.take(limit).map((suggestion) => suggestion.text).toList();
  }

  Future<bool> addGoodThing({
    required DateTime date,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty || !canAddGoodThingForDate(date)) {
      return false;
    }

    final now = DateTime.now();

    final entry = GoodThing(
      id: _createId(),
      date: _dateOnly(date),
      text: cleanText,
      createdAt: now,
      updatedAt: now,
    );

    _goodThings.add(entry);
    notifyListeners();

    final saved = await _persist(
      () => _database.saveGoodThing(entry),
      rollback: () => _goodThings.removeWhere((e) => e.id == entry.id),
    );
    await _planRemindersIfToday(entry.date);
    return saved;
  }

  /// Puts a deleted entry back exactly as it was — same id and timestamps,
  /// so it returns to its old place in the day. Used by "Undo".
  Future<bool> restoreGoodThing(GoodThing entry) async {
    if (_goodThings.any((existing) => existing.id == entry.id)) {
      return false;
    }

    _goodThings.add(entry);
    notifyListeners();

    final saved = await _persist(
      () => _database.saveGoodThing(entry),
      rollback: () => _goodThings.removeWhere((e) => e.id == entry.id),
    );
    await _planRemindersIfToday(entry.date);
    return saved;
  }

  Future<bool> updateGoodThing({
    required String id,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return false;
    }

    final index = _goodThings.indexWhere((entry) => entry.id == id);

    if (index == -1) {
      return false;
    }

    final previous = _goodThings[index];
    final updated = previous.copyWith(
      text: cleanText,
      updatedAt: DateTime.now(),
    );

    _goodThings[index] = updated;
    notifyListeners();

    return _persist(
      () => _database.saveGoodThing(updated),
      rollback: () => _replaceWhere(_goodThings, (e) => e.id == id, previous),
    );
  }

  Future<bool> deleteGoodThing(String id) async {
    final removed = _goodThings.where((entry) => entry.id == id).toList();

    if (removed.isEmpty) {
      return false;
    }

    _goodThings.removeWhere((entry) => entry.id == id);
    notifyListeners();

    final deleted = await _persist(
      () => _database.deleteGoodThing(id),
      rollback: () => _goodThings.addAll(removed),
    );
    await _planRemindersIfToday(removed.first.date);
    return deleted;
  }

  bool isHabitCompleted({required String habitId, required DateTime date}) {
    return _completedHabitKeys.contains(_habitCompletionKey(habitId, date));
  }

  Future<bool> toggleHabit({
    required String habitId,
    required DateTime date,
  }) async {
    final cleanDate = _dateOnly(date);

    if (cleanDate.isAfter(today)) {
      return false;
    }

    final key = _habitCompletionKey(habitId, cleanDate);

    final willBeCompleted = !_completedHabitKeys.contains(key);

    if (willBeCompleted) {
      _completedHabitKeys.add(key);
    } else {
      _completedHabitKeys.remove(key);
    }

    notifyListeners();

    return _persist(
      () => _database.setHabitCompleted(
        key: key,
        habitId: habitId,
        date: _dateKey(cleanDate),
        completed: willBeCompleted,
      ),
      rollback: () => willBeCompleted
          ? _completedHabitKeys.remove(key)
          : _completedHabitKeys.add(key),
    );
  }

  int habitTotalForMonth({
    required String habitId,
    required DateTime selectedMonth,
  }) {
    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    var total = 0;

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);

      if (isHabitCompleted(habitId: habitId, date: date)) {
        total++;
      }
    }

    return total;
  }

  Future<bool> addHabit({required String name, required String emoji}) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return false;
    }

    final habit = Habit(
      id: _createId(),
      name: cleanName,
      emoji: emoji.trim().isEmpty ? '✓' : emoji.trim(),
      isArchived: false,
      sortOrder: _habits.length,
      createdAt: DateTime.now(),
    );

    _habits.add(habit);
    notifyListeners();

    return _persist(
      () => _database.saveHabit(habit),
      rollback: () => _habits.removeWhere((h) => h.id == habit.id),
    );
  }

  Future<bool> updateHabit({
    required String id,
    required String name,
    required String emoji,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return false;
    }

    return _replaceHabit(
      id,
      (habit) => habit.copyWith(
        name: cleanName,
        emoji: emoji.trim().isEmpty ? '✓' : emoji.trim(),
      ),
    );
  }

  Future<bool> archiveHabit(String id) {
    return _replaceHabit(id, (habit) => habit.copyWith(isArchived: true));
  }

  Future<bool> restoreHabit(String id) {
    return _replaceHabit(id, (habit) => habit.copyWith(isArchived: false));
  }

  Future<bool> permanentlyDeleteHabit(String id) async {
    final removedHabits = _habits.where((habit) => habit.id == id).toList();
    final removedKeys = _completedHabitKeys
        .where((key) => key.startsWith('$id|'))
        .toList();

    _habits.removeWhere((habit) => habit.id == id);
    _completedHabitKeys.removeAll(removedKeys);

    notifyListeners();

    return _persist(
      () => _database.deleteHabit(id),
      rollback: () {
        _habits.addAll(removedHabits);
        _completedHabitKeys.addAll(removedKeys);
      },
    );
  }

  Future<bool> setThemePreference(ThemePreference value) async {
    if (_themePreference == value) {
      return false;
    }

    final previous = _themePreference;
    _themePreference = value;
    notifyListeners();

    return _persist(
      () => _database.saveSetting(_themeModeKey, value.name),
      rollback: () => _themePreference = previous,
    );
  }

  /// The saved choice, or — for data from before there was a choice — the
  /// old dark-mode switch: on means dark, switched off means light, never
  /// touched means follow the phone.
  static ThemePreference _themeFromSettings(Map<String, Object?> settings) {
    final stored = settings[_themeModeKey];

    for (final preference in ThemePreference.values) {
      if (preference.name == stored) {
        return preference;
      }
    }

    return switch (settings['darkMode']) {
      true => ThemePreference.dark,
      false => ThemePreference.light,
      _ => ThemePreference.system,
    };
  }

  /// The phone's language if the app speaks it, otherwise German.
  String _languageFromDevice() {
    final device = _deviceLanguage();
    return AppStrings.supportedCodes.contains(device) ? device : 'de';
  }

  Future<bool> setHabitCompactView(bool value) async {
    if (_habitCompactView == value) {
      return false;
    }

    final previous = _habitCompactView;
    _habitCompactView = value;
    notifyListeners();

    return _persist(
      () => _database.saveSetting('habitCompactView', value),
      rollback: () => _habitCompactView = previous,
    );
  }

  /// Picking a language fixes it — from then on the phone's language no
  /// longer matters, even if it is the same one right now.
  Future<bool> setLanguage(String code) async {
    if (!AppStrings.supportedCodes.contains(code) ||
        (_languageChosen && _languageCode == code)) {
      return false;
    }

    final previous = _languageCode;
    final previousChosen = _languageChosen;
    _languageCode = code;
    _languageChosen = true;
    notifyListeners();

    final saved = await _persist(
      () => _database.saveSetting('language', code),
      rollback: () {
        _languageCode = previous;
        _languageChosen = previousChosen;
      },
    );
    await _planReminders();
    return saved;
  }

  Future<bool> setUserName(String value) async {
    final cleanValue = value.trim();

    if (_userName == cleanValue) {
      return false;
    }

    final previous = _userName;
    _userName = cleanValue;
    notifyListeners();

    return _persist(
      () => _database.saveSetting('userName', cleanValue),
      rollback: () => _userName = previous,
    );
  }

  // ---- Quick entry ----------------------------------------------------------

  /// Whether opening the app on a phone goes straight to today's field.
  bool get quickEntryOnOpen => _quickEntryOnOpen;

  /// Open straight into typing — only while today is still empty, so opening
  /// the app to read never pops up a keyboard.
  bool get shouldStartWithQuickEntry =>
      _quickEntryOnOpen && goodThingsForDate(today).isEmpty;

  void requestAction(AppAction action) {
    if (!_actions.isClosed) {
      _actions.add(action);
    }
  }

  Future<bool> setQuickEntryOnOpen(bool value) async {
    if (_quickEntryOnOpen == value) {
      return false;
    }

    final previous = _quickEntryOnOpen;
    _quickEntryOnOpen = value;
    notifyListeners();

    return _persist(
      () => _database.saveSetting(_quickEntryOnOpenKey, value),
      rollback: () => _quickEntryOnOpen = previous,
    );
  }

  // ---- Evening reminder -----------------------------------------------------

  /// Whether this device can show reminders (Android / iOS app).
  bool get reminderSupported => _reminders.isSupported;

  bool get reminderEnabled => _reminderEnabled && _reminders.isSupported;

  /// Minutes after midnight, e.g. 1230 for 20:30.
  int get reminderMinutes => _reminderMinutes;

  /// Switching on asks for the notification permission first; if it is
  /// refused the reminder stays off and this returns false.
  Future<bool> setReminderEnabled(bool value) async {
    if (value && !await _reminders.requestPermission()) {
      return false;
    }

    _reminderEnabled = value;
    notifyListeners();
    await _database.saveSetting(_reminderEnabledKey, value);
    await _planReminders();
    return true;
  }

  Future<void> setReminderMinutes(int minutes) async {
    _reminderMinutes = minutes;
    notifyListeners();
    await _database.saveSetting(_reminderMinutesKey, minutes);
    await _planReminders();
  }

  Future<void> _planRemindersIfToday(DateTime date) async {
    if (_isSameDay(date, today)) {
      await _planReminders();
    }
  }

  /// Re-plans the next evenings. Never lets a notification problem get in
  /// the way of saving an entry.
  Future<void> _planReminders() async {
    if (!_reminders.isSupported) {
      return;
    }

    try {
      if (!_reminderEnabled) {
        await _reminders.cancelAll();
        return;
      }

      await _reminders.schedule(
        reminderTimes(
          now: DateTime.now(),
          hour: _reminderMinutes ~/ 60,
          minute: _reminderMinutes % 60,
          wroteToday: goodThingsForDate(today).isNotEmpty,
        ),
        title: strings.reminderTitle,
        body: strings.reminderBody,
        channelName: strings.reminderChannel,
      );
    } catch (error, stackTrace) {
      debugPrint('Lighthouse could not plan reminders: $error\n$stackTrace');
    }
  }

  // ---- Memories -------------------------------------------------------------

  /// Whether Good Things shows "Heute vor einem Jahr / Monat".
  bool get showMemories => _showMemories;

  /// Today's memory card, unless switched off or dismissed for today.
  Memory? get todaysMemory {
    if (!_showMemories || _memoryDismissedOn == _dateKey(today)) {
      return null;
    }

    return memoryFor(today);
  }

  /// A Good Thing written exactly one year before [day], or — if there is
  /// none — exactly one month before. A day that doesn't exist there (29.02.
  /// a year later, 31.03. a month earlier) has no memory. With several
  /// entries on that day the pick depends only on [day], so it stays the
  /// same all day instead of changing on every rebuild.
  Memory? memoryFor(DateTime day) {
    for (final age in MemoryAge.values) {
      final then = switch (age) {
        MemoryAge.year => DateTime(day.year - 1, day.month, day.day),
        MemoryAge.month => DateTime(day.year, day.month - 1, day.day),
      };

      // DateTime rolls 31.02. over into March — that date didn't exist.
      if (then.day != day.day) {
        continue;
      }

      final candidates = goodThingsForDate(then);

      if (candidates.isNotEmpty) {
        final seed = day.year * 10000 + day.month * 100 + day.day;
        return Memory(candidates[seed % candidates.length], age);
      }
    }

    return null;
  }

  Future<bool> setShowMemories(bool value) async {
    if (_showMemories == value) {
      return false;
    }

    final previous = _showMemories;
    _showMemories = value;
    notifyListeners();

    return _persist(
      () => _database.saveSetting(_showMemoriesKey, value),
      rollback: () => _showMemories = previous,
    );
  }

  /// Hides today's memory card until tomorrow.
  Future<void> dismissTodaysMemory() async {
    final key = _dateKey(today);
    _memoryDismissedOn = key;
    notifyListeners();
    await _database.saveSetting(_memoryDismissedOnKey, key);
  }

  // ---- Backup ---------------------------------------------------------------

  /// When a backup file was last saved on this device (or the date of the
  /// backup that was restored).
  DateTime? get lastBackupAt => _lastBackupAt;

  /// Whether the data from before the last restore can be brought back.
  bool get hasSafetyBackup => _hasSafetyBackup;

  /// The gentle "save a backup" banner on Good Things.
  bool get showBackupReminder => shouldRemindAboutBackup(
    now: DateTime.now(),
    lastBackupAt: _lastBackupAt,
    firstEntryAt: _firstEntryAt,
    dismissedAt: _backupReminderDismissedAt,
  );

  /// When the user's own data started: the first Good Thing, or — for
  /// habits-only use — the habits, once any day has been marked.
  DateTime? get _firstEntryAt {
    DateTime? first;

    for (final entry in _goodThings) {
      if (first == null || entry.createdAt.isBefore(first)) {
        first = entry.createdAt;
      }
    }

    if (first == null && _completedHabitKeys.isNotEmpty) {
      for (final habit in _habits) {
        if (first == null || habit.createdAt.isBefore(first)) {
          first = habit.createdAt;
        }
      }
    }

    return first;
  }

  /// A snapshot of everything stored, ready to be written to a file.
  Future<Backup> createBackup() async {
    final data = await _database.exportData();

    return Backup(
      createdAt: DateTime.now(),
      appVersion: kAppVersion,
      data: BackupData(
        goodThings: data.goodThings,
        habits: data.habits,
        habitEntries: data.habitEntries,
        settings: {
          for (final setting in data.settings.entries)
            if (!_deviceOnlySettings.contains(setting.key))
              setting.key: setting.value,
        },
      ),
    );
  }

  /// Call once the file was actually written.
  Future<void> markBackupSaved(DateTime at) async {
    _lastBackupAt = at;
    notifyListeners();
    await _database.saveSetting(_lastBackupAtKey, at.toIso8601String());
  }

  Future<void> dismissBackupReminder() async {
    final now = DateTime.now();
    _backupReminderDismissedAt = now;
    notifyListeners();
    await _database.saveSetting(
      _backupReminderDismissedAtKey,
      now.toIso8601String(),
    );
  }

  /// Replaces all data with [backup]. The current data is kept as a safety
  /// backup first, so [undoRestore] can bring it back. Throws if storage
  /// fails; the replace itself is all-or-nothing.
  Future<void> restoreBackup(Backup backup) async {
    final current = await createBackup();
    await _database.saveSafetyBackup(current.encode());

    await _database.replaceAllData(
      BackupData(
        goodThings: backup.data.goodThings,
        habits: backup.data.habits,
        habitEntries: backup.data.habitEntries,
        settings: {
          for (final setting in backup.data.settings.entries)
            if (!_deviceOnlySettings.contains(setting.key) &&
                setting.value != null)
              setting.key: setting.value,
          // The restored data is exactly what that backup holds.
          _lastBackupAtKey: backup.createdAt.toIso8601String(),
        },
      ),
    );

    await initialize();
  }

  /// Brings back the data as it was right before the last restore.
  Future<void> undoRestore() async {
    final encoded = await _database.loadSafetyBackup();

    if (encoded == null) {
      return;
    }

    final previous = Backup.decode(encoded);
    final lastBackupAt = _lastBackupAt;

    await _database.replaceAllData(previous.data);
    if (lastBackupAt != null) {
      await _database.saveSetting(
        _lastBackupAtKey,
        lastBackupAt.toIso8601String(),
      );
    }
    await _database.deleteSafetyBackup();

    await initialize();
  }

  Future<bool> clearAllData() async {
    try {
      await _database.clearAllData();
    } catch (error, stackTrace) {
      _reportSaveError(error, stackTrace);
      return false;
    }

    _goodThings.clear();
    _habits.clear();
    _completedHabitKeys.clear();
    _themePreference = ThemePreference.system;
    _userName = '';
    _habitCompactView = true;
    _languageCode = _languageFromDevice();
    _languageChosen = false;
    _lastBackupAt = null;
    _backupReminderDismissedAt = null;
    _hasSafetyBackup = false;
    _showMemories = true;
    _memoryDismissedOn = null;
    _quickEntryOnOpen = true;
    _reminderEnabled = false;
    _reminderMinutes = defaultReminderMinutes;

    await _createDefaultHabits();
    notifyListeners();
    await _planReminders();
    return true;
  }

  /// Runs a storage [write] for a change that is already applied in memory.
  /// If the write fails, [rollback] undoes the in-memory change so the screen
  /// never shows something that isn't actually saved, and [saveErrors] fires.
  Future<bool> _persist(
    Future<void> Function() write, {
    required VoidCallback rollback,
  }) async {
    try {
      await write();
      return true;
    } catch (error, stackTrace) {
      rollback();
      notifyListeners();
      _reportSaveError(error, stackTrace);
      return false;
    }
  }

  void _reportSaveError(Object error, StackTrace stackTrace) {
    debugPrint('Lighthouse could not save: $error\n$stackTrace');

    if (!_saveErrors.isClosed) {
      _saveErrors.add(error);
    }
  }

  Future<bool> _replaceHabit(String id, Habit Function(Habit) change) async {
    final index = _habits.indexWhere((habit) => habit.id == id);

    if (index == -1) {
      return false;
    }

    final previous = _habits[index];
    final updated = change(previous);

    _habits[index] = updated;
    notifyListeners();

    return _persist(
      () => _database.saveHabit(updated),
      rollback: () => _replaceWhere(_habits, (h) => h.id == id, previous),
    );
  }

  static void _replaceWhere<T>(
    List<T> list,
    bool Function(T) test,
    T replacement,
  ) {
    final index = list.indexWhere(test);

    if (index != -1) {
      list[index] = replacement;
    }
  }

  Future<void> _createDefaultHabits() async {
    final now = DateTime.now();

    final defaults = [
      Habit(
        id: 'work',
        name: 'Work',
        emoji: '💼',
        isArchived: false,
        sortOrder: 0,
        createdAt: now,
      ),
      Habit(
        id: 'coffee',
        name: 'Coffee',
        emoji: '☕',
        isArchived: false,
        sortOrder: 1,
        createdAt: now,
      ),
      Habit(
        id: 'water',
        name: 'Water',
        emoji: '💧',
        isArchived: false,
        sortOrder: 2,
        createdAt: now,
      ),
      Habit(
        id: 'coding',
        name: 'Coding',
        emoji: '💻',
        isArchived: false,
        sortOrder: 3,
        createdAt: now,
      ),
      Habit(
        id: 'sport',
        name: 'Sport',
        emoji: '🏃',
        isArchived: false,
        sortOrder: 4,
        createdAt: now,
      ),
      Habit(
        id: 'alcohol',
        name: 'Alkohol',
        emoji: '🍷',
        isArchived: false,
        sortOrder: 5,
        createdAt: now,
      ),
    ];

    _habits.addAll(defaults);

    for (final habit in defaults) {
      await _database.saveHabit(habit);
    }

    await _database.saveSetting(_defaultHabitsSeededKey, true);
  }

  String _createId() {
    _idCounter++;

    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  String _habitCompletionKey(String habitId, DateTime date) {
    return '$habitId|${_dateKey(date)}';
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _SuggestionStatistics {
  const _SuggestionStatistics({
    required this.text,
    required this.count,
    required this.lastUsed,
  });

  final String text;
  final int count;
  final DateTime lastUsed;

  _SuggestionStatistics copyWith({
    String? text,
    int? count,
    DateTime? lastUsed,
  }) {
    return _SuggestionStatistics(
      text: text ?? this.text,
      count: count ?? this.count,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

/// How the app picks light or dark.
enum ThemePreference { system, light, dark }

/// Where a shortcut or the app start wants to go.
enum AppAction {
  /// Good Things, today's field focused.
  addGoodThing,

  /// The Habits tab.
  habits;

  /// The id used in shortcuts (`?action=add`, quick action types).
  String get id => switch (this) {
    AppAction.addGoodThing => 'add',
    AppAction.habits => 'habits',
  };

  static AppAction? fromId(String? id) {
    for (final action in values) {
      if (action.id == id) {
        return action;
      }
    }
    return null;
  }
}

enum MemoryAge { year, month }

/// An earlier Good Thing brought back on the same calendar day.
class Memory {
  const Memory(this.entry, this.age);

  final GoodThing entry;
  final MemoryAge age;
}
