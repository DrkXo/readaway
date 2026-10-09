import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/models/ui_feedback.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../domain/repositories/reader_repository.dart';
import '../../../domain/repositories/reader_tts_repository.dart';

part 'reader_tts_bloc.freezed.dart';
part 'reader_tts_event.dart';
part 'reader_tts_state.dart';

@Injectable()
class ReaderTtsBloc extends Bloc<ReaderTtsEvent, ReaderTtsState> {
  final _log = AppLogger.instance.scope('ReaderTtsBloc');

  final ReaderRepository readerRepository;
  final ReaderTtsRepository ttsRepository;

  Uri? _coverUri;
  Uri? get coverUri => _coverUri;

  StreamSubscription<TtsPlaybackEvent>? _ttsStateSub;
  StreamSubscription<TtsChunk>? _chunkSub;
  Timer? _sleepTimerTick;

  String? _documentPath;
  String? _fileName;
  String? _bookTitle;
  String? _author;
  int _pageCount = 0;

  bool _autoAdvancing = false;

  ReaderTtsBloc({
    required this.readerRepository,
    required this.ttsRepository,
  }) : super(const ReaderTtsState()) {
    on<_TtsStart>(_onStart);
    on<_TtsClose>(_onClose);
    on<_ConsumeFeedback>(_onConsumeFeedback);
    on<_TtsErrorOccurred>(_onErrorOccurred);
    on<_TtsPageAdvanced>(_onPageAdvanced);
    on<_TtsChunkAdvanced>(_onChunkAdvanced);
    on<_ClearFollowTarget>(_onClearFollowTarget);
    on<_SetSleepTimer>(_onSetSleepTimer);
    on<_TtsSleepTimerFired>(_onSleepTimerFired);
    on<_TtsSleepTimerTick>(_onSleepTimerTick);

    _ttsStateSub = ttsRepository.playbackState.listen((event) {
      if (event.state == TtsPlaybackState.completed) {
        _onPageTtsCompleted();
      } else if (event.state == TtsPlaybackState.error) {
        add(
          ReaderTtsEvent.errorOccurred(
            event.message ?? 'Speech synthesis error',
          ),
        );
      }
    });

    _chunkSub = ttsRepository.currentChunk.listen((chunk) {
      if (isClosed) return;
      final chapter = state.ttsCurrentPage;
      if (chapter == null) return;
      add(
        ReaderTtsEvent.chunkAdvanced(
          chapterIndex: chapter,
          startOffset: chunk.startOffset,
          endOffset: chunk.endOffset,
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    _cancelSleepTimer();
    await _ttsStateSub?.cancel();
    await _chunkSub?.cancel();
    await ttsRepository.stopPipeline();
    await ttsRepository.releaseResources();
    return super.close();
  }

  Future<void> _onStart(
    _TtsStart event,
    Emitter<ReaderTtsState> emit,
  ) async {
    if (!event.isReflowable) {
      emit(
        state.copyWith(
          ttsActive: false,
          transientFeedback: UiFeedback(
            failure: const UnexpectedFailure(
              'Text-to-speech is currently only available for reflowable text documents.',
            ),
          ),
        ),
      );
      return;
    }

    final permissionResult = await readerRepository.requestAudioPermissions();
    final hasPermission = permissionResult.dataOrNull ?? false;
    if (!hasPermission) {
      emit(
        state.copyWith(
          ttsActive: false,
          ttsCurrentPage: null,
          transientFeedback: UiFeedback(
            failure: const NotificationPermissionDeniedFailure(
              message: 'Audio notification permissions are required for background read-aloud.',
            ),
          ),
        ),
      );
      return;
    }

    final prepResult = await ttsRepository.prepareForPlayback();
    final prepFailure = prepResult.failureOrNull;
    if (prepFailure != null) {
      _log.w('TTS preparation failed: $prepFailure');
      emit(
        state.copyWith(
          ttsActive: false,
          ttsCurrentPage: null,
          transientFeedback: UiFeedback(
            failure: prepFailure,
            actionLabel: 'TTS Settings',
            actionRoute: '${appRoutes.settings.path}?tab=tts',
          ),
        ),
      );
      return;
    }

    _documentPath = event.documentPath;
    _fileName = event.fileName;
    _bookTitle = event.bookTitle;
    _author = event.author;
    _pageCount = event.pageCount;

    int targetChapter = event.pageIndex;
    double? startProgression;
    final coordinator = _paginationCoordinatorOrNull;
    if (coordinator != null && coordinator.chapterCount > 0) {
      final globalPage =
          event.currentVirtualPage ?? coordinator.currentState.globalPage;
      final coord = coordinator.coordinateFromGlobalPage(globalPage);
      targetChapter = coord.chapterIndex;
      final offsets = coordinator.getChapterPageOffsets(targetChapter);
      final height = coordinator.getChapterHeight(targetChapter);
      if (coord.pageInChapter < offsets.length &&
          height != null &&
          height > 0) {
        startProgression = (offsets[coord.pageInChapter] / height).clamp(
          0.0,
          1.0,
        );
      } else if (coord.totalPagesInChapter > 0) {
        startProgression = (coord.pageInChapter / coord.totalPagesInChapter)
            .clamp(0.0, 1.0);
      }
    }

    emit(state.copyWith(ttsActive: true, ttsCurrentPage: targetChapter));
    await _beginPageTts(targetChapter, emit, startProgression);
  }

  Future<void> _beginPageTts(
    int pageIndex, [
    Emitter<ReaderTtsState>? emit,
    double? startProgression,
  ]) async {
    final prepResult = await ttsRepository.prepareForPlayback();
    final prepFailure = prepResult.failureOrNull;
    if (prepFailure != null) {
      if (emit != null) {
        emit(
          state.copyWith(
            ttsActive: false,
            ttsCurrentPage: null,
            transientFeedback: UiFeedback(
              failure: prepFailure,
              actionLabel: 'TTS Settings',
              actionRoute: '${appRoutes.settings.path}?tab=tts',
            ),
          ),
        );
      } else {
        add(ReaderTtsEvent.errorOccurred(prepFailure.message));
      }
      return;
    }

    if (ttsRepository.currentVoice == null) {
      final voices = ttsRepository.availableVoices;
      if (voices.isNotEmpty) {
        ttsRepository.setVoice(voices.first);
      }
    }

    final textResult = await readerRepository.extractSpeechText(pageIndex);
    final text = textResult.dataOrNull ?? '';
    if (text.trim().isEmpty) return;

    if (_coverUri == null && _pageCount > 0) {
      final coverResult = await readerRepository.getCoverArtUri(
        filePath: _documentPath ?? _fileName ?? 'doc',
        fileName: _fileName ?? 'doc',
        pageCount: _pageCount,
      );
      _coverUri = coverResult.dataOrNull;
    }

    if (emit != null) {
      emit(state.copyWith(ttsCurrentPage: pageIndex));
    } else {
      add(ReaderTtsEvent.pageAdvanced(pageIndex: pageIndex));
    }

    _paginationCoordinatorOrNull?.attachSpeechText(pageIndex, text);

    ttsRepository.start();
    final docPath = _documentPath ?? _fileName ?? 'doc';
    final playResult = await ttsRepository.playText(
      text,
      bookPath: docPath,
      sectionIndex: pageIndex,
      pageIndex: pageIndex,
      startProgression: startProgression,
      tag: MediaItem(
        id: 'page-${pageIndex + 1}',
        title: 'Page ${pageIndex + 1}',
        album: _bookTitle,
        artist: _author,
        genre: 'Ebook',
        artUri: _coverUri,
      ),
    );

    final playFailure = playResult.failureOrNull;
    if (playFailure != null) {
      _log.e('TTS playText failed: $playFailure');
      if (emit != null) {
        emit(
          state.copyWith(
            ttsActive: false,
            ttsCurrentPage: null,
            transientFeedback: UiFeedback(
              failure: playFailure,
              actionLabel: playFailure is TtsNoVoiceSelectedFailure
                  ? 'TTS Settings'
                  : null,
              actionRoute: playFailure is TtsNoVoiceSelectedFailure
                  ? '${appRoutes.settings.path}?tab=tts'
                  : null,
            ),
          ),
        );
      } else {
        add(ReaderTtsEvent.errorOccurred(playFailure.message));
      }
    }
  }

  Future<void> _onPageTtsCompleted() async {
    if (_autoAdvancing) return;
    if (!state.ttsActive) return;

    final basePage = state.ttsCurrentPage;
    if (basePage == null || basePage >= _pageCount - 1) return;

    _autoAdvancing = true;
    try {
      final gapMs =
          (bakedGapForRate(kDefaultParagraphGapSec, ttsRepository.rate) * 1000)
              .round();
      if (gapMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: gapMs));
      }
      if (!state.ttsActive) return;

      int? next;
      for (var i = basePage + 1; i < _pageCount; i++) {
        final textResult = await readerRepository.extractSpeechText(i);
        final text = textResult.dataOrNull ?? '';
        if (text.trim().isNotEmpty) {
          next = i;
          break;
        }
      }
      if (next == null) return;

      add(ReaderTtsEvent.pageAdvanced(pageIndex: next));
      await _beginPageTts(next);
    } finally {
      _autoAdvancing = false;
    }
  }

  void _onPageAdvanced(
    _TtsPageAdvanced event,
    Emitter<ReaderTtsState> emit,
  ) {
    emit(state.copyWith(ttsCurrentPage: event.pageIndex));
  }

  void _onChunkAdvanced(
    _TtsChunkAdvanced event,
    Emitter<ReaderTtsState> emit,
  ) {
    final chapter = event.chapterIndex;
    final coordinator = _paginationCoordinatorOrNull;
    if (coordinator == null) return;
    if (coordinator.speechMapFor(chapter) == null) return;

    final targetPage = coordinator.globalPageForSpeechOffset(
      chapter,
      event.startOffset,
    );

    emit(
      state.copyWith(
        ttsSpeechRange: (start: event.startOffset, end: event.endOffset),
        ttsTargetVirtualPage: targetPage ?? state.ttsTargetVirtualPage,
      ),
    );
  }

  void _onClearFollowTarget(
    _ClearFollowTarget event,
    Emitter<ReaderTtsState> emit,
  ) {
    if (state.ttsTargetVirtualPage != null) {
      emit(state.copyWith(ttsTargetVirtualPage: null));
    }
  }

  Future<void> _onClose(
    _TtsClose event,
    Emitter<ReaderTtsState> emit,
  ) async {
    await ttsRepository.releaseResources();
    _cancelSleepTimer();
    emit(
      state.copyWith(
        ttsActive: false,
        ttsCurrentPage: null,
        ttsSleepTimerRemaining: null,
        ttsSpeechRange: null,
        ttsTargetVirtualPage: null,
      ),
    );
  }

  void _onSetSleepTimer(
    _SetSleepTimer event,
    Emitter<ReaderTtsState> emit,
  ) {
    _sleepTimerTick?.cancel();
    _sleepTimerTick = null;

    if (event.duration <= Duration.zero) {
      ttsRepository.setSleepTimer(Duration.zero);
      emit(state.copyWith(ttsSleepTimerRemaining: null));
      return;
    }

    ttsRepository.setSleepTimer(event.duration);
    emit(state.copyWith(ttsSleepTimerRemaining: event.duration));

    _sleepTimerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const ReaderTtsEvent.sleepTimerTick());
    });
  }

  void _cancelSleepTimer() {
    _sleepTimerTick?.cancel();
    _sleepTimerTick = null;
  }

  void _onSleepTimerTick(
    _TtsSleepTimerTick event,
    Emitter<ReaderTtsState> emit,
  ) {
    final remaining = state.ttsSleepTimerRemaining;
    if (remaining == null) {
      _sleepTimerTick?.cancel();
      _sleepTimerTick = null;
      return;
    }

    final next = remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      _sleepTimerTick?.cancel();
      _sleepTimerTick = null;
      emit(state.copyWith(ttsSleepTimerRemaining: null));
      add(const ReaderTtsEvent.sleepTimerFired());
    } else {
      emit(state.copyWith(ttsSleepTimerRemaining: next));
    }
  }

  void _onSleepTimerFired(
    _TtsSleepTimerFired event,
    Emitter<ReaderTtsState> emit,
  ) {
    _cancelSleepTimer();
    ttsRepository.releaseResources();
    emit(
      state.copyWith(
        ttsActive: false,
        ttsCurrentPage: null,
        ttsSpeechRange: null,
        ttsTargetVirtualPage: null,
      ),
    );
  }

  void _onConsumeFeedback(
    _ConsumeFeedback event,
    Emitter<ReaderTtsState> emit,
  ) {
    emit(state.copyWith(transientFeedback: null));
  }

  void _onErrorOccurred(
    _TtsErrorOccurred event,
    Emitter<ReaderTtsState> emit,
  ) {
    emit(
      state.copyWith(
        ttsActive: false,
        ttsCurrentPage: null,
        transientFeedback: UiFeedback(
          failure: TtsSynthesisFailure(event.message),
          actionLabel: 'TTS Settings',
          actionRoute: '${appRoutes.settings.path}?tab=tts',
        ),
      ),
    );
  }

  PaginationCoordinator? get _paginationCoordinatorOrNull =>
      GetIt.I.isRegistered<PaginationCoordinator>()
      ? GetIt.I<PaginationCoordinator>()
      : null;
}
