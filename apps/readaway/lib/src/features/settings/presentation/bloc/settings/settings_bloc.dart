import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/services/logging_service.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../../reader/domain/repositories/reader_preferences_repository.dart';
import '../../../domain/entity/reader_preferences.dart';
import '../../../domain/entity/settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_model_repository.dart';

part 'settings_bloc.freezed.dart';
part 'settings_bloc.g.dart';
part 'settings_event.dart';
part 'settings_state.dart';

@lazySingleton
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ReaderPreferencesRepository preferencesRepository;
  final SettingsRepository settingsRepository;
  final TtsModelRepository ttsModelRepository;

  final _ttsDownloadSubs =
      <String, StreamSubscription<ModelDownloadProgress>>{};
  StreamSubscription<Settings>? _settingsSub;
  StreamSubscription<List<SherpaTtsModelInfo>>? _catalogSub;
  StreamSubscription<Set<String>>? _downloadedIdsSub;

  SettingsBloc({
    required this.preferencesRepository,
    required this.settingsRepository,
    required this.ttsModelRepository,
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
      transformer: restartable(),
    );
    on<_LoadDocumentPrefs>(_onLoadDocumentPrefs, transformer: droppable());
    on<_SetDocumentReaderPref>(
      _onSetDocumentReaderPref,
      transformer: restartable(),
    );
    on<_ClearDocumentPrefs>(_onClearDocumentPrefs, transformer: droppable());
    on<_ResetAllReaderPrefs>(_onResetAllReaderPrefs, transformer: droppable());
    on<_ImportReaderPrefs>(_onImportReaderPrefs, transformer: droppable());
    on<_UpdateAppSettings>(_onUpdateAppSettings, transformer: droppable());

    on<_RefreshTts>(_onRefreshTts, transformer: concurrent());
    on<_StartTtsDownload>(_onStartTtsDownload, transformer: concurrent());
    on<_CancelTtsDownload>(_onCancelTtsDownload);
    on<_PauseTtsDownload>(_onPauseTtsDownload);
    on<_ResumeTtsDownload>(_onResumeTtsDownload);
    on<_DeleteTtsModel>(_onDeleteTtsModel);
    on<_ActivateTts>(_onActivateTts, transformer: droppable());
    on<_PreviewTts>(_onPreviewTts, transformer: droppable());
    on<_TtsDownloadProgress>(_onTtsDownloadProgress);
    on<_TtsDownloadFailed>(_onTtsDownloadFailed);
    on<_TtsCatalogUpdated>((event, emit) {
      emit(state.copyWith(ttsAvailableModels: event.models));
    });
    on<_TtsDownloadedIdsUpdated>((event, emit) {
      emit(state.copyWith(ttsDownloadedIds: event.ids));
    });

    add(const SettingsEvent.loadPrefs());
    add(const SettingsEvent.refreshTts());

    _settingsSub = settingsRepository.watchSettings().listen((settings) {
      final voice = settings.globalViewSettings.ttsVoice;
      final modelId = voice != null && voice.contains('@')
          ? voice.split('@').first
          : voice;
      if (modelId != state.ttsActiveModelId && !isClosed) {
        add(const SettingsEvent.refreshTts());
      }
    });

    _catalogSub = ttsModelRepository.watchCatalog().listen((catalog) {
      if (!isClosed && catalog.isNotEmpty) {
        add(SettingsEvent.ttsCatalogUpdated(catalog));
      }
    });

    _downloadedIdsSub = ttsModelRepository.watchDownloadedModelIds().listen((ids) {
      if (!isClosed) {
        add(SettingsEvent.ttsDownloadedIdsUpdated(ids));
      }
    });
  }

  void _onSetGlobalReaderPref(
    _SetGlobalReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await preferencesRepository.saveGlobalPreferences(event.prefs);
    result.fold(
      (failure) => logger.e('Failed to set global prefs: $failure'),
      (_) {
        emit(state.copyWith(globalReaderPrefs: event.prefs));
        logger.d('Global reader prefs updated');
      },
    );
  }

  void _onResetAllReaderPrefs(
    _ResetAllReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    await preferencesRepository.resetAllPreferences();
    await settingsRepository.resetSettings();
    emit(
      const SettingsState(
        globalReaderPrefs: ReaderPreferences(),
        appSettings: Settings(),
      ),
    );
    logger.d('All reader prefs reset');
  }

  void _onLoadDocumentPrefs(
    _LoadDocumentPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await preferencesRepository.getDocumentPreferences(event.path);
    result.fold(
      (failure) => logger.e('Failed to load document prefs: $failure'),
      (loaded) {
        final map = Map<String, ReaderPreferences>.of(
          state.documentReaderPrefs,
        );
        // Only keep an entry when a real override exists; otherwise remove it
        // so the effective prefs fall back to the LIVE global prefs.
        if (loaded == null) {
          map.remove(event.path);
        } else {
          map[event.path] = loaded;
        }
        emit(state.copyWith(documentReaderPrefs: map));
        logger.d('Document reader prefs loaded for ${event.path}');
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
      (failure) => logger.e('Failed to set document prefs: $failure'),
      (_) {
        emit(
          state.copyWith(
            documentReaderPrefs: {
              ...state.documentReaderPrefs,
              event.path: event.prefs,
            },
          ),
        );
        logger.d('Document reader prefs updated for ${event.path}');
      },
    );
  }

  void _onClearDocumentPrefs(
    _ClearDocumentPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await preferencesRepository.clearDocumentPreferences(event.path);
    result.fold(
      (failure) => logger.e('Failed to clear document prefs: $failure'),
      (_) {
        final map = Map<String, ReaderPreferences>.of(
          state.documentReaderPrefs,
        );
        map.remove(event.path);
        emit(state.copyWith(documentReaderPrefs: map));
        logger.d('Document reader prefs cleared for ${event.path}');
      },
    );
  }

  void _onUpdateAppSettings(
    _UpdateAppSettings event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.saveSettings(event.settings);
    emit(state.copyWith(appSettings: event.settings));
    logger.d('App settings updated');
  }

  void _onImportReaderPrefs(
    _ImportReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final global = event.all['global'] ?? const ReaderPreferences();
    final result = await preferencesRepository.importGlobalPreferences(global);
    result.fold(
      (failure) => logger.e('Failed to import prefs: $failure'),
      (_) {
        emit(state.copyWith(globalReaderPrefs: global));
        logger.d('Reader prefs imported');
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

    emit(state.copyWith(globalReaderPrefs: prefs, appSettings: settings));
    logger.d('Settings loaded via event');
  }

  /// Dispatches [SettingsEvent.loadPrefs] to reload preferences.
  void loadPrefs() => add(const SettingsEvent.loadPrefs());

  SherpaTtsModelInfo? _ttsModelById(String id) {
    for (final m in ttsModelRepository.availableModels) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _onRefreshTts(_RefreshTts event, Emitter<SettingsState> emit) async {
    final catalogResult = await ttsModelRepository.getCatalog(
      forceRefresh: event.force,
    );

    await catalogResult.fold(
      (failure) async {
        if (state.ttsAvailableModels.isEmpty) {
          emit(state.copyWith(ttsError: 'Failed to load voice catalog'));
        }
      },
      (catalog) async {
        final downloadedResult =
            await ttsModelRepository.getDownloadedModelIds();
        final downloadedIds = downloadedResult.dataOrNull ?? <String>{};

        var activeModelId = ttsModelRepository.activeModelId;
        if (activeModelId == null) {
          final settingsResult = await settingsRepository.getSettings();
          final persisted = (settingsResult.dataOrNull ?? const Settings())
              .globalViewSettings
              .ttsVoice;
          final persistedModelId = persisted != null && persisted.contains('@')
              ? persisted.split('@').first
              : persisted;
          if (persistedModelId != null &&
              downloadedIds.contains(persistedModelId)) {
            final loadResult = await ttsModelRepository.activateModel(
              persistedModelId,
            );
            if (loadResult.isSuccess) {
              activeModelId = persistedModelId;
            }
          }
        }

        emit(
          state.copyWith(
            ttsAvailableModels: catalog,
            ttsDownloadedIds: downloadedIds,
            ttsActiveModelId: activeModelId,
            ttsError: null,
          ),
        );
      },
    );
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

    _ttsDownloadSubs[id] = ttsModelRepository
        .downloadModel(event.model)
        .listen(
          (progress) => add(
            _TtsDownloadProgress(
              progress.modelId,
              progress.stage,
              progress.fraction,
              speedBytesPerSec: progress.speedBytesPerSec,
              timeRemaining: progress.timeRemaining,
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
    unawaited(ttsModelRepository.cancelDownload(event.modelId));
    _removeTtsDownload(event.modelId, emit);
  }

  void _onPauseTtsDownload(
    _PauseTtsDownload event,
    Emitter<SettingsState> emit,
  ) {
    unawaited(ttsModelRepository.pauseDownload(event.modelId));
    _setTtsDownloadStage(event.modelId, ModelDownloadStage.paused, emit);
  }

  void _onResumeTtsDownload(
    _ResumeTtsDownload event,
    Emitter<SettingsState> emit,
  ) {
    unawaited(ttsModelRepository.resumeDownload(event.modelId));
    _setTtsDownloadStage(event.modelId, ModelDownloadStage.downloading, emit);
  }

  void _setTtsDownloadStage(
    String id,
    ModelDownloadStage stage,
    Emitter<SettingsState> emit,
  ) {
    final current = state.ttsDownloads[id];
    if (current == null) return;
    final downloads = Map<String, SettingsDownloadStatus>.of(
      state.ttsDownloads,
    );
    downloads[id] = SettingsDownloadStatus(
      stage: stage,
      fraction: current.fraction,
      speedBytesPerSec: current.speedBytesPerSec,
      timeRemaining: current.timeRemaining,
    );
    emit(state.copyWith(ttsDownloads: downloads));
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
      speedBytesPerSec: event.speedBytesPerSec,
      timeRemaining: event.timeRemaining,
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
    final result = await ttsModelRepository.deleteModel(id);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            ttsError: 'Failed to delete ${event.model.displayName}',
          ),
        );
      },
      (_) async {
        final settingsResult = await settingsRepository.getSettings();
        final current = settingsResult.dataOrNull ?? const Settings();
        final currentVoice = current.globalViewSettings.ttsVoice;
        final currentModelId = currentVoice != null && currentVoice.contains('@')
            ? currentVoice.split('@').first
            : currentVoice;
        if (currentModelId == id) {
          await settingsRepository.saveSettings(
            current.copyWith(
              globalViewSettings: current.globalViewSettings.copyWith(
                ttsVoice: null,
              ),
            ),
          );
        }
        final wasActive = state.ttsActiveModelId == id;
        emit(
          state.copyWith(
            ttsDownloadedIds: state.ttsDownloadedIds
                .where((e) => e != id)
                .toSet(),
            ttsActiveModelId: wasActive ? null : state.ttsActiveModelId,
          ),
        );
      },
    );
  }

  void _onActivateTts(_ActivateTts event, Emitter<SettingsState> emit) async {
    if (state.ttsBusyModelId != null) return;
    emit(state.copyWith(ttsBusyModelId: event.modelId, ttsError: null));

    final result = await ttsModelRepository.activateModel(event.modelId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            ttsError: failure.message,
            ttsBusyModelId: null,
          ),
        );
      },
      (_) async {
        await _persistActiveVoice(event.modelId);
        emit(
          state.copyWith(ttsActiveModelId: event.modelId, ttsBusyModelId: null),
        );
      },
    );
  }

  Future<void> _persistActiveVoice(String modelId) async {
    final settingsResult = await settingsRepository.getSettings();
    final current = settingsResult.dataOrNull ?? const Settings();
    if (current.globalViewSettings.ttsVoice == modelId) return;
    await settingsRepository.saveSettings(
      current.copyWith(
        globalViewSettings: current.globalViewSettings.copyWith(
          ttsVoice: modelId,
        ),
      ),
    );
  }

  void _onPreviewTts(_PreviewTts event, Emitter<SettingsState> emit) async {
    // If the currently playing preview is tapped, stop it
    if (state.ttsBusyModelId == event.modelId) {
      await ttsModelRepository.stopPreview();
      emit(state.copyWith(ttsBusyModelId: null));
      return;
    }

    // Stop any existing preview before starting the new one
    if (state.ttsBusyModelId != null) {
      await ttsModelRepository.stopPreview();
    }

    emit(state.copyWith(ttsBusyModelId: event.modelId, ttsError: null));

    final result = await ttsModelRepository.playPreview(event.modelId);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            ttsError: failure.message,
            ttsBusyModelId: null,
          ),
        );
      },
      (_) {
        if (state.ttsBusyModelId == event.modelId) {
          emit(state.copyWith(ttsBusyModelId: null));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _settingsSub?.cancel();
    _catalogSub?.cancel();
    _downloadedIdsSub?.cancel();
    for (final sub in _ttsDownloadSubs.values) {
      sub.cancel();
    }
    _ttsDownloadSubs.clear();
    return super.close();
  }
}
