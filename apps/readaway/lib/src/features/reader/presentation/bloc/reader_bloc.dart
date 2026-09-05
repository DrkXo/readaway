import 'dart:async';
import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/reader/reader_document.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/tts/tts_models.dart';
import '../../../../core/utils/reader/reader_html_utils.dart';
import '../../../../core/utils/reader/reader_image_utils.dart';
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

    // Auto-advance to the next page when TTS genuinely finishes the current page's queue.
    _ttsStateSub = ttsRepository.playbackState.listen((event) {
      if (event.state == TtsPlaybackState.completed) {
        _onPageTtsCompleted();
      }
    });
  }

  void _disposeImages() {
    final images = state.pageImages;
    if (images != null) {
      for (final img in images) {
        img?.dispose();
      }
    }
  }

  @override
  Future<void> close() async {
    _disposeImages();
    await _ttsStateSub?.cancel();
    await ttsRepository.stopPipeline().run();
    await readerRepository.closeDocument().run();
    await readerRepository.updateWindowTitle(null).run();
    return super.close();
  }

  Future<void> _onOpenDocument(
    _OpenDocument event,
    Emitter<ReaderState> emit,
  ) async {
    _disposeImages();
    emit(
      state.copyWith(
        loading: true,
        failure: null,
        error: null,
        documentPages: null,
        pageImages: null,
      ),
    );

    final openResult = await readerRepository
        .openDocument(event.path, defaultTitle: event.fileName)
        .run();

    await openResult.fold(
      (failure) async {
        logger.e('[ReaderBloc] Failed to open document: $failure');
        emit(
          state.copyWith(
            loading: false,
            failure: failure,
            error: failure.message,
          ),
        );
      },
      (info) async {
        final count = info.pageCount;
        final reflowable = info.isReflowable;
        final fileName = event.fileName ?? event.path.split('/').last;

        emit(
          state.copyWith(
            fileName: fileName,
            pageCount: count,
            isReflowable: reflowable,
            documentPages: reflowable
                ? List<ReaderDocument?>.filled(count, null)
                : null,
            pageImages: reflowable ? null : List<ui.Image?>.filled(count, null),
            currentPage: 0,
            outline: info.outline,
            bookTitle: info.title,
            loading: false,
            failure: null,
            error: null,
          ),
        );

        add(const ReaderEvent.loadPage(index: 0));
        _precachePages(0);

        await readerRepository.updateWindowTitle(info.title).run();

        final coverResult = await readerRepository
            .getCoverArtUri(
              filePath: event.path,
              fileName: fileName,
              pageCount: count,
            )
            .run();
        _coverUri = coverResult.getRight().toNullable();
      },
    );
  }

  void _onPageChanged(_PageChanged event, Emitter<ReaderState> emit) {
    emit(state.copyWith(currentPage: event.index));
    _precachePages(event.index);
  }

  Future<void> _onLoadPage(_LoadPage event, Emitter<ReaderState> emit) async {
    final index = event.index;
    if (index < 0 || index >= state.pageCount) return;

    if (state.isReflowable) {
      if (state.documentPages == null ||
          state.documentPages![index] != null ||
          state.loadingPages.contains(index)) {
        return;
      }
    } else {
      if (state.pageImages == null ||
          state.pageImages![index] != null ||
          state.loadingPages.contains(index)) {
        return;
      }
    }

    emit(state.copyWith(loadingPages: {...state.loadingPages, index}));

    final result = await readerRepository
        .loadPage(index, isReflowable: state.isReflowable)
        .run();

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
        if (state.isReflowable) {
          final pages = List<ReaderDocument?>.from(state.documentPages!);
          pages[index] = pageData.document;
          emit(
            state.copyWith(
              documentPages: pages,
              loadingPages: {...state.loadingPages}..remove(index),
            ),
          );
        } else {
          final rendered = pageData.renderedData;
          final images = List<ui.Image?>.from(state.pageImages!);
          images[index]?.dispose();
          images[index] = rendered == null
              ? null
              : await decodeRenderedPage(rendered);
          emit(
            state.copyWith(
              pageImages: images,
              loadingPages: {...state.loadingPages}..remove(index),
            ),
          );
        }
      },
    );
  }

  void _onCloseDocument(
    _CloseDocument event,
    Emitter<ReaderState> emit,
  ) {
    _disposeImages();
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
    if (!state.isReflowable) return;

    final permissionResult = await readerRepository
        .requestAudioPermissions()
        .run();
    final hasPermission = permissionResult.getOrElse((_) => false);
    if (!hasPermission) return;

    emit(state.copyWith(ttsActive: true));
    await _beginPageTts(state.currentPage);
  }

  /// Starts TTS playback for the page at [pageIndex]: sets the active voice
  /// from settings, spins up the pipeline, and plays the page's text.
  Future<void> _beginPageTts(int pageIndex) async {
    if (ttsRepository.currentVoice == null) {
      final models = ttsRepository.availableVoices;
      if (models.isNotEmpty) {
        final m = models.first;
        ttsRepository.setVoice(
          TtsVoiceOption(
            engine: TtsEngineKind.sherpaOnnx,
            id: m.id,
            label: m.displayName,
            languageCode: m.languageCode,
            sherpaSpeakerId: m.speakerCount > 0 ? 0 : null,
          ),
        );
      }
    }

    final textResult = await readerRepository.extractPageText(pageIndex).run();
    final text = textResult.getOrElse((_) => '');
    if (text.trim().isEmpty) return;

    if (_coverUri == null && state.pageCount > 0) {
      final coverResult = await readerRepository
          .getCoverArtUri(
            filePath: state.fileName ?? 'doc',
            fileName: state.fileName ?? 'doc',
            pageCount: state.pageCount,
          )
          .run();
      _coverUri = coverResult.getRight().toNullable();
    }

    ttsRepository.start();
    await ttsRepository
        .playText(
          text,
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
  }

  /// Called when [ReaderTtsRepository] reports a genuine page-end.
  Future<void> _onPageTtsCompleted() async {
    if (_autoAdvancing) return;
    if (!state.isReflowable || !state.ttsActive) return;
    if (state.currentPage >= state.pageCount - 1) return;

    _autoAdvancing = true;
    try {
      int? next;
      for (var i = state.currentPage + 1; i < state.pageCount; i++) {
        final textResult = await readerRepository.extractPageText(i).run();
        final text = textResult.getOrElse((_) => '');
        if (text.isNotEmpty) {
          next = i;
          break;
        }
      }
      if (next == null) return;

      add(ReaderEvent.pageChanged(index: next));
      await _beginPageTts(next);
    } finally {
      _autoAdvancing = false;
    }
  }

  /// Stops playback and hides the TTS player.
  Future<void> _onTtsClose(
    _TtsClose event,
    Emitter<ReaderState> emit,
  ) async {
    await ttsRepository.stop().run();
    emit(state.copyWith(ttsActive: false));
  }

  void _precachePages(int currentIndex) {
    final pages = state.isReflowable ? state.documentPages : state.pageImages;
    if (pages == null) return;

    for (final idx in precacheCandidates(currentIndex, state.pageCount)) {
      if (pages[idx] == null) {
        add(ReaderEvent.loadPage(index: idx));
      }
    }
  }
}
