import 'dart:io';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/logging_service.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/reader/supported_document_formats.dart';
import '../../../../core/services/document_cover_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../library/domain/entity/reading_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../domain/repositories/reader_repository.dart';

@LazySingleton(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final WindowService _windowService;
  final NotificationService _notificationService;
  final DocumentCoverService _coverService;
  final LibraryRepository _libraryRepository;
  ReflowableDocumentReader? _reflowReader;
  final Map<String, Uint8List> _assetCache = {};

  ReaderRepositoryImpl(
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

        _reflowReader?.dispose();
        _reflowReader = null;
        _assetCache.clear();

        final DocumentReader reader;
        try {
          reader = await DocumentReaderFactory().open(path);
        } on UnsupportedFormatException {
          final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
          throw UnsupportedDocumentFormatFailure(ext.isEmpty ? 'unknown' : ext);
        }
        if (reader is! ReflowableDocumentReader) {
          final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
          throw UnsupportedDocumentFormatFailure(ext.isEmpty ? 'unknown' : ext);
        }
        _reflowReader = reader;

        final metaTitle = reader.title;
        final title = (metaTitle != null && metaTitle.isNotEmpty)
            ? metaTitle
            : (defaultTitle ?? file.uri.pathSegments.last);

        return ReaderDocumentInfo(
          path: path,
          title: title,
          pageCount: reader.sectionCount,
          outline: reader.outline,
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
  TaskEither<Failure, ReaderPageData> loadPage(int pageIndex) {
    return TaskEither.tryCatch(
      () async {
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
        if (_reflowReader != null &&
            pageIndex >= 0 &&
            pageIndex < _reflowReader!.sectionCount) {
          return _reflowReader!.extractSectionText(pageIndex);
        }
        throw DocumentParseFailure('Invalid section index: $pageIndex');
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
        final cacheKey = pageIndex != null
            ? '$pageIndex:$cleanPath'
            : cleanPath;

        final cached =
            _assetCache[cacheKey] ??
            _assetCache[decoded] ??
            _assetCache[cleanPath];
        if (cached != null) return cached;

        void cache(Uint8List b) {
          _assetCache[cacheKey] = b;
          _assetCache[cleanPath] = b;
          _assetCache[decoded] = b;
        }

        // 1. If pageIndex is provided, resolve relative to that section/chapter
        if (pageIndex != null && pageIndex >= 0) {
          final resolved = _reflowReader!.resolveAssetPath(pageIndex, decoded);
          final bytes = _reflowReader!.loadAsset(resolved);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 2. Try direct decoded path
        var bytes = _reflowReader!.loadAsset(decoded);
        if (bytes != null && bytes.isNotEmpty) {
          cache(bytes);
          return bytes;
        }

        // 3. Try raw path
        if (cleanPath != decoded) {
          bytes = _reflowReader!.loadAsset(cleanPath);
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
          bytes = _reflowReader!.loadAsset(noSlash);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 5. Try basename fallback
        final base = p.posix.basename(decoded);
        bytes = _reflowReader!.loadAsset(base);
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
