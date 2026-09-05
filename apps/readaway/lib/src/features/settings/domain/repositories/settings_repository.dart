import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';

/// Contract for general application settings, window preferences, and theme state.
abstract interface class SettingsRepository {
  /// Fetches current application settings.
  TaskEither<Failure, Settings> getSettings();

  /// Saves updated application settings.
  TaskEither<Failure, Unit> saveSettings(Settings settings);

  /// Resets application settings to factory defaults.
  TaskEither<Failure, Unit> resetSettings();

  /// Stream of settings changes over time.
  Stream<Settings> watchSettings();
}

