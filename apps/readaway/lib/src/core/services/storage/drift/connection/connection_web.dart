import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the SQLite database in a web worker.
///
/// Requires `sqlite3.wasm` and `drift_worker.dart.js` to be served from the
/// app's `web/` directory. Journal mode is left at the SQLite default: WAL is
/// not available on the web.
QueryExecutor openAppConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'readaway',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );
      return result.resolvedExecutor;
    }),
  );
}
