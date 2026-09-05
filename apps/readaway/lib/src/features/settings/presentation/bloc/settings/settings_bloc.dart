import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../../reader/domain/repositories/reader_preferences_repository.dart';
import '../../../domain/entity/reader_preferences.dart';
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
    // `restartable` (not `droppable`) so rapid slider drags always land on the
    // final value: each new event cancels the previous in-flight handler.
    on<_SetGlobalReaderPref>(
      _onSetGlobalReaderPref,
      transformer: restartable(),
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

  void _onSetGlobalReaderPref(
    _SetGlobalReaderPref event,
    Emitter<SettingsState> emit,
  ) async {
    final result =
        await preferencesRepository.saveGlobalPreferences(event.prefs).run();
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
    await preferencesRepository.resetAllPreferences().run();
    await settingsRepository.resetSettings().run();
    emit(
      const SettingsState(
        globalReaderPrefs: ReaderPreferences(),
        appSettings: Settings(),
      ),
    );
    logger.d('All reader prefs reset');
  }

  void _onUpdateAppSettings(
    _UpdateAppSettings event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.saveSettings(event.settings).run();
    emit(state.copyWith(appSettings: event.settings));
    logger.d('App settings updated');
  }

  void _onImportReaderPrefs(
    _ImportReaderPrefs event,
    Emitter<SettingsState> emit,
  ) async {
    final global = event.all['global'] ?? const ReaderPreferences();
    final result =
        await preferencesRepository.importGlobalPreferences(global).run();
    result.fold(
      (failure) => logger.e('Failed to import prefs: $failure'),
      (_) {
        emit(state.copyWith(globalReaderPrefs: global));
        logger.d('Reader prefs imported');
      },
    );
  }

  Future<void> loadPrefs() async {
    final prefsResult =
        await preferencesRepository.getGlobalPreferences().run();
    final settingsResult = await settingsRepository.getSettings().run();

    final prefs = prefsResult.getOrElse((_) => state.globalReaderPrefs);
    final settings = settingsResult.getOrElse((_) => state.appSettings);

    // ignore: invalid_use_of_visible_for_testing_member
    emit(state.copyWith(globalReaderPrefs: prefs, appSettings: settings));
    logger.d('Settings loaded');
  }

  SherpaTtsModelInfo? _ttsModelById(String id) {
    for (final m in ttsModelRepository.availableModels) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _onRefreshTts(_RefreshTts event, Emitter<SettingsState> emit) async {
    final downloadedResult =
        await ttsModelRepository.getDownloadedModelIds().run();

    await downloadedResult.fold(
      (failure) async {
        emit(state.copyWith(ttsError: 'Failed to load voice catalog'));
      },
      (downloadedIds) async {
        var activeModelId = ttsModelRepository.activeModelId;
        if (activeModelId == null) {
          final settingsResult = await settingsRepository.getSettings().run();
          final persisted = settingsResult
              .getOrElse((_) => const Settings())
              .globalViewSettings
              .ttsVoice;
          if (persisted != null && downloadedIds.contains(persisted)) {
            final loadResult =
                await ttsModelRepository.activateModel(persisted).run();
            if (loadResult.isRight()) {
              activeModelId = persisted;
            }
          }
        }

        emit(
          state.copyWith(
            ttsAvailableModels: ttsModelRepository.availableModels,
            ttsDownloadedIds: downloadedIds,
            ttsActiveModelId: activeModelId,
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
    final result = await ttsModelRepository.deleteModel(id).run();
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            ttsError: 'Failed to delete ${event.model.displayName}',
          ),
        );
      },
      (_) async {
        final wasActive = state.ttsActiveModelId == id;
        if (wasActive) {
          final settingsResult = await settingsRepository.getSettings().run();
          final current = settingsResult.getOrElse((_) => const Settings());
          if (current.globalViewSettings.ttsVoice == id) {
            await settingsRepository
                .saveSettings(
                  current.copyWith(
                    globalViewSettings: current.globalViewSettings.copyWith(
                      ttsVoice: null,
                    ),
                  ),
                )
                .run();
          }
        }
        emit(
          state.copyWith(
            ttsDownloadedIds:
                state.ttsDownloadedIds.where((e) => e != id).toSet(),
            ttsActiveModelId: wasActive ? null : state.ttsActiveModelId,
          ),
        );
      },
    );
  }

  void _onActivateTts(_ActivateTts event, Emitter<SettingsState> emit) async {
    if (state.ttsBusyModelId != null) return;
    emit(state.copyWith(ttsBusyModelId: event.modelId, ttsError: null));

    final result = await ttsModelRepository.activateModel(event.modelId).run();
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
    final settingsResult = await settingsRepository.getSettings().run();
    final current = settingsResult.getOrElse((_) => const Settings());
    if (current.globalViewSettings.ttsVoice == modelId) return;
    await settingsRepository
        .saveSettings(
          current.copyWith(
            globalViewSettings: current.globalViewSettings.copyWith(
              ttsVoice: modelId,
            ),
          ),
        )
        .run();
  }

  void _onPreviewTts(_PreviewTts event, Emitter<SettingsState> emit) async {
    if (state.ttsBusyModelId != null) return;
    emit(state.copyWith(ttsBusyModelId: event.modelId, ttsError: null));

    final result = await ttsModelRepository.playPreview(event.modelId).run();
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
        emit(state.copyWith(ttsBusyModelId: null));
      },
    );
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
