import 'package:drift/native.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';

/// Opens an in-memory drift database with the full schema applied and the
/// migration strategy (foreign keys on) executed.
///
/// Tests must close it (typically in `tearDown` / `addTearDown`).
AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());
