import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/settings_service.dart';
import '../../domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsService _settingsService;

  SettingsRepositoryImpl(this._settingsService);

  @override
  TaskEither<Failure, Settings> getSettings() {
    return TaskEither.tryCatch(
      () async => _settingsService.settings,
      (error, stack) => StorageReadFailure(
        'app_settings',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> saveSettings(Settings settings) {
    return TaskEither.tryCatch(
      () async {
        await _settingsService.save(settings);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'app_settings',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> resetSettings() {
    return TaskEither.tryCatch(
      () async {
        await _settingsService.save(const Settings());
        return unit;
      },
      (error, stack) => StorageResetFailure(
        'Failed to reset settings: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Stream<Settings> watchSettings() => _settingsService.changes;
}

