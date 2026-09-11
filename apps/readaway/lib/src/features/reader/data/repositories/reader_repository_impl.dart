import 'dart:io';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/logging_service.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/reader/supported_document_formats.dart';
import '../../../../core/services/document_cover_service.dart';
import '../../../../core/services/mupdf_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reader/reflowable_document_reader.dart';
import '../../../../core/services/window_service.dart';
import '../../../../core/utils/reader/reader_html_utils.dart'
    as reader_html_utils;
import '../../../library/domain/entity/reading_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../domain/entity/reader_link.dart';
import '../../domain/repositories/reader_repository.dart';

@LazySingleton(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final MuPdfService _muPdfService;
  final WindowService _windowService;
  final NotificationService _notificationService;
  final DocumentCoverService _coverService;
  final LibraryRepository _libraryRepository;
  ReflowableDocumentReader? _reflowReader;
  String? _currentDocumentPath;
  bool _isMuPdfOpen = false;
  final Map<String, Uint8List> _assetCache = {};

  ReaderRepositoryImpl(
    this._muPdfService,
    this._windowService,
    this._notificationService,
    this._coverService,
    this._libraryRepository,
  );

  Future<void> _ensureMuPdfOpen() async {
    if (!_isMuPdfOpen && _currentDocumentPath != null) {
      await _muPdfService.openDocument(_currentDocumentPath!);
      _isMuPdfOpen = true;
    }
  }

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

        _reflowReader?.dispose();
        _reflowReader = null;
        _assetCache.clear();
        if (_isMuPdfOpen) {
          await _muPdfService.closeDocument();
          _isMuPdfOpen = false;
        }

        _currentDocumentPath = path;

        final format = SupportedDocumentFormats.findFormat(path);
        final isReflowable = format?.isReflowable ?? false;

        final List<OutlineItem> outline;
        final String title;
        final int pageCount;

        if (isReflowable) {
          _reflowReader = await ReflowableDocumentReader.fromFile(path);
          outline = _reflowReader!.outline;
          final metaTitle = _reflowReader!.title;
          title = (metaTitle != null && metaTitle.isNotEmpty)
              ? metaTitle
              : (defaultTitle ?? file.uri.pathSegments.last);
          pageCount = _reflowReader!.sectionCount;
        } else {
          _reflowReader = null;
          await _ensureMuPdfOpen();
          outline = await _muPdfService.getOutLine();
          final metaTitle = await _muPdfService.getMetaData('info:Title');
          title = (metaTitle != null && metaTitle.isNotEmpty)
              ? metaTitle
              : (defaultTitle ?? file.uri.pathSegments.last);
          pageCount = await _muPdfService.getPageCount();
        }

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
        // Reflowable document -> HyperRender from semantic HTML
        if (isReflowable) {
          if (_reflowReader != null &&
              pageIndex >= 0 &&
              pageIndex < _reflowReader!.sectionCount) {
            final html = _reflowReader!.loadSectionHtml(pageIndex);
            return ReaderPageData(
              pageIndex: pageIndex,
              links: const [],
              html: html,
            );
          }
          throw DocumentParseFailure('Invalid section index: $pageIndex');
        }

        // Non-reflowable document (PDF, XPS, CBZ) -> MuPDF Native C
        await _ensureMuPdfOpen();
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
        // Reflowable documents do not use MuPDF render engine; position is section index.
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
        if (_reflowReader != null) {
          return _reflowReader!.sectionCount;
        }
        await _ensureMuPdfOpen();
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
        if (_reflowReader != null &&
            pageIndex >= 0 &&
            pageIndex < _reflowReader!.sectionCount) {
          final html = _reflowReader!.loadSectionHtml(pageIndex);
          return reader_html_utils.extractPageText(html);
        }
        await _ensureMuPdfOpen();
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
      () async {
        if (_reflowReader != null) {
          final resolved = _reflowReader!.resolveSectionIndex(uri);
          if (resolved != null) return resolved;
        }
        await _ensureMuPdfOpen();
        return await _muPdfService.resolveUri(uri);
      },
      (error, stack) => CorruptDocumentFailure(
        'Failed to resolve link: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Uint8List?> loadAssetBytes(
    String assetPath, {
    int? pageIndex,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (_reflowReader == null) {
          logger.w(
            '[ReaderRepository] loadAssetBytes: _reflowReader is null for asset: $assetPath',
          );
          return null;
        }

        final cleanPath = assetPath.split('?').first.split('#').first;
        final decoded = Uri.decodeComponent(cleanPath);
        final cacheKey = pageIndex != null ? '$pageIndex:$cleanPath' : cleanPath;

        final cached = _assetCache[cacheKey] ?? _assetCache[decoded] ?? _assetCache[cleanPath];
        if (cached != null) return cached;

        void cache(Uint8List b) {
          _assetCache[cacheKey] = b;
          _assetCache[cleanPath] = b;
          _assetCache[decoded] = b;
        }

        // 1. If pageIndex is provided, resolve relative to that section/chapter
        if (pageIndex != null && pageIndex >= 0) {
          final resolved = _reflowReader!.resolveAssetPath(pageIndex, decoded);
          final bytes = _reflowReader!.loadAssetBytes(resolved);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 2. Try direct decoded path
        var bytes = _reflowReader!.loadAssetBytes(decoded);
        if (bytes != null && bytes.isNotEmpty) {
          cache(bytes);
          return bytes;
        }

        // 3. Try raw path
        if (cleanPath != decoded) {
          bytes = _reflowReader!.loadAssetBytes(cleanPath);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 4. Try path without leading slash
        final noSlash = decoded.startsWith('/')
            ? decoded.substring(1)
            : decoded;
        if (noSlash != decoded) {
          bytes = _reflowReader!.loadAssetBytes(noSlash);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 5. Try basename fallback
        final base = p.posix.basename(decoded);
        bytes = _reflowReader!.loadAssetBytes(base);
        if (bytes != null && bytes.isNotEmpty) {
          cache(bytes);
          return bytes;
        }

        logger.w(
          '[ReaderRepository] loadAssetBytes: could not resolve asset "$assetPath" (page: $pageIndex)',
        );
        return null;
      },
      (error, stack) {
        logger.e(
          '[ReaderRepository] loadAssetBytes error: $error',
          error,
          stack,
        );
        return StorageReadFailure(
          assetPath,
          cause: error,
          stackTrace: stack,
        );
      },
    );
  }

  @override
  TaskEither<Failure, int?> resolveReflowableLink(String uri) {
    return TaskEither.tryCatch(
      () async => _reflowReader?.resolveSectionIndex(uri),
      (error, stack) => CorruptDocumentFailure(
        'Failed to resolve reflowable link: $error',
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
        _reflowReader?.dispose();
        _reflowReader = null;
        _assetCache.clear();
        if (_isMuPdfOpen) {
          await _muPdfService.closeDocument();
          _isMuPdfOpen = false;
        }
        _currentDocumentPath = null;
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
