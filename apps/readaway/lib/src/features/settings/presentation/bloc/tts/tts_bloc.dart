import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../../core/services/services.dart';


part 'tts_bloc.freezed.dart';
part 'tts_event.dart';
part 'tts_state.dart';

/// Owns the offline voice catalog state: what's downloadable, what's on
/// disk, download progress, and the active voice. Lives as a singleton so
/// downloads keep running after the settings sheet closes.
@Singleton()
class TtsBloc extends Bloc<TtsEvent, TtsState> {
  final SherpaOnnxTtsService _ttsService;
  final JustAudioService _audio;
  final SettingsService _settingsService;

  final _downloadSubs = <String, StreamSubscription<ModelDownloadProgress>>{};

  TtsBloc({
    required this._ttsService,
    required this._audio,
    required this._settingsService,
  }) : super(const TtsState()) {
    on<_Refresh>(_onRefresh, transformer: concurrent());
    on<_StartDownload>(_onStartDownload, transformer: concurrent());
    on<_CancelDownload>(_onCancelDownload);
    on<_DeleteModel>(_onDeleteModel);
    on<_Activate>(_onActivate, transformer: droppable());
    on<_Preview>(_onPreview, transformer: droppable());
    on<_DownloadProgress>(_onDownloadProgress);
    on<_DownloadFailed>(_onDownloadFailed);

    add(const _Refresh());
  }

  SherpaTtsModelInfo? _modelById(String id) {
    for (final m in _ttsService.availableModels) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _onRefresh(_Refresh event, Emitter<TtsState> emit) async {
    try {
      final downloaded = await _ttsService.getDownloadedModels();
      final downloadedIds = downloaded.map((m) => m.id).toSet();

      // Restore the persisted active voice (if any) so the selection
      // survives app restarts. Only load it when its files are on disk.
      var activeModelId = _ttsService.activeModel?.id;
      if (activeModelId == null) {
        final persisted = _settingsService.settings.globalViewSettings.ttsVoice;
        if (persisted != null && downloadedIds.contains(persisted)) {
          try {
            await _ttsService.loadModel(persisted);
            activeModelId = persisted;
          } on SherpaTtsException {
            // Model files present but failed to load — fall through to
            // "no active voice" rather than crashing the refresh.
          }
        }
      }

      emit(
        state.copyWith(
          availableModels: _ttsService.availableModels,
          downloadedIds: downloadedIds,
          activeModelId: activeModelId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to load voice catalog'));
    }
  }

  void _onStartDownload(_StartDownload event, Emitter<TtsState> emit) {
    final id = event.model.id;
    if (_downloadSubs.containsKey(id)) return;

    emit(
      state.copyWith(
        error: null,
        downloads: {
          ...state.downloads,
          id: const TtsDownloadStatus(stage: ModelDownloadStage.downloading),
        },
      ),
    );

    _downloadSubs[id] = _ttsService
        .downloadModel(event.model)
        .listen(
          (progress) => add(
            _DownloadProgress(
              progress.modelId,
              progress.stage,
              progress.fraction,
            ),
          ),
          onError: (Object _) => add(_DownloadFailed(id)),
          cancelOnError: true,
        );
  }

  void _onCancelDownload(_CancelDownload event, Emitter<TtsState> emit) {
    _downloadSubs.remove(event.modelId)?.cancel();
    _removeDownload(event.modelId, emit);
  }

  void _onDownloadProgress(
    _DownloadProgress event,
    Emitter<TtsState> emit,
  ) {
    if (event.stage == ModelDownloadStage.done) {
      _downloadSubs.remove(event.modelId)?.cancel();
      _finishDownload(event.modelId, emit);
      return;
    }
    if (event.stage == ModelDownloadStage.failed) {
      _onDownloadFailed(_DownloadFailed(event.modelId), emit);
      return;
    }
    if (!state.downloads.containsKey(event.modelId)) return;

    final downloads = Map.of(state.downloads);
    downloads[event.modelId] = TtsDownloadStatus(
      stage: event.stage,
      fraction: event.fraction,
    );
    emit(state.copyWith(downloads: downloads));
  }

  void _onDownloadFailed(_DownloadFailed event, Emitter<TtsState> emit) {
    if (_downloadSubs.remove(event.modelId) != null ||
        state.downloads.containsKey(event.modelId)) {
      final name = _modelById(event.modelId)?.displayName ?? 'voice';
      final downloads = Map.of(state.downloads)..remove(event.modelId);
      emit(
        state.copyWith(error: 'Failed to download $name', downloads: downloads),
      );
    }
  }

  void _removeDownload(String id, Emitter<TtsState> emit) {
    if (!state.downloads.containsKey(id)) return;
    final downloads = Map.of(state.downloads)..remove(id);
    emit(state.copyWith(downloads: downloads));
  }

  void _finishDownload(String id, Emitter<TtsState> emit) {
    final downloads = Map.of(state.downloads)..remove(id);
    emit(
      state.copyWith(
        downloads: downloads,
        downloadedIds: {...state.downloadedIds, id},
      ),
    );
  }

  void _onDeleteModel(_DeleteModel event, Emitter<TtsState> emit) async {
    final id = event.model.id;
    try {
      await _ttsService.deleteModel(id);
      final wasActive = state.activeModelId == id;
      if (wasActive) {
        // Clear the persisted selection so we don't try to restore a
        // deleted voice on the next launch.
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
          downloadedIds: state.downloadedIds.where((e) => e != id).toSet(),
          activeModelId: wasActive ? null : state.activeModelId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(error: 'Failed to delete ${event.model.displayName}'),
      );
    }
  }

  void _onActivate(_Activate event, Emitter<TtsState> emit) async {
    if (state.busyModelId != null) return;
    emit(state.copyWith(busyModelId: event.modelId, error: null));
    try {
      if (_ttsService.activeModel?.id != event.modelId) {
        await _ttsService.loadModel(event.modelId);
      }
      // Persist the selection so it survives app restarts.
      _persistActiveVoice(event.modelId);
      emit(
        state.copyWith(activeModelId: event.modelId, busyModelId: null),
      );
    } on SherpaTtsException catch (e) {
      emit(state.copyWith(error: e.message, busyModelId: null));
    } catch (_) {
      emit(
        state.copyWith(
          error: 'Failed to activate voice',
          busyModelId: null,
        ),
      );
    }
  }

  /// Writes the active voice id into app settings (debounced) so it's
  /// restored on the next launch.
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

  void _onPreview(_Preview event, Emitter<TtsState> emit) async {
    if (state.busyModelId != null) return;
    final previousActive = state.activeModelId;
    emit(state.copyWith(busyModelId: event.modelId, error: null));
    try {
      if (_ttsService.activeModel?.id != event.modelId) {
        await _ttsService.loadModel(event.modelId);
      }

      final tmp = await getTemporaryDirectory();
      final file = await _ttsService.synthesizeToFile(
        text: 'Hello. This is what this voice sounds like while reading.',
        outputPath: p.join(tmp.path, 'tts_voice_preview.wav'),
      );

      unawaited(_audio.playFile(file.path));

      // Previewing must not change the active voice: restore the model that
      // was loaded before the preview (if any) so the reader keeps using it.
      if (previousActive != null && previousActive != event.modelId) {
        await _ttsService.loadModel(previousActive);
      }
      emit(state.copyWith(busyModelId: null));
    } on SherpaTtsException catch (e) {
      emit(state.copyWith(error: e.message, busyModelId: null));
    } catch (_) {
      emit(
        state.copyWith(error: 'Failed to preview voice', busyModelId: null),
      );
    }
  }

  @override
  Future<void> close() {
    for (final sub in _downloadSubs.values) {
      sub.cancel();
    }
    _downloadSubs.clear();
    return super.close();
  }
}
