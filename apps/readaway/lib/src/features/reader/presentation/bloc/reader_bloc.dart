import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';

import '../../../../core/services/css_service.dart';
import '../../../../core/services/services.dart';
import '../../../../core/utils/reader/reader_html_utils.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@singleton
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final WindowService _windowService;
  final MuPdfService _muPdfService;

  ReaderBloc({
    required this._windowService,
    required this._muPdfService,
  }) : super(const ReaderState()) {
    on<_OpenDocument>(_onOpenDocument, transformer: droppable());
    on<_PageChanged>(_onPageChanged);
    on<_LoadPage>(_onLoadPage, transformer: droppable());
    on<_CloseDocument>(_onCloseDocument);
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
      final html = _sanitizeHtml(rawHtml, links) ?? '';

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
      images[index] = rendered == null ? null : await _decodePage(rendered);
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

  static Future<ui.Image> _decodePage(Map<String, dynamic> rendered) {
    final w = rendered['width'] as int;
    final h = rendered['height'] as int;
    final stride = rendered['stride'] as int;
    final comps = rendered['components'] as int;
    final src = rendered['pixels'] as Uint8List;

    // mupdf renders RGB(A); Flutter needs RGBA.
    final rgba = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      var s = y * stride;
      var d = y * w * 4;
      for (var x = 0; x < w; x++) {
        rgba[d++] = src[s];
        rgba[d++] = src[s + 1];
        rgba[d++] = src[s + 2];
        rgba[d++] = comps == 4 ? src[s + 3] : 255;
        s += comps;
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      w,
      h,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  void _onCloseDocument(
    _CloseDocument event,
    Emitter<ReaderState> emit,
  ) {
    _muPdfService.closeDocument();
    _windowService.setDefaultTitle();
    emit(const ReaderState());
  }

  void _precachePages(int currentIndex) {
    final pages = state.isReflowable ? state.htmlPages : state.pageImages;
    if (pages == null) return;

    for (final idx in [currentIndex, currentIndex + 1, currentIndex - 1]) {
      if (idx >= 0 && idx < state.pageCount && pages[idx] == null) {
        add(ReaderEvent.loadPage(index: idx));
      }
    }
  }

  static String? _sanitizeHtml(String? raw, List<PageLink> links) {
    if (raw == null || raw.isEmpty) return raw;

    final document = html_parser.parse(raw);
    for (final element in document.querySelectorAll('*')) {
      _stripHeight(element);
    }
    mergePageLinks(document, links);
    return document.outerHtml;
  }

  static void _stripHeight(dom.Element element) {
    element.attributes.remove('height');

    final style = element.attributes['style'];
    if (style == null || style.isEmpty) return;

    final declarations = cssService.parseDeclarations(style)..remove('height');
    if (declarations.isEmpty) {
      element.attributes.remove('style');
    } else {
      element.attributes['style'] = declarations.entries
          .map((e) => '${e.key}: ${e.value};')
          .join(' ');
    }
  }
}
