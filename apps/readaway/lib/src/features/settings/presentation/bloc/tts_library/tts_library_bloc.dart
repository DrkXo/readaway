import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/services/tts/importer/custom_tts_model_importer_service.dart';
import '../../../../../core/services/tts/sherpa/tts_download_manager.dart';
import '../../../../../core/services/tts/tts_download_task.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../domain/entity/settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_model_repository.dart';

part 'tts_library_bloc.freezed.dart';
part 'tts_library_event.dart';
part 'tts_library_state.dart';

/// Owns the TTS voice-library state: the catalog, installed voices (streamed
/// from the Hive-backed store — the single source of truth for "downloaded"),
/// the active voice, and live download tasks replayed from the
/// [TtsDownloadManager] snapshot stream.
///
/// The download manager is the only writer of installed state. This bloc
/// mirrors its snapshots into state and exposes the user actions (download,
/// pause, resume, cancel, activate, preview, delete, import, check-updates)
/// that drive the manager and the repository.
@lazySingleton
class TtsLibraryBloc extends Bloc<TtsLibraryEvent, TtsLibraryState> {
  final TtsModelRepository ttsModelRepository;
  final SettingsRepository settingsRepository;
  final TtsDownloadManager downloadManager;

  StreamSubscription<Settings>? _settingsSub;
  StreamSubscription<List<SherpaTtsModelInfo>>? _catalogSub;
  StreamSubscription<List<SherpaTtsModelInfo>>? _installedModelsSub;
  StreamSubscription<Map<String, TtsDownloadTask>>? _downloadsSub;

  TtsLibraryBloc({
    required this.ttsModelRepository,
    required this.settingsRepository,
    required this.downloadManager,
  }) : super(const TtsLibraryState()) {
    on<_RefreshCatalog>(_onRefreshCatalog, transformer: concurrent());
    on<_CheckForUpdates>(_onCheckForUpdates, transformer: droppable());
    on<_StartDownload>(_onStartDownload, transformer: concurrent());
    on<_PauseDownload>(_onPauseDownload);
    on<_ResumeDownload>(_onResumeDownload);
    on<_ResumeInterrupted>(_onResumeInterrupted);
    on<_CancelDownload>(_onCancelDownload);
    on<_DeleteModel>(_onDeleteModel);
    on<_Activate>(_onActivate, transformer: droppable());
    // `concurrent()` (not `droppable()`) so a tap on the busy row actually
    // stops the sample: `playPreview` awaits synthesis *and* full playback, so
    // a dropped event would leave the Stop button dead until the sample ends.
    // The handler re-checks `busyModelId` on completion, so a superseded
    // playback cannot clear the busy flag of the one that replaced it.
    on<_Preview>(_onPreview, transformer: concurrent());
    on<_ImportCustomModel>(_onImportCustomModel, transformer: droppable());
    on<_CatalogUpdated>((event, emit) {
      emit(state.copyWith(availableModels: event.models));
    });
    on<_InstalledModelsUpdated>((event, emit) {
      // Reconcile the active voice: if it vanished from the store (deleted
      // elsewhere), drop it from state.
      var activeModelId = state.activeModelId;
      if (activeModelId != null &&
          !event.models.any((m) => m.id == activeModelId)) {
        activeModelId = null;
      }
      emit(
        state.copyWith(
          installedModels: event.models,
          activeModelId: activeModelId,
        ),
      );
    });
    on<_DownloadsUpdated>((event, emit) {
      emit(state.copyWith(downloads: event.tasks));
    });

    // Cold-start reconcile: catalog + installed list + persisted active voice
    // (mirrors the old SettingsBloc boot refresh, minus any disk scan).
    add(const TtsLibraryEvent.refreshCatalog());

    _settingsSub = settingsRepository.watchSettings().listen((settings) {
      final voice = settings.globalViewSettings.ttsVoice;
      final modelId = voice != null && voice.contains('@')
          ? voice.split('@').first
          : voice;
      if (modelId != state.activeModelId && !isClosed) {
        add(const TtsLibraryEvent.refreshCatalog());
      }
    });

    _catalogSub = ttsModelRepository.watchCatalog().listen((catalog) {
      if (!isClosed && catalog.isNotEmpty) {
        add(_CatalogUpdated(catalog));
      }
    });

    _installedModelsSub = ttsModelRepository.watchInstalledModels().listen((
      installed,
    ) {
      if (!isClosed) {
        add(_InstalledModelsUpdated(installed));
      }
    });

    _downloadsSub = downloadManager.snapshots.listen((tasks) {
      if (!isClosed) {
        add(_DownloadsUpdated(tasks));
      }
    });
  }

  void _onRefreshCatalog(
    _RefreshCatalog event,
    Emitter<TtsLibraryState> emit,
  ) async {
    final catalogResult = await ttsModelRepository.getCatalog(
      forceRefresh: event.force,
    );

    await catalogResult.fold(
      (failure) async {
        if (state.availableModels.isEmpty) {
          emit(state.copyWith(error: 'Failed to load voice catalog'));
        }
      },
      (catalog) async {
        // Installed/downloaded state streams in from the Hive-backed
        // `watchInstalledModels()` subscription — no boot-time disk scan here.
        // Fall back to a single cheap Hive read only on cold start, before
        // the stream's first emission has been processed.
        var installedModels = state.installedModels;
        if (installedModels.isEmpty) {
          final installedResult = await ttsModelRepository.getInstalledModels();
          installedModels = installedResult.dataOrNull ?? const [];
        }

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
              installedModels.any((m) => m.id == persistedModelId)) {
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
            availableModels: catalog,
            installedModels: installedModels,
            activeModelId: activeModelId,
            error: null,
          ),
        );
      },
    );
  }

  void _onCheckForUpdates(
    _CheckForUpdates event,
    Emitter<TtsLibraryState> emit,
  ) async {
    emit(state.copyWith(isCheckingUpdates: true, updateNotification: null));
    final result = await ttsModelRepository.checkForCatalogUpdates();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isCheckingUpdates: false,
            error: 'Failed to check for updates: ${failure.message}',
          ),
        );
      },
      (syncResult) {
        final String message;
        if (syncResult.newModelsCount > 0 ||
            syncResult.updatedModelsCount > 0) {
          message =
              'Catalog updated: ${syncResult.newModelsCount} new voice(s), '
              '${syncResult.updatedModelsCount} updated';
        } else {
          message = 'All voices are up to date';
        }
        emit(
          state.copyWith(
            isCheckingUpdates: false,
            availableModels: ttsModelRepository.availableModels,
            updateNotification: message,
            error: null,
          ),
        );
      },
    );
  }

  void _onStartDownload(
    _StartDownload event,
    Emitter<TtsLibraryState> emit,
  ) {
    emit(state.copyWith(error: null));
    // Idempotent: an existing queued/running/interrupted task is returned
    // untouched. Status flows back through the manager snapshot stream.
    downloadManager.start(event.model);
  }

  void _onPauseDownload(
    _PauseDownload event,
    Emitter<TtsLibraryState> emit,
  ) {
    unawaited(downloadManager.pause(event.modelId));
  }

  void _onResumeDownload(
    _ResumeDownload event,
    Emitter<TtsLibraryState> emit,
  ) {
    unawaited(downloadManager.resume(event.modelId));
  }

  /// First-class manual "Resume interrupted": re-attaches every parked
  /// interrupted task. Interrupted downloads are never auto-rescheduled.
  void _onResumeInterrupted(
    _ResumeInterrupted event,
    Emitter<TtsLibraryState> emit,
  ) {
    final interrupted = state.downloads.values
        .where((t) => t.phase == TtsDownloadPhase.interrupted)
        .map((t) => t.modelId)
        .toList();
    if (interrupted.isEmpty) return;
    emit(state.copyWith(error: null));
    for (final id in interrupted) {
      unawaited(downloadManager.resume(id));
    }
  }

  void _onCancelDownload(
    _CancelDownload event,
    Emitter<TtsLibraryState> emit,
  ) {
    unawaited(downloadManager.cancel(event.modelId));
  }

  void _onDeleteModel(
    _DeleteModel event,
    Emitter<TtsLibraryState> emit,
  ) async {
    final id = event.model.id;
    final result = await ttsModelRepository.deleteModel(id);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            error: 'Failed to delete ${event.model.displayName}',
          ),
        );
      },
      (_) async {
        final settingsResult = await settingsRepository.getSettings();
        final current = settingsResult.dataOrNull ?? const Settings();
        final currentVoice = current.globalViewSettings.ttsVoice;
        final currentModelId =
            currentVoice != null && currentVoice.contains('@')
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
        final wasActive = state.activeModelId == id;
        emit(
          state.copyWith(
            installedModels: state.installedModels
                .where((m) => m.id != id)
                .toList(),
            activeModelId: wasActive ? null : state.activeModelId,
          ),
        );
      },
    );
  }

  void _onActivate(_Activate event, Emitter<TtsLibraryState> emit) async {
    if (state.busyModelId != null) return;
    emit(state.copyWith(busyModelId: event.modelId, error: null));

    final result = await ttsModelRepository.activateModel(event.modelId);
    await result.fold(
      (failure) async {
        emit(state.copyWith(error: failure.message, busyModelId: null));
      },
      (_) async {
        await _persistActiveVoice(event.modelId);
        emit(
          state.copyWith(activeModelId: event.modelId, busyModelId: null),
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

  void _onPreview(_Preview event, Emitter<TtsLibraryState> emit) async {
    // If the currently playing preview is tapped, stop it.
    if (state.busyModelId == event.modelId) {
      await ttsModelRepository.stopPreview();
      emit(state.copyWith(busyModelId: null));
      return;
    }

    // Stop any existing preview before starting the new one.
    if (state.busyModelId != null) {
      await ttsModelRepository.stopPreview();
    }

    emit(state.copyWith(busyModelId: event.modelId, error: null));

    final result = await ttsModelRepository.playPreview(event.modelId);
    result.fold(
      (failure) {
        emit(state.copyWith(error: failure.message, busyModelId: null));
      },
      (_) {
        if (state.busyModelId == event.modelId) {
          emit(state.copyWith(busyModelId: null));
        }
      },
    );
  }

  void _onImportCustomModel(
    _ImportCustomModel event,
    Emitter<TtsLibraryState> emit,
  ) async {
    emit(state.copyWith(error: null));
    final result = await ttsModelRepository.importCustomModel(
      inspection: event.inspection,
      displayName: event.displayName,
      languageCode: event.languageCode,
      languageLabel: event.languageLabel,
      typeOverride: event.typeOverride,
      speakerCount: event.speakerCount,
      sampleRate: event.sampleRate,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(error: failure.message));
      },
      (importedModel) {
        emit(
          state.copyWith(
            availableModels: ttsModelRepository.availableModels,
            installedModels: [
              ...state.installedModels.where((m) => m.id != importedModel.id),
              importedModel,
            ],
            updateNotification:
                'Voice "${importedModel.displayName}" imported successfully',
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _settingsSub?.cancel();
    _catalogSub?.cancel();
    _installedModelsSub?.cancel();
    _downloadsSub?.cancel();
    return super.close();
  }
}
