import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';
import 'package:readaway/src/core/services/services.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@singleton
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  ReaderBloc() : super(const ReaderState()) {
    on<_OpenDocument>(_onOpenDocument, transformer: droppable());
    on<_PageChanged>(_onPageChanged);
    on<_LoadPage>(_onLoadPage, transformer: droppable());
    on<_CloseDocument>(_onCloseDocument);
  }

  Future<void> _onOpenDocument(
    _OpenDocument event,
    Emitter<ReaderState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null, htmlPages: null));

    try {
      final service = GetIt.I<MuPdfService>();
      await service.closeDocument();
      await service.openDocument(event.path);

      final count = await service.getPageCount();
      logger.d('Loaded: $count pages');

      final outline = await service.getOutLine();

      final fileName = event.fileName ?? event.path.split('/').last;

      emit(
        state.copyWith(
          fileName: fileName,
          pageCount: count,
          htmlPages: List<String?>.filled(count, null),
          currentPage: 0,
          outline: outline,
          loading: false,
        ),
      );

      _precachePages(0);

      final metaTitle = await service.getMetaData('title');
      final metaAuthor = await service.getMetaData('author');
      final bookTitle =
          (metaTitle == null || metaTitle.isEmpty) ? fileName : metaTitle;

      if (!isClosed) {
        emit(
          state.copyWith(
            bookTitle: bookTitle,
            author: metaAuthor,
          ),
        );
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
    final index = event.index;
    if (state.htmlPages == null || index < 0 || index >= state.pageCount) {
      return;
    }
    if (state.htmlPages![index] != null || state.loadingPages.contains(index)) {
      return;
    }

    emit(state.copyWith(loadingPages: {...state.loadingPages, index}));

    try {
      final service = GetIt.I<MuPdfService>();
      final rawHtml = await service.extractPageHtml(index);
      final html = _sanitizeHtml(rawHtml) ?? '';

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

  void _onCloseDocument(_CloseDocument event, Emitter<ReaderState> emit) {
    GetIt.I<MuPdfService>().closeDocument();
    emit(const ReaderState());
  }

  void _precachePages(int currentIndex) {
    final htmlPages = state.htmlPages;
    if (htmlPages == null) return;

    for (final idx in [currentIndex, currentIndex + 1, currentIndex - 1]) {
      if (idx >= 0 && idx < state.pageCount && htmlPages[idx] == null) {
        add(ReaderEvent.loadPage(index: idx));
      }
    }
  }

  static String? _sanitizeHtml(String? raw) {
    if (raw == null || raw.isEmpty) return raw;

    final document = html_parser.parse(raw);
    for (final element in document.querySelectorAll('*')) {
      _stripHeight(element);
    }
    return document.outerHtml;
  }

  static void _stripHeight(dom.Element element) {
    element.attributes.remove('height');

    final style = element.attributes['style'];
    if (style == null || style.isEmpty) return;

    final kept = style.split(';').map((d) => d.trim()).where((decl) {
      if (decl.isEmpty) return false;
      return decl.split(':').first.trim().toLowerCase() != 'height';
    }).toList();

    if (kept.isEmpty) {
      element.attributes.remove('style');
    } else {
      element.attributes['style'] = '${kept.join('; ')};';
    }
  }
}
