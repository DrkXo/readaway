import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/logging_service.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/reader/supported_document_formats.dart';
import '../../../../core/services/document_cover_service.dart';
import '../../../../core/services/epub/epub_spine_reader.dart';
import '../../../../core/services/mupdf_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../library/domain/entity/reading_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../../core/utils/reader/reader_html_utils.dart' as reader_html_utils;
import '../../domain/entity/reader_link.dart';
import '../../domain/repositories/reader_repository.dart';

@LazySingleton(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final MuPdfService _muPdfService;
  final WindowService _windowService;
  final NotificationService _notificationService;
  final DocumentCoverService _coverService;
  final LibraryRepository _libraryRepository;
  EpubSpineReader? _spineReader;

  ReaderRepositoryImpl(
    this._muPdfService,
    this._windowService,
    this._notificationService,
    this._coverService,
    this._libraryRepository,
  );

  @override
  TaskEither<Failure, ReaderDocumentInfo> openDocument(
    String path, {
    String? defaultTitle,
    ReaderEngineMode engineMode = ReaderEngineMode.customFlow,
  }) {
    return TaskEither.tryCatch(
      () async {
        final file = File(path);
        if (!await file.exists()) {
          throw DocumentNotFoundFailure(path);
        }

        if (!SupportedDocumentFormats.isSupported(path)) {
          final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
          throw UnsupportedDocumentFormatFailure(ext.isEmpty ? 'unknown' : ext);
        }

        await _muPdfService.openDocument(path);

        final isReflowable = await _muPdfService.isReflowable();
        final outline = await _muPdfService.getOutLine();
        final metaTitle = await _muPdfService.getMetaData('info:Title');

        if (isReflowable && path.toLowerCase().endsWith('.epub')) {
          try {
            _spineReader = await EpubSpineReader.fromFile(path);
          } catch (e) {
            logger.w('Failed to initialize EpubSpineReader, falling back to MuPDF: $e');
            _spineReader = null;
          }
        } else {
          _spineReader = null;
        }

        final int pageCount;
        if (isReflowable && engineMode == ReaderEngineMode.customFlow && _spineReader != null) {
          pageCount = _spineReader!.spineCount;
        } else {
          pageCount = await _muPdfService.getPageCount();
        }

        final title = (metaTitle != null && metaTitle.isNotEmpty)
            ? metaTitle
            : (defaultTitle ?? file.uri.pathSegments.last);

        return ReaderDocumentInfo(
          path: path,
          title: title,
          pageCount: pageCount,
          isReflowable: isReflowable,
          outline: outline,
        );
      },
      (error, stack) {
        if (error is Failure) return error;
        return CorruptDocumentFailure(
          'Failed to open document: $error',
          cause: error,
          stackTrace: stack,
        );
      },
    );
  }

  @override
  TaskEither<Failure, ReaderPageData> loadPage(
    int pageIndex, {
    required bool isReflowable,
    ReaderEngineMode engineMode = ReaderEngineMode.customFlow,
  }) {
    return TaskEither.tryCatch(
      () async {
        // Mode B: Custom Flow on reflowable EPUB
        if (isReflowable && engineMode == ReaderEngineMode.customFlow && _spineReader != null) {
          if (pageIndex >= 0 && pageIndex < _spineReader!.spineCount) {
            final html = _spineReader!.loadSpineHtml(pageIndex);
            return ReaderPageData(
              pageIndex: pageIndex,
              links: const [],
              html: html,
            );
          }
        }

        // Mode A: Publisher Fidelity (or PDF)
        final pageLinks = await _muPdfService.getPageLinks(pageIndex);
        final domainLinks = pageLinks
            .map(
              (l) => ReaderLink(
                x0: l.x0,
                y0: l.y0,
                x1: l.x1,
                y1: l.y1,
                uri: l.uri,
                pageNumber: l.pageNumber,
              ),
            )
            .toList();

        final rendered = await _muPdfService.renderPage(pageIndex);
        return ReaderPageData(
          pageIndex: pageIndex,
          links: domainLinks,
          renderedData: rendered,
        );
      },
      (error, stack) => DocumentParseFailure(
        'Failed to load page $pageIndex: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, int> convertPagePosition({
    required int currentPage,
    required ReaderEngineMode fromMode,
    required ReaderEngineMode toMode,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (fromMode == toMode || _spineReader == null) {
          return currentPage;
        }

        if (fromMode == ReaderEngineMode.customFlow &&
            toMode == ReaderEngineMode.publisherFidelity) {
          final clampedSpine = currentPage.clamp(0, _spineReader!.spineCount - 1);
          final mupdfPage = await _muPdfService.pageFromLocation(
            MuPdfLocation(chapter: clampedSpine, page: 0),
          );
          return mupdfPage >= 0 ? mupdfPage : 0;
        } else if (fromMode == ReaderEngineMode.publisherFidelity &&
            toMode == ReaderEngineMode.customFlow) {
          final loc = await _muPdfService.locationFromPage(currentPage);
          return loc.chapter.clamp(0, _spineReader!.spineCount - 1);
        }

        return currentPage;
      },
      (error, stack) => DocumentParseFailure(
        'Failed to convert page position: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, int> getPageCountForMode(ReaderEngineMode engineMode) {
    return TaskEither.tryCatch(
      () async {
        if (_spineReader != null && engineMode == ReaderEngineMode.customFlow) {
          return _spineReader!.spineCount;
        }
        return await _muPdfService.getPageCount();
      },
      (error, stack) => DocumentParseFailure(
        'Failed to get page count for mode $engineMode: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, String> extractPageText(int pageIndex) {
    return TaskEither.tryCatch(
      () async {
        if (_spineReader != null && pageIndex >= 0 && pageIndex < _spineReader!.spineCount) {
          final html = _spineReader!.loadSpineHtml(pageIndex);
          return reader_html_utils.extractPageText(html);
        }
        final text = await _muPdfService.extractPageText(pageIndex);
        return text ?? '';
      },
      (error, stack) => DocumentParseFailure(
        'Failed to extract text from page $pageIndex: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Uri?> getCoverArtUri({
    required String filePath,
    required String fileName,
    required int pageCount,
  }) {
    return TaskEither.tryCatch(
      () async {
        return _coverService.getCoverArtUri(
          filePath: filePath,
          fileName: fileName,
          pageCount: pageCount,
        );
      },
      (error, stack) => StorageReadFailure(
        filePath,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> updateWindowTitle(String? title) {
    return TaskEither.tryCatch(
      () async {
        if (title != null && title.isNotEmpty) {
          await _windowService.setTitle(title);
        } else {
          await _windowService.setDefaultTitle();
        }
        return unit;
      },
      (error, stack) => UnexpectedFailure(
        'Failed to update window title: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, bool> requestAudioPermissions() {
    return TaskEither.tryCatch(
      () async {
        return _notificationService.requestPermissions();
      },
      (error, stack) => NotificationPermissionDeniedFailure(
        message: 'Failed to request audio playback permissions: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, int> resolveLink(String uri) {
    return TaskEither.tryCatch(
      () async => await _muPdfService.resolveUri(uri),
      (error, stack) => CorruptDocumentFailure(
        'Failed to resolve link: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> updateReadingProgress({
    required String path,
    required int page,
    required int pageCount,
  }) {
    return TaskEither.tryCatch(
      () async {
        final docsResult = await _libraryRepository.getRecentDocuments().run();
        final docs = docsResult.getOrElse((_) => []);
        final doc = docs.where((d) => d.path == path).firstOrNull;
        if (doc != null) {
          final isFinished = pageCount > 0 && page >= pageCount - 1;
          final updated = doc.copyWith(
            lastReadPage: page,
            pageCount: pageCount,
            lastOpened: DateTime.now(),
            readingStatus: isFinished
                ? ReadingStatus.finished
                : ReadingStatus.reading,
          );
          await _libraryRepository.saveRecentDocument(updated).run();
        }
        return unit;
      },
      (error, stack) => DatabaseFailure(
        'Failed to update reading progress: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, int> getLastReadPage(String path) {
    return TaskEither.tryCatch(
      () async {
        final docsResult = await _libraryRepository.getRecentDocuments().run();
        final docs = docsResult.getOrElse((_) => []);
        final doc = docs.where((d) => d.path == path).firstOrNull;
        return doc?.lastReadPage ?? 0;
      },
      (error, stack) => DatabaseFailure(
        'Failed to get last read page: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> closeDocument() {
    return TaskEither.tryCatch(
      () async {
        await _muPdfService.closeDocument();
        return unit;
      },
      (error, stack) => UnexpectedFailure(
        'Failed to close document: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
