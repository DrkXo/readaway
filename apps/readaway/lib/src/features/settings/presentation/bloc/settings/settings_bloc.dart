import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/error/failures.dart';
import '../../../../reader/domain/repositories/reader_preferences_repository.dart';
import '../../../domain/entity/reader_preferences.dart';
import '../../../domain/entity/settings.dart';
import '../../../domain/repositories/settings_repository.dart';

part 'settings_bloc.freezed.dart';
part 'settings_bloc.g.dart';
part 'settings_event.dart';
part 'settings_state.dart';

@lazySingleton
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final _log = AppLogger.instance.scope('SettingsBloc');

  final ReaderPreferencesRepository preferencesRepository;
  final SettingsRepository settingsRepository;
  final Map<String, int> _documentLoadVersions = {};

  SettingsBloc({
    required this.preferencesRepository,
    required this.settingsRepository,
  }) : super(
         const SettingsState(
           globalReaderPrefs: ReaderPreferences(),
           appSettings: Settings(),
         ),
       ) {
    on<_LoadPrefs>(_onLoadPrefs, transformer: droppable());
    // `restartable` (not `droppable`) so rapid slider drags always land on the
    // final value: each new event cancels the previous in-flight handler.
    on<_SetGlobalReaderPref>(
      _onSetGlobalReaderPref,
      transformer: sequential(),
    );
    on<_LoadDocumentPrefs>(_onLoadDocumentPrefs, transformer: concurrent());
    on<_SetDocumentReaderPref>(
      _onSetDocumentReaderPref,
      transformer: sequential(),
    );
    on<_ClearDocumentPrefs>(
      _onClearDocumentPrefs,
      transformer: sequential(),
    );
    on<_ResetAllReaderPrefs>(_onResetAllReaderPrefs, transformer: droppable());
    on<_ImportReaderPrefs>(_onImportReaderPrefs, transformer: droppable());
    on<_UpdateAppSettings>(_onUpdateAppSettings, transformer: sequential());

    add(const SettingsEvent.loadPrefs());
  }

  void _onSetGlobalReaderPref(
    _SetGlobalReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await preferencesRepository.saveGlobalPreferences(
      event.prefs,
    );
    result.fold(
      (failure) {
        _log.e('Failed to set global prefs: $failure');
        emit(state.copyWith(failure: failure));
      },
      (_) {
        emit(state.copyWith(globalReaderPrefs: event.prefs, failure: null));
        _log.d('Global reader prefs updated');
      },
    );
  }

  void _onResetAllReaderPrefs(
    _ResetAllReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final prefsResult = await preferencesRepository.resetAllPreferences();
    if (prefsResult.isFailure) {
      _log.e('Failed to reset reader prefs: ${prefsResult.failureOrNull}');
      emit(state.copyWith(failure: prefsResult.failureOrNull));
      return;
    }
    final settingsResult = await settingsRepository.resetSettings();
    if (settingsResult.isFailure) {
      _log.e('Failed to reset app settings: ${settingsResult.failureOrNull}');
      emit(state.copyWith(failure: settingsResult.failureOrNull));
      return;
    }
    emit(
      const SettingsState(
        globalReaderPrefs: ReaderPreferences(),
        appSettings: Settings(),
      ),
    );
    _log.d('All reader prefs reset');
  }

  void _onLoadDocumentPrefs(
    _LoadDocumentPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final loadVersion = (_documentLoadVersions[event.path] ?? 0) + 1;
    _documentLoadVersions[event.path] = loadVersion;
    final result = await preferencesRepository.getDocumentPreferences(
      event.path,
    );
    result.fold(
      (failure) {
        if (_documentLoadVersions[event.path] != loadVersion || emit.isDone) {
          return;
        }
        _log.e('Failed to load document prefs: $failure');
        emit(
          state.copyWith(
            failure: failure,
            loadedDocumentPaths: {...state.loadedDocumentPaths, event.path},
          ),
        );
      },
      (loaded) {
        if (_documentLoadVersions[event.path] != loadVersion || emit.isDone) {
          return;
        }
        final map = Map<String, ReaderPreferences>.of(
          state.documentReaderPrefs,
        );
        if (loaded == null) {
          map.remove(event.path);
        } else {
          map[event.path] = loaded;
        }
        emit(
          state.copyWith(
            documentReaderPrefs: map,
            loadedDocumentPaths: {...state.loadedDocumentPaths, event.path},
            failure: null,
          ),
        );
        _log.d('Document reader prefs loaded for ${event.path}');
      },
    );
  }

  void _onSetDocumentReaderPref(
    _SetDocumentReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await preferencesRepository.saveDocumentPreferences(
      event.path,
      event.prefs,
    );
    result.fold(
      (failure) {
        _log.e('Failed to set document prefs: $failure');
        emit(state.copyWith(failure: failure));
      },
      (_) {
        emit(
          state.copyWith(
            documentReaderPrefs: {
              ...state.documentReaderPrefs,
              event.path: event.prefs,
            },
            loadedDocumentPaths: {...state.loadedDocumentPaths, event.path},
            failure: null,
          ),
        );
        _log.d('Document reader prefs updated for ${event.path}');
      },
    );
  }

  void _onClearDocumentPrefs(
    _ClearDocumentPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await preferencesRepository.clearDocumentPreferences(
      event.path,
    );
    result.fold(
      (failure) {
        _log.e('Failed to clear document prefs: $failure');
        emit(state.copyWith(failure: failure));
      },
      (_) {
        final map = Map<String, ReaderPreferences>.of(
          state.documentReaderPrefs,
        );
        map.remove(event.path);
        emit(state.copyWith(documentReaderPrefs: map, failure: null));
        _log.d('Document reader prefs cleared for ${event.path}');
      },
    );
  }

  void _onImportReaderPrefs(
    _ImportReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final global = event.all['global'] ?? const ReaderPreferences();
    final result = await preferencesRepository.importGlobalPreferences(global);
    result.fold(
      (failure) {
        _log.e('Failed to import prefs: $failure');
        emit(state.copyWith(failure: failure));
      },
      (_) {
        emit(state.copyWith(globalReaderPrefs: global, failure: null));
        _log.d('Reader prefs imported');
      },
    );
  }

  void _onUpdateAppSettings(
    _UpdateAppSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await settingsRepository.saveSettings(event.settings);
    result.fold(
      (failure) {
        _log.e('Failed to update app settings: $failure');
        emit(state.copyWith(failure: failure));
      },
      (_) {
        emit(state.copyWith(appSettings: event.settings, failure: null));
        _log.d('App settings updated');
      },
    );
  }

  void _onLoadPrefs(
    _LoadPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final prefsResult = await preferencesRepository.getGlobalPreferences();
    final settingsResult = await settingsRepository.getSettings();

    final prefs = prefsResult.dataOrNull ?? state.globalReaderPrefs;
    final settings = settingsResult.dataOrNull ?? state.appSettings;
    final failure = prefsResult.failureOrNull ?? settingsResult.failureOrNull;

    emit(
      state.copyWith(
        globalReaderPrefs: prefs,
        appSettings: settings,
        failure: failure,
      ),
    );
    _log.d('Settings loaded via event');
  }
}
