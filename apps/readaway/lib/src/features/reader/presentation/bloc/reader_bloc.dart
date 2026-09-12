import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/ui_feedback.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/tts/tts_models.dart';
import '../../../../core/utils/reader/reader_html_utils.dart';
import '../../domain/entity/reader_link.dart';
import '../../domain/repositories/reader_repository.dart';
import '../../domain/repositories/reader_tts_repository.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@Injectable()
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final ReaderRepository readerRepository;
  final ReaderTtsRepository ttsRepository;

  Uri? _coverUri;
  Uri? get coverUri => _coverUri;

  StreamSubscription<TtsPlaybackEvent>? _ttsStateSub;

  /// Guards against re-entrant auto-advance while the next page's TTS is
  /// being spun up (extract text + playText are async).
  bool _autoAdvancing = false;

  ReaderBloc({
    required this.readerRepository,
    required this.ttsRepository,
  }) : super(const ReaderState()) {
    on<_OpenDocument>(_onOpenDocument, transformer: droppable());
    on<_PageChanged>(_onPageChanged);
    on<_LoadPage>(_onLoadPage, transformer: concurrent());
    on<_CloseDocument>(_onCloseDocument);
    on<_TtsStart>(_onTtsStart);
    on<_TtsClose>(_onTtsClose);
    on<_ConsumeFeedback>(_onConsumeFeedback);
    on<_TtsErrorOccurred>(_onTtsErrorOccurred);
    on<_JumpToTtsPage>(_onJumpToTtsPage);
    on<_TtsPageAdvanced>(_onTtsPageAdvanced);
    on<_VirtualPageChanged>(_onVirtualPageChanged);

    // Auto-advance or report errors when TTS reports state updates
    _ttsStateSub = ttsRepository.playbackState.listen((event) {
      if (event.state == TtsPlaybackState.completed) {
        _onPageTtsCompleted();
      } else if (event.state == TtsPlaybackState.error) {
        add(
          ReaderEvent.ttsErrorOccurred(
            event.message ?? 'Speech synthesis error',
          ),
        );
      }
    });
  }

  Timer? _progressDebounceTimer;

  void _scheduleProgressSync(int page) {
    _progressDebounceTimer?.cancel();
    _progressDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _flushProgress(page);
    });
  }

  void _flushProgress([int? page]) {
    final targetPage = page ?? state.currentPage;
    final path = state.documentPath;
    if (path == null || state.pageCount <= 0) return;
    readerRepository
        .updateReadingProgress(
          path: path,
          page: targetPage,
          pageCount: state.pageCount,
        )
        .run();
  }

  @override
  Future<void> close() async {
    _progressDebounceTimer?.cancel();
    _flushProgress();
    await _ttsStateSub?.cancel();
    await ttsRepository.stopPipeline().run();
    await ttsRepository.releaseResources().run();
    await readerRepository.closeDocument().run();
    await readerRepository.updateWindowTitle(null).run();
    return super.close();
  }

  Future<void> _onOpenDocument(
    _OpenDocument event,
    Emitter<ReaderState> emit,
  ) async {
    final initialFileName = event.fileName ?? event.path.split('/').last;
    emit(
      state.copyWith(
        loading: true,
        failure: null,
        error: null,
        documentPath: event.path,
        fileName: initialFileName,
        pageHtmls: null,
      ),
    );

    final openResult = await readerRepository
        .openDocument(
          event.path,
          defaultTitle: event.fileName,
        )
        .run();

    await openResult.fold(
      (failure) async {
        logger.e('[ReaderBloc] Failed to open document: $failure');
        emit(
          state.copyWith(
            loading: false,
            failure: failure,
            error: failure.message,
            documentPath: event.path,
            fileName: initialFileName,
          ),
        );
      },
      (info) async {
        final count = info.pageCount;

        final lastPageResult = await readerRepository
            .getLastReadPage(event.path)
            .run();
        final rawLastPage = lastPageResult.getOrElse((_) => 0);
        final initialPage = count > 0 ? rawLastPage.clamp(0, count - 1) : 0;

        emit(
          state.copyWith(
            documentPath: event.path,
            fileName: initialFileName,
            pageCount: count,
            pageHtmls: List<String?>.filled(count, null),
            pageLinks: List<List<ReaderLink>?>.filled(count, null),
            currentPage: initialPage,
            ttsCurrentPage: null,
            outline: info.outline,
            bookTitle: info.title,
            loading: false,
            failure: null,
            error: null,
          ),
        );

        add(ReaderEvent.loadPage(index: initialPage));
        _precachePages(initialPage);
        _scheduleProgressSync(initialPage);

        await readerRepository.updateWindowTitle(info.title).run();

        final coverResult = await readerRepository
            .getCoverArtUri(
              filePath: event.path,
              fileName: initialFileName,
              pageCount: count,
            )
            .run();
        _coverUri = coverResult.getRight().toNullable();
      },
    );
  }

  void _onPageChanged(_PageChanged event, Emitter<ReaderState> emit) {
    emit(
      state.copyWith(
        currentPage: event.index,
        currentVirtualPage: null,
        virtualPageCount: null,
      ),
    );
    _precachePages(event.index);
    _scheduleProgressSync(event.index);
  }

  void _onVirtualPageChanged(
    _VirtualPageChanged event,
    Emitter<ReaderState> emit,
  ) {
    emit(
      state.copyWith(
        currentVirtualPage: event.globalPage,
        virtualPageCount: event.totalPages,
        currentPage: event.chapterIndex,
      ),
    );
    _precachePages(event.chapterIndex);
    _scheduleProgressSync(event.globalPage);
  }

  Future<void> _onLoadPage(_LoadPage event, Emitter<ReaderState> emit) async {
    final index = event.index;
    if (index < 0 || index >= state.pageCount) return;

    if (state.pageHtmls == null ||
        state.pageHtmls![index] != null ||
        state.loadingPages.contains(index)) {
      return;
    }

    emit(state.copyWith(loadingPages: {...state.loadingPages, index}));

    final result = await readerRepository.loadPage(index).run();

    await result.fold(
      (failure) async {
        logger.d('Failed to load page $index: $failure');
        emit(
          state.copyWith(
            loadingPages: {...state.loadingPages}..remove(index),
          ),
        );
      },
      (pageData) async {
        final htmlPages = List<String?>.from(state.pageHtmls!);
        final linkPages = List<List<ReaderLink>?>.from(state.pageLinks!);
        htmlPages[index] = pageData.html;
        linkPages[index] = pageData.links;
        emit(
          state.copyWith(
            pageHtmls: htmlPages,
            pageLinks: linkPages,
            loadingPages: {...state.loadingPages}..remove(index),
          ),
        );
      },
    );
  }

  void _onCloseDocument(
    _CloseDocument event,
    Emitter<ReaderState> emit,
  ) {
    _progressDebounceTimer?.cancel();
    _flushProgress();
    _coverUri = null;
    readerRepository.closeDocument().run();
    readerRepository.updateWindowTitle(null).run();
    emit(const ReaderState());
  }

  /// Starts TTS playback for the current page.
  Future<void> _onTtsStart(
    _TtsStart event,
    Emitter<ReaderState> emit,
  ) async {
    final permissionResult = await readerRepository
        .requestAudioPermissions()
        .run();
    final hasPermission = permissionResult.getOrElse((_) => false);
    if (!hasPermission) {
      emit(
        state.copyWith(
          ttsActive: false,
          ttsCurrentPage: null,
          transientFeedback: UiFeedback(
            failure: const NotificationPermissionDeniedFailure(
              message:
                  'Audio notification permissions are required for background read-aloud.',
            ),
          ),
        ),
      );
      return;
    }

    final prepResult = await ttsRepository.prepareForPlayback().run();
    final prepFailure = prepResult.getLeft().toNullable();
    if (prepFailure != null) {
      logger.w('[ReaderBloc] TTS preparation failed: $prepFailure');
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

    emit(state.copyWith(ttsActive: true, ttsCurrentPage: state.currentPage));
    await _beginPageTts(state.currentPage, emit);
  }

  /// Starts TTS playback for the page at [pageIndex]: sets the active voice
  /// from settings, spins up the pipeline, and plays the page's text.
  Future<void> _beginPageTts(
    int pageIndex, [
    Emitter<ReaderState>? emit,
  ]) async {
    final prepResult = await ttsRepository.prepareForPlayback().run();
    final prepFailure = prepResult.getLeft().toNullable();
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
        add(ReaderEvent.ttsErrorOccurred(prepFailure.message));
      }
      return;
    }

    if (ttsRepository.currentVoice == null) {
      final voices = ttsRepository.availableVoices;
      if (voices.isNotEmpty) {
        ttsRepository.setVoice(voices.first);
      }
    }

    final textResult = await readerRepository.extractPageText(pageIndex).run();
    final text = textResult.getOrElse((_) => '');
    if (text.trim().isEmpty) return;

    if (_coverUri == null && state.pageCount > 0) {
      final coverResult = await readerRepository
          .getCoverArtUri(
            filePath: state.documentPath ?? state.fileName ?? 'doc',
            fileName: state.fileName ?? 'doc',
            pageCount: state.pageCount,
          )
          .run();
      _coverUri = coverResult.getRight().toNullable();
    }

    if (emit != null) {
      emit(state.copyWith(ttsCurrentPage: pageIndex));
    } else {
      add(ReaderEvent.ttsPageAdvanced(pageIndex: pageIndex));
    }

    ttsRepository.start();
    final playResult = await ttsRepository
        .playText(
          text,
          pageIndex: pageIndex,
          tag: MediaItem(
            id: 'page-${pageIndex + 1}',
            title: 'Page ${pageIndex + 1}',
            album: state.bookTitle,
            artist: state.author,
            genre: 'Ebook',
            artUri: _coverUri,
          ),
        )
        .run();

    final playFailure = playResult.getLeft().toNullable();
    if (playFailure != null) {
      logger.e('[ReaderBloc] TTS playText failed: $playFailure');
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
        add(ReaderEvent.ttsErrorOccurred(playFailure.message));
      }
    }
  }

  /// Called when [ReaderTtsRepository] reports a genuine page-end.
  /// Decoupled: advances the spoken audio page in the background WITHOUT
  /// forcefully changing the user's viewport page.
  Future<void> _onPageTtsCompleted() async {
    if (_autoAdvancing) return;
    if (!state.ttsActive) return;

    final basePage = state.ttsCurrentPage ?? state.currentPage;
    if (basePage >= state.pageCount - 1) return;

    _autoAdvancing = true;
    try {
      int? next;
      for (var i = basePage + 1; i < state.pageCount; i++) {
        final textResult = await readerRepository.extractPageText(i).run();
        final text = textResult.getOrElse((_) => '');
        if (text.trim().isNotEmpty) {
          next = i;
          break;
        }
      }
      if (next == null) return;

      add(ReaderEvent.ttsPageAdvanced(pageIndex: next));
      await _beginPageTts(next);
    } finally {
      _autoAdvancing = false;
    }
  }

  void _onTtsPageAdvanced(
    _TtsPageAdvanced event,
    Emitter<ReaderState> emit,
  ) {
    emit(state.copyWith(ttsCurrentPage: event.pageIndex));
  }

  void _onJumpToTtsPage(
    _JumpToTtsPage event,
    Emitter<ReaderState> emit,
  ) {
    final target = state.ttsCurrentPage;
    if (target != null && target >= 0 && target < state.pageCount) {
      emit(state.copyWith(currentPage: target));
      _precachePages(target);
      _scheduleProgressSync(target);
    }
  }

  /// Stops playback and hides the TTS player.
  Future<void> _onTtsClose(
    _TtsClose event,
    Emitter<ReaderState> emit,
  ) async {
    await ttsRepository.stop().run();
    emit(state.copyWith(ttsActive: false, ttsCurrentPage: null));
  }

  void _onConsumeFeedback(
    _ConsumeFeedback event,
    Emitter<ReaderState> emit,
  ) {
    emit(state.copyWith(transientFeedback: null));
  }

  void _onTtsErrorOccurred(
    _TtsErrorOccurred event,
    Emitter<ReaderState> emit,
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

  void _precachePages(int currentIndex) {
    final pages = state.pageHtmls;
    if (pages == null) return;

    for (final idx in precacheCandidates(currentIndex, state.pageCount)) {
      if (pages[idx] == null) {
        add(ReaderEvent.loadPage(index: idx));
      }
    }
  }
}
