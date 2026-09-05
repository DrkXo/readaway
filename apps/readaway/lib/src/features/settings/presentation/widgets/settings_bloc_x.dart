import '../../domain/entity/reader_preferences.dart';
import '../bloc/settings/settings_bloc.dart';

/// Extension on [SettingsBloc] for reader-preference updates.
extension SettingsBlocX on SettingsBloc {
  /// Dispatches a reader-preference update directly to global preferences.
  void updateReaderPrefs(
    ReaderPreferences Function(ReaderPreferences) update,
  ) {
    add(SettingsEvent.setGlobalReaderPref(update(state.globalReaderPrefs)));
  }
}
