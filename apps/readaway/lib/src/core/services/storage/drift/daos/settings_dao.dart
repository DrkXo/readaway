import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../../features/settings/domain/entity/settings.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

/// The single application-settings row (`id = 1`).
@DriftAccessor(tables: [AppSettings])
@lazySingleton
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// The stored settings, or null when none have ever been saved.
  Future<Settings?> get() async {
    final row = await (select(
      appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    return row?.payload;
  }

  /// Inserts or replaces the settings row, stamping the write time.
  Future<void> put(Settings settings) {
    return into(appSettings).insert(
      AppSettingRow(id: 1, payload: settings, updatedAt: DateTime.now()),
      mode: InsertMode.insertOrReplace,
    );
  }
}
