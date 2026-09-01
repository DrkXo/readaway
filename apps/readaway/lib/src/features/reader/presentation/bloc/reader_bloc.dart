import 'dart:async';
import 'dart:ui' as ui;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';

import '../../../../core/services/services.dart';
import '../../../../core/utils/reader/reader_html_utils.dart';
import '../../../../core/utils/reader/reader_image_utils.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@Injectable()
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final WindowService _windowService;
  final MuPdfService _muPdfService;
  final TtsControllerService _ttsController;

  ReaderBloc({
    required this._windowService,
    required this._muPdfService,
    required this._ttsController,
  }) : super(const ReaderState()) {
    on<_OpenDocument>(_onOpenDocument, transformer: droppable());
    on<_PageChanged>(_onPageChanged);
    on<_LoadPage>(_onLoadPage, transformer: droppable());
    on<_CloseDocument>(_onCloseDocument);
    on<_TtsStart>(_onTtsStart);
    on<_TtsClose>(_onTtsClose);
  }

  /// Exposes the TTS playback controller to reader widgets.
  TtsControllerService get ttsController => _ttsController;

  @override
  Future<void> close() async {
    await _ttsController.stopPipeline();
    await _muPdfService.closeDocument();
    await _windowService.setDefaultTitle();
    return super.close();
  }

  Future<void> _onOpenDocument(
    _OpenDocument event,
    Emitter<ReaderState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        htmlPages: null,
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
          htmlPages: reflowable ? List<String?>.filled(count, null) : null,
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
    if (state.htmlPages == null || index < 0 || index >= state.pageCount) {
      return;
    }
    if (state.htmlPages![index] != null || state.loadingPages.contains(index)) {
      return;
    }

    emit(state.copyWith(loadingPages: {...state.loadingPages, index}));

    try {
      final service = _muPdfService;
      final (rawHtml, links) = await (
        service.extractPageHtml(index),
        service.getPageLinks(index),
      ).wait;
      final html = sanitizeHtml(rawHtml, links) ?? '';

      final pages = List<String?>.from(state.htmlPages!);
      pages[index] = html;
      emit(
        state.copyWith(
          htmlPages: pages,
          loadingPages: {...state.loadingPages}..remove(index),
        ),
      );
    } catch (e) {
      logger.d('Failed to load page $index');
      final pages = List<String?>.from(state.htmlPages!);
      pages[index] = '<p>Error loading page: $e</p>';
      emit(
        state.copyWith(
          htmlPages: pages,
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
      images[index] = rendered == null
          ? null
          : await decodeRenderedPage(rendered);
      emit(
        state.copyWith(
          pageImages: images,
          loadingPages: {...state.loadingPages}..remove(index),
        ),
      );
    } catch (e) {
      logger.d('Failed to render page $index');
      emit(
        state.copyWith(loadingPages: {...state.loadingPages}..remove(index)),
      );
    }
  }

  void _onCloseDocument(
    _CloseDocument event,
    Emitter<ReaderState> emit,
  ) {
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
    if (!state.isReflowable || state.htmlPages == null) return;
    final html = state.htmlPages![state.currentPage];
    if (html == null) return;
    final text = extractPageText(html);
    if (text.trim().isEmpty) return;

    _ttsController.start();
    emit(state.copyWith(ttsActive: true));
    await _ttsController.playText(text);
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
    final pages = state.isReflowable ? state.htmlPages : state.pageImages;
    if (pages == null) return;

    for (final idx in precacheCandidates(currentIndex, state.pageCount)) {
      if (pages[idx] == null) {
        add(ReaderEvent.loadPage(index: idx));
      }
    }
  }
}
