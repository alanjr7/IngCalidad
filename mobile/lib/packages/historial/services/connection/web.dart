import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Conexión SQLite sobre WebAssembly (navegador).
/// Requiere `web/sqlite3.wasm` y `web/drift_worker.js`.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'scamshield',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
