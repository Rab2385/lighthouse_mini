import 'package:sembast/sembast.dart';

import 'database_open_io.dart'
    if (dart.library.js_interop) 'database_open_web.dart';

/// Opens the Sembast database for the current platform.
///
/// On web this is an IndexedDB-backed store; on Android, iOS, desktop it is a
/// file inside the app's documents directory. The rest of the app only talks
/// to [Database], so it stays platform-agnostic.
Future<Database> openLighthouseDatabase(String databaseName) {
  return openPlatformDatabase(databaseName);
}
