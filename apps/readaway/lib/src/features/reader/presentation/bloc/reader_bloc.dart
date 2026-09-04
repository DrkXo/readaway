// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';

import '../../../../core/models/reader/reader_document.dart';
import '../../../../core/services/services.dart';
import '../../../../core/utils/reader/reader_html_utils.dart';
import '../../../../core/utils/reader/reader_image_utils.dart';
import '../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../domain/services/document_parser.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@Injectable()
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final WindowService _windowService;
  final MuPdfService _muPdfService;
  final TtsControllerService _ttsController;
  final SettingsBloc _settingsBloc;
  final DocumentParser<String> _documentParser;

  StreamSubscription<TtsPlaybackEvent>? _ttsStateSub;

  /// Guards against re-entrant auto-advance while the next page's TTS is
  /// being spun up (extract text + playText are async).
  bool _autoAdvancing = false;

  ReaderBloc({
    required WindowService windowService,
    required MuPdfService muPdfService,
    required TtsControllerService ttsController,
    required SettingsBloc settingsBloc,
    required DocumentParser<String> documentParser,
  })  : _windowService = windowService,
        _muPdfService = muPdfService,
        _ttsController = ttsController,
        _settingsBloc = settingsBloc,
        _documentParser = documentParser,
        super(const ReaderState()) {
    on<_OpenDocument>(_onOpenDocument, transformer: droppable());
    on<_PageChanged>(_onPageChanged);
    on<_LoadPage>(_onLoadPage, transformer: concurrent());
    on<_CloseDocument>(_onCloseDocument);
    on<_TtsStart>(_onTtsStart);
    on<_TtsClose>(_onTtsClose);

    // Auto-advance to the next page when TTS genuinely finishes the current
    // page's queue.
    _ttsStateSub = _ttsController.playbackState.listen((event) {
      if (event.state == TtsPlaybackState.completed) {
        _onPageTtsCompleted();
      }
    });
  }

  /// Exposes the TTS playback controller to reader widgets.
  TtsControllerService get ttsController => _ttsController;

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
    await _ttsController.stopPipeline();
    await _muPdfService.closeDocument();
    await _windowService.setDefaultTitle();
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
        error: null,
        documentPages: null,
        pageImages: null,
      ),
    );

    try {
      final service = _muPdfService;
      await service.closeDocument();
      await service.openDocument(event.path);

      final count = await service.getPageCount();
      logger.d('Loaded: $count pages');

      final reflowable = await service.isReflowable();
      final outline = await service.getOutLine();

      final fileName = event.fileName ?? event.path.split('/').last;

      emit(
        state.copyWith(
          fileName: fileName,
          pageCount: count,
          isReflowable: reflowable,
          documentPages:
              reflowable ? List<ReaderDocument?>.filled(count, null) : null,
          pageImages: reflowable ? null : List<ui.Image?>.filled(count, null),
          currentPage: 0,
          outline: outline,
          loading: false,
        ),
      );
      add(const ReaderEvent.loadPage(index: 0));
      _precachePages(0);

      final metaTitle = await service.getMetaData('title');
      final metaAuthor = await service.getMetaData('author');
      final bookTitle = (metaTitle == null || metaTitle.isEmpty)
          ? fileName
          : metaTitle;

      if (!isClosed) {
        emit(
          state.copyWith(
            bookTitle: bookTitle,
            author: metaAuthor,
          ),
        );

        await _windowService.setTitle(bookTitle);
      }
      // ignore: unused_catch_stack
    } catch (e, st) {
      logger.d(
        'Failed to open document',
      );
      emit(state.copyWith(error: '$e', loading: false));
    }
  }

  void _onPageChanged(_PageChanged event, Emitter<ReaderState> emit) {
    emit(state.copyWith(currentPage: event.index));
    _precachePages(event.index);
  }

  Future<void> _onLoadPage(_LoadPage event, Emitter<ReaderState> emit) async {
    if (!state.isReflowable) {
      await _onRenderPage(event, emit);
      return;
    }

    final index = event.index;
    if (state.documentPages == null || index < 0 || index >= state.pageCount) {
      return;
    }
    if (state.documentPages![index] != null ||
        state.loadingPages.contains(index)) {
      return;
    }

    emit(state.copyWith(loadingPages: {...state.loadingPages, index}));

    try {
      final service = _muPdfService;
      final (rawHtml, links) = await (
        service.extractPageHtml(index),
        service.getPageLinks(index),
      ).wait;

      final doc = _documentParser.parse(rawHtml ?? '', links: links);

      final pages = List<ReaderDocument?>.from(state.documentPages!);
      pages[index] = doc;
      emit(
        state.copyWith(
          documentPages: pages,
          loadingPages: {...state.loadingPages}..remove(index),
        ),
      );
    } catch (e) {
      logger.d('Failed to load page $index: $e');
      emit(
        state.copyWith(
          loadingPages: {...state.loadingPages}..remove(index),
        ),
      );
    }
  }

  Future<void> _onRenderPage(
    _LoadPage event,
    Emitter<ReaderState> emit,
  ) async {
    final index = event.index;
    if (state.pageImages == null || index < 0 || index >= state.pageCount) {
      return;
    }
    if (state.pageImages![index] != null ||
        state.loadingPages.contains(index)) {
      return;
    }

    emit(state.copyWith(loadingPages: {...state.loadingPages, index}));

    try {
      final rendered = await _muPdfService.renderPage(index);
      final images = List<ui.Image?>.from(state.pageImages!);
      images[index]?.dispose();
      images[index] =
          rendered == null ? null : await decodeRenderedPage(rendered);
      emit(
        state.copyWith(
          pageImages: images,
          loadingPages: {...state.loadingPages}..remove(index),
        ),
      );
    } catch (e) {
      logger.d('Failed to render page $index: $e');
      emit(
        state.copyWith(loadingPages: {...state.loadingPages}..remove(index)),
      );
    }
  }

  void _onCloseDocument(
    _CloseDocument event,
    Emitter<ReaderState> emit,
  ) {
    _disposeImages();
    _muPdfService.closeDocument();
    _windowService.setDefaultTitle();
    emit(const ReaderState());
  }

  /// Starts TTS playback for the current page. The pipeline is only spun up
  /// here (on user tap), never on document load.
  Future<void> _onTtsStart(
    _TtsStart event,
    Emitter<ReaderState> emit,
  ) async {
    if (!state.isReflowable) return;

    emit(state.copyWith(ttsActive: true));
    await _beginPageTts(state.currentPage);
  }

  /// Starts TTS playback for the page at [pageIndex]: sets the active voice
  /// from settings, spins up the pipeline, and plays the page's text. Shared
  /// by the initial Listen action and the auto-advance path.
  Future<void> _beginPageTts(int pageIndex) async {
    // Set the active voice from settings
    final activeModelId = _settingsBloc.state.ttsActiveModelId;
    if (activeModelId != null) {
      final models = _settingsBloc.state.ttsAvailableModels;
      for (final m in models) {
        if (m.id == activeModelId) {
          _ttsController.setVoice(
            TtsVoiceOption(
              engine: TtsEngineKind.sherpaOnnx,
              id: m.id,
              label: m.displayName,
              languageCode: m.languageCode,
              sherpaSpeakerId: m.speakerCount > 0 ? 0 : null,
            ),
          );
          break;
        }
      }
    }

    final text = await _muPdfService.extractPageText(pageIndex);
    if (text == null || text.trim().isEmpty) return;

    _ttsController.start();
    await _ttsController.playText(
      text,
      tag: MediaItem(
        id: 'page-${pageIndex + 1}',
        title: 'Page ${pageIndex + 1}',
        album: state.bookTitle,
        artist: state.author,
        genre: 'Ebook',
      ),
    );
  }

  /// Called when [TtsControllerService] reports a genuine page-end (every
  /// chunk of the current page was enqueued and played). If a next page with
  /// readable text exists, navigates to it and continues TTS playback;
  /// otherwise playback stops at book end.
  Future<void> _onPageTtsCompleted() async {
    if (_autoAdvancing) return;
    if (!state.isReflowable || !state.ttsActive) return;
    if (state.currentPage >= state.pageCount - 1) return;

    _autoAdvancing = true;
    try {
      // Skip forward to the next page that has readable text.
      int? next;
      for (var i = state.currentPage + 1; i < state.pageCount; i++) {
        String? text;
        try {
          text = await _muPdfService.extractPageText(i);
        } catch (e) {
          logger.d('TTS auto-advance: failed to extract text for page $i', e);
        }
        if (text != null && text.trim().isNotEmpty) {
          next = i;
          break;
        }
      }
      if (next == null) return; // No readable page remains — stop at book end.

      add(ReaderEvent.pageChanged(index: next));
      try {
        await _beginPageTts(next);
      } catch (e) {
        logger.d('TTS auto-advance failed for page $next', e);
      }
    } finally {
      _autoAdvancing = false;
    }
  }

  /// Stops playback and hides the TTS player.
  Future<void> _onTtsClose(
    _TtsClose event,
    Emitter<ReaderState> emit,
  ) async {
    await _ttsController.stop();
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
