import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway/src/core/services/logging_service.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/document_format.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../library/domain/entity/reading_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../domain/repositories/reader_repository.dart';

@LazySingleton(as: ReaderRepository)
class ReaderRepositoryImpl implements ReaderRepository {
  final WindowService _windowService;
  final NotificationService _notificationService;
  final AppPathService _pathService;
  final LibraryRepository _libraryRepository;
  IsolateDocumentSession? _session;
  final Map<String, Uint8List> _assetCache = {};

  ReaderRepositoryImpl(
    this._windowService,
    this._notificationService,
    this._pathService,
    this._libraryRepository,
  );

  @override
  TaskEither<Failure, ReaderDocumentInfo> openDocument(
    String path, {
    String? defaultTitle,
    String? password,
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

        final oldSession = _session;
        _session = null;
        _assetCache.clear();
        if (oldSession != null) {
          await oldSession.dispose();
        }

        final IsolateDocumentSession session;
        try {
          session = await IsolateDocumentSession.open(
            path,
            password: password,
          );
        } on DocumentEncryptedException catch (e) {
          throw DocumentEncryptedFailure(
            path,
            isInvalidPassword: e.isInvalidPassword,
            cause: e,
          );
        } on UnsupportedFormatException {
          final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
          throw UnsupportedDocumentFormatFailure(ext.isEmpty ? 'unknown' : ext);
        }
        _session = session;

        final metaTitle = session.title;
        final title = (metaTitle != null && metaTitle.isNotEmpty)
            ? metaTitle
            : (defaultTitle ?? file.uri.pathSegments.last);
        final author = session.metadata?.creator;
        final count = session.isReflowable
            ? session.sectionCount
            : session.pageCount;

        return ReaderDocumentInfo(
          path: path,
          title: title,
          author: author,
          pageCount: count,
          outline: session.outline,
          isReflowable: session.isReflowable,
          format: session.format,
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
        if (_session != null &&
            pageIndex >= 0 &&
            pageIndex < _session!.sectionCount) {
          final html = await _session!.loadSectionHtml(pageIndex);
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
  TaskEither<Failure, Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (_session != null &&
            pageIndex >= 0 &&
            pageIndex < _session!.pageCount) {
          return await _session!.loadPageImage(
            pageIndex,
            scale: scale,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
          );
        }
        throw DocumentParseFailure('Invalid page index: $pageIndex');
      },
      (error, stack) => DocumentParseFailure(
        'Failed to load page image $pageIndex: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, PageSize?> getPageSize(int pageIndex) {
    return TaskEither.tryCatch(
      () async {
        if (_session != null &&
            pageIndex >= 0 &&
            pageIndex < _session!.pageCount) {
          return await _session!.getPageSize(pageIndex);
        }
        return null;
      },
      (error, stack) => DocumentParseFailure(
        'Failed to get page size for $pageIndex: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, String> extractPageText(int pageIndex) {
    return TaskEither.tryCatch(
      () async {
        if (_session != null &&
            pageIndex >= 0 &&
            pageIndex < _session!.sectionCount) {
          return await _session!.extractSectionText(pageIndex);
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
  TaskEither<Failure, String> extractSpeechText(int pageIndex) {
    return TaskEither.tryCatch(
      () async {
        if (_session != null &&
            pageIndex >= 0 &&
            pageIndex < _session!.sectionCount) {
          return await _session!.extractSectionSpeechText(pageIndex);
        }
        throw DocumentParseFailure('Invalid section index: $pageIndex');
      },
      (error, stack) => DocumentParseFailure(
        'Failed to extract speech text from page $pageIndex: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Option<FootnoteItem>> resolveFootnote(
    String url, {
    int? currentChapterIndex,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (_session == null || url.trim().isEmpty) {
          return none();
        }

        final footnote = await _session!.resolveFootnote(
          url,
          currentChapterIndex: currentChapterIndex,
        );
        if (footnote != null) {
          return some(footnote);
        }
        return none();
      },
      (error, stack) => DocumentParseFailure(
        'Failed to resolve footnote for "$url": $error',
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
        // 1. Check if recent document already has a valid cover path
        final docsRes = await _libraryRepository.getRecentDocuments().run();
        final doc = docsRes
            .getOrElse((_) => [])
            .where((d) => d.path == filePath)
            .firstOrNull;
        if (doc?.coverPath != null && await File(doc!.coverPath!).exists()) {
          return File(doc.coverPath!).uri;
        }

        // 2. Check if cover file exists in cache directory
        final coverDir = await _pathService.getCoversDirectory();
        final fileHash =
            md5.convert(utf8.encode(filePath)).toString().substring(0, 8);
        final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final coverFile = File(
          p.join(coverDir.path, 'cover_${safeName}_$fileHash.jpg'),
        );
        if (await coverFile.exists()) {
          return coverFile.uri;
        }

        // 3. Fallback to extract from active session
        if (_session != null && _session!.coverImagePath != null) {
          final bytes = await _session!.loadAsset(_session!.coverImagePath!);
          if (bytes != null && bytes.isNotEmpty) {
            await coverFile.writeAsBytes(bytes, flush: true);
            return coverFile.uri;
          }
        }
        return null;
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
        if (_session == null) {
          logger.w(
            '[ReaderRepository] loadAssetBytes: _session is null for asset: $assetPath',
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
          final resolved = await _session!.resolveAssetPath(pageIndex, decoded);
          final bytes = await _session!.loadAsset(resolved);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 2. Try direct decoded path
        var bytes = await _session!.loadAsset(decoded);
        if (bytes != null && bytes.isNotEmpty) {
          cache(bytes);
          return bytes;
        }

        // 3. Try raw path
        if (cleanPath != decoded) {
          bytes = await _session!.loadAsset(cleanPath);
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
          bytes = await _session!.loadAsset(noSlash);
          if (bytes != null && bytes.isNotEmpty) {
            cache(bytes);
            return bytes;
          }
        }

        // 5. Try basename fallback
        final base = p.posix.basename(decoded);
        bytes = await _session!.loadAsset(base);
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
      () async => _session != null ? await _session!.resolveSectionIndex(uri) : null,
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
    ReadingAnchor? anchor,
  }) {
    return TaskEither.tryCatch(
      () async {
        final docsResult = await _libraryRepository.getRecentDocuments().run();
        final docs = docsResult.getOrElse((_) => []);
        final doc = docs.where((d) => d.path == path).firstOrNull;
        if (doc != null) {
          final chapter = anchor?.chapterIndex ?? page;
          final isFinished = pageCount > 0 && chapter >= pageCount - 1;
          final updated = doc.copyWith(
            lastReadPage: page,
            pageCount: pageCount,
            lastReadChapter: anchor?.chapterIndex ?? doc.lastReadChapter,
            lastReadProgression:
                anchor?.progressionInChapter ?? doc.lastReadProgression,
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
  TaskEither<Failure, ReadingAnchor?> getLastReadAnchor(String path) {
    return TaskEither.tryCatch(
      () async {
        final docsResult = await _libraryRepository.getRecentDocuments().run();
        final docs = docsResult.getOrElse((_) => []);
        final doc = docs.where((d) => d.path == path).firstOrNull;
        if (doc == null) return null;
        final hasAnchor =
            doc.lastReadChapter > 0 || doc.lastReadProgression > 0.0;
        if (!hasAnchor) return null;
        return ReadingAnchor(
          chapterIndex: doc.lastReadChapter,
          progressionInChapter: doc.lastReadProgression,
        );
      },
      (error, stack) => DatabaseFailure(
        'Failed to get last read anchor: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> closeDocument() {
    return TaskEither.tryCatch(
      () async {
        final session = _session;
        _session = null;
        _assetCache.clear();
        if (session != null) {
          await session.dispose();
        }
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
