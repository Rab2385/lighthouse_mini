import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/lighthouse_database.dart';
import '../models/good_thing.dart';
import '../models/habit.dart';

class LighthouseController extends ChangeNotifier {
  LighthouseController(this._database);

  final LighthouseDatabase _database;

  final List<GoodThing> _goodThings = [];
  final List<Habit> _habits = [];
  final Set<String> _completedHabitKeys = {};

  int _idCounter = 0;

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

    if (_habits.isEmpty) {
      await _createDefaultHabits();
    }

    notifyListeners();
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

  Future<void> addGoodThing({
    required DateTime date,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty || !canAddGoodThingForDate(date)) {
      return;
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

    await _database.saveGoodThing(entry);
  }

  Future<void> updateGoodThing({
    required String id,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final index = _goodThings.indexWhere((entry) => entry.id == id);

    if (index == -1) {
      return;
    }

    final updated = _goodThings[index].copyWith(
      text: cleanText,
      updatedAt: DateTime.now(),
    );

    _goodThings[index] = updated;
    notifyListeners();

    await _database.saveGoodThing(updated);
  }

  Future<void> deleteGoodThing(String id) async {
    _goodThings.removeWhere((entry) => entry.id == id);
    notifyListeners();

    await _database.deleteGoodThing(id);
  }

  bool isHabitCompleted({required String habitId, required DateTime date}) {
    return _completedHabitKeys.contains(_habitCompletionKey(habitId, date));
  }

  Future<void> toggleHabit({
    required String habitId,
    required DateTime date,
  }) async {
    final cleanDate = _dateOnly(date);

    if (cleanDate.isAfter(today)) {
      return;
    }

    final key = _habitCompletionKey(habitId, cleanDate);

    final willBeCompleted = !_completedHabitKeys.contains(key);

    if (willBeCompleted) {
      _completedHabitKeys.add(key);
    } else {
      _completedHabitKeys.remove(key);
    }

    notifyListeners();

    await _database.setHabitCompleted(
      key: key,
      habitId: habitId,
      date: _dateKey(cleanDate),
      completed: willBeCompleted,
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

  Future<void> addHabit({
    required String name,
    required String emoji,
    required String description,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return;
    }

    final habit = Habit(
      id: _createId(),
      name: cleanName,
      emoji: emoji.trim().isEmpty ? '✓' : emoji.trim(),
      description: description.trim(),
      isArchived: false,
      sortOrder: _habits.length,
      createdAt: DateTime.now(),
    );

    _habits.add(habit);
    notifyListeners();

    await _database.saveHabit(habit);
  }

  Future<void> updateHabit({
    required String id,
    required String name,
    required String emoji,
    required String description,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return;
    }

    final index = _habits.indexWhere((habit) => habit.id == id);

    if (index == -1) {
      return;
    }

    final updated = _habits[index].copyWith(
      name: cleanName,
      emoji: emoji.trim().isEmpty ? '✓' : emoji.trim(),
      description: description.trim(),
    );

    _habits[index] = updated;
    notifyListeners();

    await _database.saveHabit(updated);
  }

  Future<void> archiveHabit(String id) async {
    final index = _habits.indexWhere((habit) => habit.id == id);

    if (index == -1) {
      return;
    }

    final updated = _habits[index].copyWith(isArchived: true);

    _habits[index] = updated;
    notifyListeners();

    await _database.saveHabit(updated);
  }

  Future<void> restoreHabit(String id) async {
    final index = _habits.indexWhere((habit) => habit.id == id);

    if (index == -1) {
      return;
    }

    final updated = _habits[index].copyWith(isArchived: false);

    _habits[index] = updated;
    notifyListeners();

    await _database.saveHabit(updated);
  }

  Future<void> permanentlyDeleteHabit(String id) async {
    _habits.removeWhere((habit) => habit.id == id);
    _completedHabitKeys.removeWhere((key) => key.startsWith('$id|'));

    notifyListeners();

    await _database.deleteHabit(id);
  }

  Future<void> _createDefaultHabits() async {
    final now = DateTime.now();

    final defaults = [
      Habit(
        id: 'work',
        name: 'Work',
        emoji: '💼',
        description: 'Ich habe gearbeitet.',
        isArchived: false,
        sortOrder: 0,
        createdAt: now,
      ),
      Habit(
        id: 'coffee',
        name: 'Coffee',
        emoji: '☕',
        description: 'Ich habe Kaffee getrunken.',
        isArchived: false,
        sortOrder: 1,
        createdAt: now,
      ),
      Habit(
        id: 'water',
        name: 'Water',
        emoji: '💧',
        description: 'Ich habe genug Wasser getrunken.',
        isArchived: false,
        sortOrder: 2,
        createdAt: now,
      ),
      Habit(
        id: 'coding',
        name: 'Coding',
        emoji: '💻',
        description: 'Ich habe programmiert.',
        isArchived: false,
        sortOrder: 3,
        createdAt: now,
      ),
      Habit(
        id: 'sport',
        name: 'Sport',
        emoji: '🏃',
        description: 'Ich habe Sport gemacht.',
        isArchived: false,
        sortOrder: 4,
        createdAt: now,
      ),
      Habit(
        id: 'alcohol',
        name: 'Alkohol',
        emoji: '🍷',
        description: 'Ich habe Alkohol getrunken.',
        isArchived: false,
        sortOrder: 5,
        createdAt: now,
      ),
    ];

    _habits.addAll(defaults);

    for (final habit in defaults) {
      await _database.saveHabit(habit);
    }
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
