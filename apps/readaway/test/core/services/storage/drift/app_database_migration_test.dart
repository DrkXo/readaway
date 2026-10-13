import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';

void main() {
  test('fresh database has schemaVersion 1 and opens cleanly', () async {
    final dir = await Directory.systemTemp.createTemp('drift_mig_');
    final file = File('${dir.path}/fresh.sqlite');
    addTearDown(() async {
      if (await file.exists()) await file.delete();
      await dir.delete(recursive: true);
    });

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], 1);
  });

  test('onUpgrade is a no-op when from >= to (1 -> 1)', () async {
    final dir = await Directory.systemTemp.createTemp('drift_mig_');
    final file = File('${dir.path}/v1eq.sqlite');
    addTearDown(() async {
      if (await file.exists()) await file.delete();
      await dir.delete(recursive: true);
    });

    final db = AppDatabase(NativeDatabase(file), schemaVersion: 1);
    await db.close();

    // Re-opening with the same schemaVersion should not throw.
    final db2 = AppDatabase(NativeDatabase(file), schemaVersion: 1);
    await db2.close();
  });
}
