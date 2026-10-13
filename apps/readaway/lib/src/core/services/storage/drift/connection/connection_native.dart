import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../../../path_service.dart';

/// Opens the SQLite database in a background isolate.
///
/// WAL lets readers proceed while reading progress is being written, and the
/// background isolate keeps those writes off the UI thread.
QueryExecutor openAppConnection() {
  final paths = AppPathService();
  return LazyDatabase(() async {
    final dir = await paths.storageDirectory;
    final file = File(p.join(dir.path, 'readaway.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA foreign_keys = ON;');
        db.execute('PRAGMA busy_timeout = 5000;');
      },
    );
  });
}
