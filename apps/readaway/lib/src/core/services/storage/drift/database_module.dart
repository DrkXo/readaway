import 'package:injectable/injectable.dart';

import 'app_database.dart';

/// Registers the shared [AppDatabase].
@module
abstract class DatabaseModule {
  @singleton
  AppDatabase provideAppDatabase() => AppDatabase.open();
}
