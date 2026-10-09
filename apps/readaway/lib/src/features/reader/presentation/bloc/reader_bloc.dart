import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/ui_feedback.dart';
import '../../../../core/utils/reader/reader_html_utils.dart';
import '../../domain/entity/reader_link.dart';
import '../../domain/repositories/reader_repository.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@Injectable()
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final _log = AppLogger.instance.scope('ReaderBloc');

  final ReaderRepository readerRepository;

  Uri? _coverUri;
  Uri? get coverUri => _coverUri;

  ReaderBloc({
    required this.readerRepository,
  }) : super(const ReaderState()) {
    on<_OpenDocument>(_onOpenDocument, transformer: droppable());
    on<_UnlockDocument>(_onUnlockDocument);
    on<_PageChanged>(_onPageChanged);
    on<_JumpToChapter>(_onJumpToChapter);
    on<_LoadPage>(_onLoadPage, transformer: concurrent());
    on<_CloseDocument>(_onCloseDocument);
    on<_ConsumeFeedback>(_onConsumeFeedback);
    on<_VirtualPageChanged>(_onVirtualPageChanged);
    on<_ClearPendingRestore>(_onClearPendingRestore);
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

    // Persist the stable anchor when pagination is ready. Before the viewport
    // initializes the coordinator, chapterCount is 0 and we preserve any
    // previously stored anchor instead of overwriting it.
    ReadingAnchor? anchor;
    final coordinator = GetIt.I.isRegistered<PaginationCoordinator>()
        ? GetIt.I<PaginationCoordinator>()
        : null;
    if (coordinator != null && coordinator.chapterCount > 0) {
      anchor = coordinator.currentAnchor;
    }

    readerRepository.updateReadingProgress(
      path: path,
      page: targetPage,
      pageCount: state.pageCount,
      anchor: anchor,
    );
  }

  void _onClearPendingRestore(
    _ClearPendingRestore event,
    Emitter<ReaderState> emit,
  ) {
    emit(state.copyWith(pendingRestoreAnchor: null));
  }

  @override
  Future<void> close() async {
    _progressDebounceTimer?.cancel();
    _flushProgress();
    await readerRepository.closeDocument();
    await readerRepository.updateWindowTitle(null);
    return super.close();
  }

  Future<void> _onOpenDocument(
    _OpenDocument event,
    Emitter<ReaderState> emit,
  ) async {
    // If a document was already open, properly flush progress and release its resources first.
    if (state.hasDocument) {
      _progressDebounceTimer?.cancel();
      _progressDebounceTimer = null;
      _flushProgress();
      await readerRepository.closeDocument();
    }

    // Reset pagination so a stale anchor from a previous document is never
    // saved while the new document is still loading.
    final coordinator = GetIt.I.isRegistered<PaginationCoordinator>()
        ? GetIt.I<PaginationCoordinator>()
        : null;
    coordinator?.reset();

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

    final openResult = await readerRepository.openDocument(
      event.path,
      defaultTitle: event.fileName,
      password: event.password,
    );

    await openResult.fold(
      (failure) async {
        _log.e('Failed to open document: $failure');
        final isEncrypted = failure is DocumentEncryptedFailure;
        emit(
          state.copyWith(
            loading: false,
            failure: failure,
            error: failure.message,
            documentPath: event.path,
            fileName: initialFileName,
            requiresPassword: isEncrypted,
            isInvalidPassword: isEncrypted && failure.isInvalidPassword,
          ),
        );
      },
      (info) async {
        final count = info.pageCount;
        final isReflow = info.isReflowable;

        final lastPageResult = await readerRepository.getLastReadPage(
          event.path,
        );
        final rawLastPage = lastPageResult.dataOrNull ?? 0;
        final initialPage = count > 0 ? rawLastPage.clamp(0, count - 1) : 0;

        final anchorResult = await readerRepository.getLastReadAnchor(
          event.path,
        );
        final savedAnchor = anchorResult.dataOrNull;

        emit(
          state.copyWith(
            documentPath: event.path,
            fileName: initialFileName,
            pageCount: count,
            pageHtmls: isReflow ? List<String?>.filled(count, null) : null,
            pageLinks: isReflow
                ? List<List<ReaderLink>?>.filled(count, null)
                : null,
            currentPage: initialPage,
            currentVirtualPage: null,
            virtualPageCount: null,
            pendingRestoreAnchor: savedAnchor,
            outline: info.outline,
            bookTitle: info.title,
            author: info.author,
            isReflowable: isReflow,
            format: info.format,
            requiresPassword: false,
            isInvalidPassword: false,
            loading: false,
            failure: null,
            error: null,
          ),
        );

        if (isReflow) {
          add(ReaderEvent.loadPage(index: initialPage));
          _precachePages(initialPage);
        }

        await readerRepository.updateReadingProgress(
          path: event.path,
          page: initialPage,
          pageCount: count,
          anchor: savedAnchor,
        );

        await readerRepository.updateWindowTitle(info.title);

        final coverResult = await readerRepository.getCoverArtUri(
          filePath: event.path,
          fileName: initialFileName,
          pageCount: count,
        );
        _coverUri = coverResult.dataOrNull;
      },
    );
  }

  void _onUnlockDocument(
    _UnlockDocument event,
    Emitter<ReaderState> emit,
  ) {
    if (state.documentPath != null) {
      add(
        ReaderEvent.openDocument(
          path: state.documentPath!,
          fileName: state.fileName,
          password: event.password,
        ),
      );
    }
  }

  void _onPageChanged(_PageChanged event, Emitter<ReaderState> emit) {
    emit(
      state.copyWith(
        currentPage: event.index,
        currentVirtualPage: null,
        virtualPageCount: null,
      ),
    );
    if (state.isReflowable) {
      _precachePages(event.index);
    }
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

    final result = await readerRepository.loadPage(index);

    await result.fold(
      (failure) async {
        _log.d('Failed to load page $index: $failure');
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

  Future<void> _onCloseDocument(
    _CloseDocument event,
    Emitter<ReaderState> emit,
  ) async {
    _progressDebounceTimer?.cancel();
    _flushProgress();
    await readerRepository.closeDocument();
    await readerRepository.updateWindowTitle(null);
    emit(const ReaderState());
  }

  void _onJumpToChapter(
    _JumpToChapter event,
    Emitter<ReaderState> emit,
  ) {
    final chapter = event.chapterIndex;
    if (chapter < 0 || chapter >= state.pageCount) return;
    emit(
      state.copyWith(
        currentPage: chapter,
        currentVirtualPage: event.virtualPage ?? state.currentVirtualPage,
      ),
    );
    _precachePages(chapter);
    _scheduleProgressSync(event.virtualPage ?? chapter);
  }

  void _onConsumeFeedback(
    _ConsumeFeedback event,
    Emitter<ReaderState> emit,
  ) {
    emit(state.copyWith(transientFeedback: null));
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
