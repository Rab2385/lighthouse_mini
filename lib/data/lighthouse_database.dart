import 'package:sembast_web/sembast_web.dart';

import '../models/good_thing.dart';
import '../models/habit.dart';

class LighthouseDatabase {
  static const String _databaseName = 'lighthouse_mini.db';

  final StoreRef<String, Map<String, Object?>> _goodThingsStore =
      stringMapStoreFactory.store('good_things');

  final StoreRef<String, Map<String, Object?>> _habitsStore =
      stringMapStoreFactory.store('habits');

  final StoreRef<String, Map<String, Object?>> _habitEntriesStore =
      stringMapStoreFactory.store('habit_entries');

  Database? _database;

  Future<Database> get _db async {
    return _database ??= await databaseFactoryWeb.openDatabase(
      _databaseName,
      version: 1,
    );
  }

  Future<List<GoodThing>> loadGoodThings() async {
    final database = await _db;

    final snapshots = await _goodThingsStore.find(
      database,
      finder: Finder(sortOrders: [SortOrder('date'), SortOrder('createdAt')]),
    );

    return snapshots
        .map((snapshot) => GoodThing.fromMap(snapshot.value))
        .toList();
  }

  Future<void> saveGoodThing(GoodThing entry) async {
    final database = await _db;

    await _goodThingsStore.record(entry.id).put(database, entry.toMap());
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
        sortOrders: [SortOrder('sortOrder'), SortOrder('createdAt')],
      ),
    );

    return snapshots.map((snapshot) => Habit.fromMap(snapshot.value)).toList();
  }

  Future<void> saveHabit(Habit habit) async {
    final database = await _db;

    await _habitsStore.record(habit.id).put(database, habit.toMap());
  }

  Future<void> deleteHabit(String id) async {
    final database = await _db;

    await database.transaction((transaction) async {
      await _habitsStore.record(id).delete(transaction);

      final relatedEntries = await _habitEntriesStore.find(
        transaction,
        finder: Finder(filter: Filter.equals('habitId', id)),
      );

      for (final entry in relatedEntries) {
        await _habitEntriesStore.record(entry.key).delete(transaction);
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
      await record.put(database, {
        'habitId': habitId,
        'date': date,
        'completed': true,
      });
    } else {
      await record.delete(database);
    }
  }
}
