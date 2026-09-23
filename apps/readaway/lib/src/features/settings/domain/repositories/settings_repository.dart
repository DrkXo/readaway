import '../../../../core/result/result.dart';
import '../entity/settings.dart';

/// Contract for general application settings, window preferences, and theme state.
abstract interface class SettingsRepository {
  /// Fetches current application settings.
  Future<Result<Settings>> getSettings();

  /// Saves updated application settings.
  Future<Result<void>> saveSettings(Settings settings);

  /// Resets application settings to factory defaults.
  Future<Result<void>> resetSettings();

  /// Stream of settings changes over time.
  Stream<Settings> watchSettings();
}
