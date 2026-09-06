import 'package:sembast/sembast.dart';

import '../models/good_thing.dart';
import '../models/habit.dart';
import 'database_open.dart';

class LighthouseDatabase {
  static const String _databaseName = 'lighthouse_mini.db';

  final StoreRef<String, Map<String, Object?>> _goodThingsStore =
      stringMapStoreFactory.store('good_things');

  final StoreRef<String, Map<String, Object?>> _habitsStore =
      stringMapStoreFactory.store('habits');

  final StoreRef<String, Map<String, Object?>> _habitEntriesStore =
      stringMapStoreFactory.store('habit_entries');

  final StoreRef<String, Object?> _settingsStore =
      StoreRef<String, Object?>('settings');

  Database? _database;

  Future<Database> get _db async {
    return _database ??= await openLighthouseDatabase(_databaseName);
  }

  Future<List<GoodThing>> loadGoodThings() async {
    final database = await _db;

    final snapshots = await _goodThingsStore.find(
      database,
      finder: Finder(
        sortOrders: [
          SortOrder('date'),
          SortOrder('createdAt'),
        ],
      ),
    );

    return snapshots
        .map((snapshot) => GoodThing.fromMap(snapshot.value))
        .toList();
  }

  Future<void> saveGoodThing(GoodThing entry) async {
    final database = await _db;

    await _goodThingsStore.record(entry.id).put(
          database,
          entry.toMap(),
        );
  }

  Future<void> deleteGoodThing(String id) async {
    final database = await _db;
    await _goodThingsStore.record(id).delete(database);
  }

  Future<List<Habit>> loadHabits() async {
    final database = await _db;

    final snapshots = await _habitsStore.find(
      database,
      finder: Finder(
        sortOrders: [
          SortOrder('sortOrder'),
          SortOrder('createdAt'),
        ],
      ),
    );

    return snapshots
        .map((snapshot) => Habit.fromMap(snapshot.value))
        .toList();
  }

  Future<void> saveHabit(Habit habit) async {
    final database = await _db;

    await _habitsStore.record(habit.id).put(
          database,
          habit.toMap(),
        );
  }

  Future<void> deleteHabit(String id) async {
    final database = await _db;

    await database.transaction((transaction) async {
      await _habitsStore.record(id).delete(transaction);

      final relatedEntries = await _habitEntriesStore.find(
        transaction,
        finder: Finder(
          filter: Filter.equals('habitId', id),
        ),
      );

      for (final entry in relatedEntries) {
        await _habitEntriesStore.record(entry.key).delete(
              transaction,
            );
      }
    });
  }

  Future<Set<String>> loadHabitCompletionKeys() async {
    final database = await _db;
    final snapshots = await _habitEntriesStore.find(database);

    return snapshots.map((snapshot) => snapshot.key).toSet();
  }

  Future<void> setHabitCompleted({
    required String key,
    required String habitId,
    required String date,
    required bool completed,
  }) async {
    final database = await _db;
    final record = _habitEntriesStore.record(key);

    if (completed) {
      await record.put(
        database,
        {
          'habitId': habitId,
          'date': date,
          'completed': true,
        },
      );
    } else {
      await record.delete(database);
    }
  }

  Future<Map<String, Object?>> loadSettings() async {
    final database = await _db;
    final snapshots = await _settingsStore.find(database);

    return {
      for (final snapshot in snapshots)
        snapshot.key: snapshot.value,
    };
  }

  Future<void> saveSetting(
    String key,
    Object? value,
  ) async {
    final database = await _db;
    await _settingsStore.record(key).put(database, value);
  }

  Future<void> clearAllData() async {
    final database = await _db;

    await database.transaction((transaction) async {
      await _goodThingsStore.delete(transaction);
      await _habitsStore.delete(transaction);
      await _habitEntriesStore.delete(transaction);
      await _settingsStore.delete(transaction);
    });
  }
}
