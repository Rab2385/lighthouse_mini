import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

import 'package:lighthouse_mini/data/lighthouse_database.dart';
import 'package:lighthouse_mini/models/good_thing.dart';
import 'package:lighthouse_mini/state/lighthouse_controller.dart';

/// A memory database whose Good Thing writes can be made to fail, to stand in
/// for a full or evicted browser storage.
class _FlakyDatabase extends LighthouseDatabase {
  _FlakyDatabase(String name) : super.withFactory(databaseFactoryMemory, name);

  bool failWrites = false;

  @override
  Future<void> saveGoodThing(GoodThing entry) async {
    if (failWrites) {
      throw StateError('storage full');
    }
    return super.saveGoodThing(entry);
  }
}

LighthouseDatabase _memoryDatabase(String name) {
  return LighthouseDatabase.withFactory(databaseFactoryMemory, name);
}

void main() {
  group('default habits (#3)', () {
    test('are created on the very first launch', () async {
      final controller = LighthouseController(_memoryDatabase('seed-first'));
      await controller.initialize();

      expect(controller.habits.map((habit) => habit.id), [
        'work',
        'coffee',
        'water',
        'coding',
        'sport',
      ]);
    });

    test('stay gone after the user deletes every habit', () async {
      final database = _memoryDatabase('seed-deleted');
      final first = LighthouseController(database);
      await first.initialize();

      for (final habit in first.habits) {
        await first.permanentlyDeleteHabit(habit.id);
      }

      final restarted = LighthouseController(database);
      await restarted.initialize();

      expect(restarted.habits, isEmpty);
    });

    test('are not re-added for an older install without the flag', () async {
      final database = _memoryDatabase('seed-legacy');
      // An install from before the flag: a Good Thing, no habits, no flag.
      final now = DateTime.now();
      await database.saveGoodThing(
        GoodThing(
          id: 'old',
          date: DateTime(now.year, now.month, now.day),
          text: 'Kaffee',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final restarted = LighthouseController(database);
      await restarted.initialize();

      expect(restarted.habits, isEmpty);
    });
  });

  group('restoreGoodThing (#4)', () {
    test('puts a deleted entry back in its old place with its id', () async {
      final database = _memoryDatabase('restore');
      final controller = LighthouseController(database);
      await controller.initialize();

      await controller.addGoodThing(date: controller.today, text: 'first');
      await controller.addGoodThing(date: controller.today, text: 'second');
      final deleted = controller.goodThingsForDate(controller.today).first;

      await controller.deleteGoodThing(deleted.id);
      await controller.restoreGoodThing(deleted);

      final day = controller.goodThingsForDate(controller.today);
      expect(day.map((e) => e.text), ['first', 'second']);
      expect(day.first.id, deleted.id);
      expect(day.first.createdAt, deleted.createdAt);

      // And it is really stored, not just in memory.
      final reloaded = LighthouseController(database);
      await reloaded.initialize();
      expect(reloaded.goodThings.map((e) => e.id), contains(deleted.id));
    });

    test('does nothing when the entry is already there', () async {
      final controller = LighthouseController(_memoryDatabase('restore-dup'));
      await controller.initialize();
      await controller.addGoodThing(date: controller.today, text: 'once');
      final entry = controller.goodThings.single;

      expect(await controller.restoreGoodThing(entry), isFalse);
      expect(controller.goodThings, hasLength(1));
    });
  });

  group('failed saves (#5)', () {
    test('roll back the change and report the error', () async {
      final database = _FlakyDatabase('flaky');
      final controller = LighthouseController(database);
      await controller.initialize();

      final errors = <Object>[];
      final subscription = controller.saveErrors.listen(errors.add);

      database.failWrites = true;
      final saved = await controller.addGoodThing(
        date: controller.today,
        text: 'lost?',
      );
      await Future<void>.delayed(Duration.zero);

      expect(saved, isFalse);
      expect(controller.goodThings, isEmpty);
      expect(errors, hasLength(1));

      database.failWrites = false;
      expect(
        await controller.addGoodThing(date: controller.today, text: 'kept'),
        isTrue,
      );
      expect(controller.goodThings.single.text, 'kept');

      await subscription.cancel();
    });

    test('of an edit restore the previous text', () async {
      final database = _FlakyDatabase('flaky-edit');
      final controller = LighthouseController(database);
      await controller.initialize();
      await controller.addGoodThing(date: controller.today, text: 'before');
      final id = controller.goodThings.single.id;

      database.failWrites = true;
      final saved = await controller.updateGoodThing(id: id, text: 'after');

      expect(saved, isFalse);
      expect(controller.goodThings.single.text, 'before');
    });
  });
}
