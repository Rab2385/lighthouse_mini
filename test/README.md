# Tests

Run everything with:

```bash
flutter test
```

The whole suite finishes in a few seconds. CI (`.github/workflows/ci.yml`)
runs `flutter analyze` and `flutter test` on every push and pull request.

## Touching the database in a widget test

`testWidgets` runs its body inside a `FakeAsync` zone. Sembast (even the
in-memory factory) does real asynchronous I/O, which **never completes** there,
so the test simply hangs until the 10-minute timeout. Do all database setup
inside `tester.runAsync`:

```dart
await tester.runAsync(() async {
  await controller.initialize();
  await controller.addGoodThing(date: controller.today, text: 'Entry');
});
```

Plain `test(...)` cases (like `controller_test`) run on the real event loop
and don't need this.

## What they cover

| File | Covers |
|---|---|
| `widget_test` | `GoodThing` / `Habit` map round-trips; `greetingForTime` — time buckets, name trimming, both languages |
| `edit_good_thing_test` | drives add → edit dialog → save against an in-memory database; regression guard for the `_dependents.isEmpty` crash |
| `controller_test` | default habits are only seeded once; Undo restores the original entry; failed saves roll back and are reported |
| `backup_test` | backup file round trip into a fresh install; refuses non-JSON, foreign, newer and damaged files; restore + undo; reminder timing; app version in step with pubspec |
| `resume_policy_test` | when coming back to the app jumps to today (new day / 10+ min away) and when it doesn't |

Database tests use `LighthouseDatabase.withFactory(databaseFactoryMemory, name)`
— give each test its own `name`, since memory databases are shared by name.
