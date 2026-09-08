import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failures.dart';
import '../../../../core/models/reader/supported_document_formats.dart';
import '../../../../core/services/document_cover_service.dart';
import '../../../../core/services/mupdf_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../library/domain/entity/reading_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../domain/entity/reader_link.dart';
import '../../domain/repositories/reader_repository.dart';
import '../../domain/services/document_parser.dart';

@LazySingleton(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final MuPdfService _muPdfService;
  final DocumentParser<String> _documentParser;
  final WindowService _windowService;
  final NotificationService _notificationService;
  final DocumentCoverService _coverService;
  final LibraryRepository _libraryRepository;

  ReaderRepositoryImpl(
    this._muPdfService,
    this._documentParser,
    this._windowService,
    this._notificationService,
    this._coverService,
    this._libraryRepository,
  );

  @override
  TaskEither<Failure, ReaderDocumentInfo> openDocument(
    String path, {
    String? defaultTitle,
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

        final pageCount = await _muPdfService.getPageCount();
        final isReflowable = await _muPdfService.isReflowable();
        final outline = await _muPdfService.getOutLine();
        final metaTitle = await _muPdfService.getMetaData('info:Title');

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
  }) {
    return TaskEither.tryCatch(
      () async {
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

        if (isReflowable) {
          final html = (await _muPdfService.extractPageHtml(pageIndex)) ?? '';
          final document = _documentParser.parse(html, links: pageLinks);

          return ReaderPageData(
            pageIndex: pageIndex,
            document: document,
            links: domainLinks,
          );
        } else {
          final rendered = await _muPdfService.renderPage(pageIndex);

          return ReaderPageData(
            pageIndex: pageIndex,
            links: domainLinks,
            renderedData: rendered,
          );
        }
      },
      (error, stack) => DocumentParseFailure(
        'Failed to load page $pageIndex: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, String> extractPageText(int pageIndex) {
    return TaskEither.tryCatch(
      () async {
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
            readingStatus:
                isFinished ? ReadingStatus.finished : ReadingStatus.reading,
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
