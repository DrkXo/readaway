import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/services.dart';
import '../../domain/models/reader_preferences.dart';

part 'settings_bloc.freezed.dart';
part 'settings_bloc.g.dart';
part 'settings_event.dart';
part 'settings_state.dart';

@Singleton()
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AppStorageService _storage;

  SettingsBloc({
    required this._storage,
  }) : super(
         const SettingsState(
           globalReaderPrefs: ReaderPreferences(),
           documentReaderPrefs: {},
         ),
       ) {
    on<_SetGlobalReaderPref>(_onSetGlobalReaderPref, transformer: droppable());
    on<_SetDocumentReaderPref>(
      _onSetDocumentReaderPref,
      transformer: droppable(),
    );
    on<_ResetDocumentReaderPref>(
      _onResetDocumentReaderPref,
      transformer: droppable(),
    );
    on<_ResetAllReaderPrefs>(_onResetAllReaderPrefs, transformer: droppable());
    on<_ImportReaderPrefs>(_onImportReaderPrefs, transformer: droppable());
  }

  static SettingsBloc get settingsBloc => GetIt.I.get<SettingsBloc>();

  void _onSetGlobalReaderPref(
    _SetGlobalReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.writeReaderGlobalPrefs(event.prefs);
      emit(state.copyWith(globalReaderPrefs: event.prefs));
      logger.d('Global reader prefs updated');
    } catch (e) {
      logger.e('Failed to set global prefs: $e');
    }
  }

  void _onSetDocumentReaderPref(
    _SetDocumentReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.writeReaderDocumentPrefs(event.path, event.prefs);
      final docs = Map<String, ReaderPreferences>.from(
        state.documentReaderPrefs,
      );
      docs[event.path] = event.prefs;
      emit(state.copyWith(documentReaderPrefs: docs));
      logger.d('Document prefs updated for ${event.path}');
    } catch (e) {
      logger.e('Failed to set document prefs: $e');
    }
  }

  void _onResetDocumentReaderPref(
    _ResetDocumentReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.deleteReaderDocumentPrefs(event.path);
      final docs = Map<String, ReaderPreferences>.from(
        state.documentReaderPrefs,
      );
      docs.remove(event.path);
      emit(state.copyWith(documentReaderPrefs: docs));
      logger.d('Document prefs reset for ${event.path}');
    } catch (e) {
      logger.e('Failed to reset document prefs: $e');
    }
  }

  void _onResetAllReaderPrefs(
    _ResetAllReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.resetStorage();
      emit(
        const SettingsState(
          globalReaderPrefs: ReaderPreferences(),
          documentReaderPrefs: {},
        ),
      );
      logger.d('All reader prefs reset');
    } catch (e) {
      logger.e('Failed to reset all prefs: $e');
    }
  }

  void _onImportReaderPrefs(
    _ImportReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.writeReaderGlobalPrefs(
        event.all['global'] ?? const ReaderPreferences(),
      );
      final docs = Map<String, ReaderPreferences>.from(event.all);
      docs.remove('global');
      for (final entry in docs.entries) {
        await _storage.writeReaderDocumentPrefs(entry.key, entry.value);
      }
      emit(
        state.copyWith(
          globalReaderPrefs: event.all['global'] ?? const ReaderPreferences(),
          documentReaderPrefs: docs,
        ),
      );
      logger.d('Reader prefs imported');
    } catch (e) {
      logger.e('Failed to import prefs: $e');
    }
  }

  Future<void> loadPrefs() async {
    try {
      final global =
          _storage.readReaderGlobalPrefs() ?? const ReaderPreferences();
      final docs = await _storage.readAllReaderDocumentPrefs();
      // ignore: invalid_use_of_visible_for_testing_member
      emit(
        state.copyWith(globalReaderPrefs: global, documentReaderPrefs: docs),
      );
      logger.d('Reader prefs loaded');
    } catch (e) {
      logger.e('Failed to load prefs: $e');
    }
  }

  void updateActiveDocumentPath(String? path) {
    if (state.activeDocumentPath != path) {
      // ignore: invalid_use_of_visible_for_testing_member
      emit(state.copyWith(activeDocumentPath: path));
    }
  }
}

extension SettingsStateX on SettingsState {
  ReaderPreferences resolvedReaderPrefs(String? documentPath) {
    if (documentPath != null && documentReaderPrefs.containsKey(documentPath)) {
      return documentReaderPrefs[documentPath]!;
    }
    return globalReaderPrefs;
  }
}
