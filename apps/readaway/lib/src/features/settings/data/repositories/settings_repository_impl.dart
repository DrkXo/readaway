import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/settings_service.dart';
import '../../domain/entity/settings.dart';
import '../../domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsService _settingsService;

  SettingsRepositoryImpl(this._settingsService);

  @override
  Future<Result<Settings>> getSettings() {
    return guard(
      () async => _settingsService.settings,
      onError: (error, stack) => StorageReadFailure(
        'app_settings',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> saveSettings(Settings settings) {
    return guard(
      () async => _settingsService.save(settings),
      onError: (error, stack) => StorageWriteFailure(
        'app_settings',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> resetSettings() {
    return guard(
      () async => _settingsService.save(const Settings()),
      onError: (error, stack) => StorageResetFailure(
        'Failed to reset settings: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Stream<Settings> watchSettings() => _settingsService.changes;
}
