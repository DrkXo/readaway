import 'package:drift/drift.dart';

/// Database-level bookkeeping: schema markers and one-time flags. Not user
/// data, and never surfaced to the app.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
