import 'dart:js_interop';

import 'package:sembast_web/sembast_web.dart';

/// Web implementation: an IndexedDB-backed store keyed by [databaseName].
Future<Database> openPlatformDatabase(String databaseName) {
  _requestPersistentStorage();
  return databaseFactoryWeb.openDatabase(databaseName, version: 1);
}

@JS('navigator.storage')
external _StorageManager? get _storageManager;

extension type _StorageManager._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> persist();
}

/// Asks the browser to keep this origin's IndexedDB under storage pressure
/// instead of silently evicting it. Best effort: browsers may decline, and
/// older ones don't have the API at all — neither should block startup.
void _requestPersistentStorage() {
  try {
    _storageManager?.persist().toDart.catchError((_) => false.toJS);
  } catch (_) {
    // Not supported here; the app works the same, just without the request.
  }
}
