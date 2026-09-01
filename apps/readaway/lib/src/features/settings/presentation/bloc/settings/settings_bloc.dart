import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/services/services.dart';
import '../../../domain/models/reader_preferences.dart';

part 'settings_bloc.freezed.dart';
part 'settings_bloc.g.dart';
part 'settings_event.dart';
part 'settings_state.dart';

@Injectable()
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AppStorageService _storage;
  final SettingsService _settingsService;
  final SherpaOnnxTtsService _ttsService;
  final JustAudioService _audio;

  final _ttsDownloadSubs =
      <String, StreamSubscription<ModelDownloadProgress>>{};

  SettingsBloc({
    required this._storage,
    required this._settingsService,
    required this._ttsService,
    required this._audio,
  }) : super(
         SettingsState(
           globalReaderPrefs: ReaderPreferences(),
           documentReaderPrefs: {},
           appSettings: _settingsService.settings,
         ),
       ) {
    // `restartable` (not `droppable`) so rapid slider drags always land on the
    // final value: each new event cancels the previous in-flight handler.
    on<_SetGlobalReaderPref>(
      _onSetGlobalReaderPref,
      transformer: restartable(),
    );
    on<_SetDocumentReaderPref>(
      _onSetDocumentReaderPref,
      transformer: restartable(),
    );
    on<_ResetDocumentReaderPref>(
      _onResetDocumentReaderPref,
      transformer: droppable(),
    );
    on<_ResetAllReaderPrefs>(_onResetAllReaderPrefs, transformer: droppable());
    on<_ImportReaderPrefs>(_onImportReaderPrefs, transformer: droppable());
    on<_UpdateAppSettings>(_onUpdateAppSettings, transformer: droppable());

    on<_RefreshTts>(_onRefreshTts, transformer: concurrent());
    on<_StartTtsDownload>(_onStartTtsDownload, transformer: concurrent());
    on<_CancelTtsDownload>(_onCancelTtsDownload);
    on<_DeleteTtsModel>(_onDeleteTtsModel);
    on<_ActivateTts>(_onActivateTts, transformer: droppable());
    on<_PreviewTts>(_onPreviewTts, transformer: droppable());
    on<_TtsDownloadProgress>(_onTtsDownloadProgress);
    on<_TtsDownloadFailed>(_onTtsDownloadFailed);

    add(const _RefreshTts());
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
      await _settingsService.save(const Settings());
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

  void _onUpdateAppSettings(
    _UpdateAppSettings event,
    Emitter<SettingsState> emit,
  ) {
    _settingsService.scheduleSave(event.settings);
    emit(state.copyWith(appSettings: event.settings));
    logger.d('App settings updated');
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
      final global = await _storage.readReaderGlobalPrefs();
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

  SherpaTtsModelInfo? _ttsModelById(String id) {
    for (final m in _ttsService.availableModels) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _onRefreshTts(_RefreshTts event, Emitter<SettingsState> emit) async {
    try {
      final downloaded = await _ttsService.getDownloadedModels();
      final downloadedIds = downloaded.map((m) => m.id).toSet();

      var activeModelId = _ttsService.activeModel?.id;
      if (activeModelId == null) {
        final persisted = _settingsService.settings.globalViewSettings.ttsVoice;
        if (persisted != null && downloadedIds.contains(persisted)) {
          try {
            await _ttsService.loadModel(persisted);
            activeModelId = persisted;
          } on SherpaTtsException {
            // Model files present but failed to load — fall through
          }
        }
      }

      emit(
        state.copyWith(
          ttsAvailableModels: _ttsService.availableModels,
          ttsDownloadedIds: downloadedIds,
          ttsActiveModelId: activeModelId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(ttsError: 'Failed to load voice catalog'));
    }
  }

  void _onStartTtsDownload(
    _StartTtsDownload event,
    Emitter<SettingsState> emit,
  ) {
    final id = event.model.id;
    if (_ttsDownloadSubs.containsKey(id)) return;

    emit(
      state.copyWith(
        ttsError: null,
        ttsDownloads: {
          ...state.ttsDownloads,
          id: const SettingsDownloadStatus(
            stage: ModelDownloadStage.downloading,
          ),
        },
      ),
    );

    _ttsDownloadSubs[id] = _ttsService
        .downloadModel(event.model)
        .listen(
          (progress) => add(
            _TtsDownloadProgress(
              progress.modelId,
              progress.stage,
              progress.fraction,
            ),
          ),
          onError: (Object e) => add(_TtsDownloadFailed(id, e.toString())),
          cancelOnError: true,
        );
  }

  void _onCancelTtsDownload(
    _CancelTtsDownload event,
    Emitter<SettingsState> emit,
  ) {
    _ttsDownloadSubs.remove(event.modelId)?.cancel();
    _removeTtsDownload(event.modelId, emit);
  }

  void _onTtsDownloadProgress(
    _TtsDownloadProgress event,
    Emitter<SettingsState> emit,
  ) {
    if (event.stage == ModelDownloadStage.done) {
      _ttsDownloadSubs.remove(event.modelId)?.cancel();
      _finishTtsDownload(event.modelId, emit);
      return;
    }
    if (event.stage == ModelDownloadStage.failed) {
      _removeTtsDownload(event.modelId, emit);
      return;
    }
    if (!state.ttsDownloads.containsKey(event.modelId)) return;

    final downloads = Map<String, SettingsDownloadStatus>.of(
      state.ttsDownloads,
    );
    downloads[event.modelId] = SettingsDownloadStatus(
      stage: event.stage,
      fraction: event.fraction,
    );
    emit(state.copyWith(ttsDownloads: downloads));
  }

  void _onTtsDownloadFailed(
    _TtsDownloadFailed event,
    Emitter<SettingsState> emit,
  ) {
    if (_ttsDownloadSubs.remove(event.modelId) != null ||
        state.ttsDownloads.containsKey(event.modelId)) {
      final name = _ttsModelById(event.modelId)?.displayName ?? 'voice';
      final downloads = Map<String, SettingsDownloadStatus>.of(
        state.ttsDownloads,
      )..remove(event.modelId);
      emit(
        state.copyWith(
          ttsError: 'Failed to download $name: ${event.error}',
          ttsDownloads: downloads,
        ),
      );
    }
  }

  void _removeTtsDownload(String id, Emitter<SettingsState> emit) {
    if (!state.ttsDownloads.containsKey(id)) return;
    final downloads = Map<String, SettingsDownloadStatus>.of(state.ttsDownloads)
      ..remove(id);
    emit(state.copyWith(ttsDownloads: downloads));
  }

  void _finishTtsDownload(String id, Emitter<SettingsState> emit) {
    final downloads = Map<String, SettingsDownloadStatus>.of(state.ttsDownloads)
      ..remove(id);
    emit(
      state.copyWith(
        ttsDownloads: downloads,
        ttsDownloadedIds: {...state.ttsDownloadedIds, id},
      ),
    );
  }

  void _onDeleteTtsModel(
    _DeleteTtsModel event,
    Emitter<SettingsState> emit,
  ) async {
    final id = event.model.id;
    try {
      await _ttsService.deleteModel(id);
      final wasActive = state.ttsActiveModelId == id;
      if (wasActive) {
        final current = _settingsService.settings;
        if (current.globalViewSettings.ttsVoice == id) {
          _settingsService.scheduleSave(
            current.copyWith(
              globalViewSettings: current.globalViewSettings.copyWith(
                ttsVoice: null,
              ),
            ),
          );
        }
      }
      emit(
        state.copyWith(
          ttsDownloadedIds: state.ttsDownloadedIds
              .where((e) => e != id)
              .toSet(),
          ttsActiveModelId: wasActive ? null : state.ttsActiveModelId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(ttsError: 'Failed to delete ${event.model.displayName}'),
      );
    }
  }

  void _onActivateTts(_ActivateTts event, Emitter<SettingsState> emit) async {
    if (state.ttsBusyModelId != null) return;
    emit(state.copyWith(ttsBusyModelId: event.modelId, ttsError: null));
    try {
      if (_ttsService.activeModel?.id != event.modelId) {
        await _ttsService.loadModel(event.modelId);
      }
      _persistActiveVoice(event.modelId);
      emit(
        state.copyWith(ttsActiveModelId: event.modelId, ttsBusyModelId: null),
      );
    } on SherpaTtsException catch (e) {
      emit(state.copyWith(ttsError: e.message, ttsBusyModelId: null));
    } catch (_) {
      emit(
        state.copyWith(
          ttsError: 'Failed to activate voice',
          ttsBusyModelId: null,
        ),
      );
    }
  }

  void _persistActiveVoice(String modelId) {
    final current = _settingsService.settings;
    if (current.globalViewSettings.ttsVoice == modelId) return;
    _settingsService.scheduleSave(
      current.copyWith(
        globalViewSettings: current.globalViewSettings.copyWith(
          ttsVoice: modelId,
        ),
      ),
    );
  }

  void _onPreviewTts(_PreviewTts event, Emitter<SettingsState> emit) async {
    if (state.ttsBusyModelId != null) return;
    final previousActive = state.ttsActiveModelId;
    emit(state.copyWith(ttsBusyModelId: event.modelId, ttsError: null));

    try {
      if (_ttsService.activeModel?.id != event.modelId) {
        await _ttsService.loadModel(event.modelId);
      }

      final pcmAudio = await _ttsService.generate(
        text: 'Hello. This is what this voice sounds like while reading.',
        speakerId: 0,
        speed: 1.0,
      );

      await _audio.playPreview(pcmAudio);

      if (previousActive != null && previousActive != event.modelId) {
        await _ttsService.loadModel(previousActive);
      }

      emit(state.copyWith(ttsBusyModelId: null));
    } on SherpaTtsException catch (e) {
      emit(state.copyWith(ttsError: e.message, ttsBusyModelId: null));
    } catch (_) {
      emit(
        state.copyWith(
          ttsError: 'Failed to preview voice',
          ttsBusyModelId: null,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    for (final sub in _ttsDownloadSubs.values) {
      sub.cancel();
    }
    _ttsDownloadSubs.clear();
    return super.close();
  }
}
