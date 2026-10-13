import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/settings_service.dart';
import 'package:readaway/src/core/services/storage/drift/app_database.dart';
import 'package:readaway/src/core/services/storage/drift/daos/settings_dao.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late AppDatabase db;
  late SettingsService service;

  setUp(() {
    db = openTestDatabase();
    service = SettingsService(SettingsDao(db));
  });

  tearDown(() => db.close());

  test('persists settings and loads them back from the database', () async {
    await service.init();

    const newSettings = Settings(screenWakeLock: true);
    await service.save(newSettings);

    expect(service.settings.screenWakeLock, isTrue);

    final reloaded = SettingsService(SettingsDao(db));
    await reloaded.init();
    expect(reloaded.settings.screenWakeLock, isTrue);

    final rows = await db.select(db.appSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.payload.screenWakeLock, isTrue);
  });

  test('init stores defaults when nothing has been saved yet', () async {
    await service.init();

    expect(service.settings, const Settings());
    final rows = await db.select(db.appSettings).get();
    expect(rows, hasLength(1));
  });
}
