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
        if (_isMuPdfOpen) {
          await _muPdfService.closeDocument();
          _isMuPdfOpen = false;
        }

        _currentDocumentPath = path;

        final format = SupportedDocumentFormats.findFormat(path);
        final isReflowable = format?.isReflowable ?? false;

        List<OutlineItem> rawOutline = [];
        String? metaTitle;

        if (isReflowable) {
          try {
            _reflowReader = await ReflowableDocumentReader.fromFile(path);
          } catch (e) {
            logger.w('Failed to initialize ReflowableDocumentReader: $e');
            _reflowReader = null;
          }
        } else {
          _reflowReader = null;
        }

        if (!isReflowable || engineMode == ReaderEngineMode.publisherFidelity) {
          await _ensureMuPdfOpen();
          rawOutline = await _muPdfService.getOutLine();
          metaTitle = await _muPdfService.getMetaData('info:Title');
        } else {
          // Reflowable document in Custom Flow mode:
          // For EPUB, briefly extract rich TOC and metadata via MuPDF, then immediately
          // release the heavy background Fitz document from memory to avoid double loading.
          if (format == SupportedDocumentFormats.epub) {
            try {
              await _muPdfService.openDocument(path);
              rawOutline = await _muPdfService.getOutLine();
              metaTitle = await _muPdfService.getMetaData('info:Title');
            } catch (e) {
              logger.w('Could not extract EPUB metadata via MuPdfService: $e');
            } finally {
              await _muPdfService.closeDocument();
              _isMuPdfOpen = false;
            }
          }
        }

        final int pageCount;
        if (isReflowable &&
            engineMode == ReaderEngineMode.customFlow &&
            _reflowReader != null) {
          pageCount = _reflowReader!.sectionCount;
        } else {
          await _ensureMuPdfOpen();
          pageCount = await _muPdfService.getPageCount();
        }

        final List<OutlineItem> outline;
        if (isReflowable && _reflowReader != null) {
          if (rawOutline.isNotEmpty) {
            outline = rawOutline.map((item) {
              var chapter = item.chapter;
              if (chapter < 0 && item.uri != null && item.uri!.isNotEmpty) {
                final resolved = _reflowReader!.resolveSectionIndex(item.uri!);
                if (resolved != null) {
                  chapter = resolved;
                }
              }
              return OutlineItem(
                title: item.title,
                uri: item.uri,
                chapter: chapter,
                page: item.page,
                level: item.level,
                isOpen: item.isOpen,
              );
            }).toList();
          } else {
            outline = _reflowReader!.sections.map((sec) {
              return OutlineItem(
                title: sec.title ?? 'Chapter ${sec.index + 1}',
                uri: sec.href,
                chapter: sec.index,
                page: sec.index,
                level: 0,
                isOpen: false,
              );
            }).toList();
          }
        } else {
          outline = rawOutline;
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
        // Reflowable document in Custom Flow mode -> HyperRender
        if (isReflowable &&
            engineMode == ReaderEngineMode.customFlow &&
            _reflowReader != null) {
          if (pageIndex >= 0 && pageIndex < _reflowReader!.sectionCount) {
            final html = _reflowReader!.loadSectionHtml(pageIndex);
            return ReaderPageData(
              pageIndex: pageIndex,
              links: const [],
              html: html,
            );
          }
        }

        // Non-reflowable document (PDF, XPS, CBZ) or Publisher Fidelity -> MuPDF Native C
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
        if (fromMode == toMode || _reflowReader == null) {
          return currentPage;
        }

        await _ensureMuPdfOpen();

        if (fromMode == ReaderEngineMode.customFlow &&
            toMode == ReaderEngineMode.publisherFidelity) {
          final clampedSpine = currentPage.clamp(
            0,
            _reflowReader!.sectionCount - 1,
          );
          final mupdfPage = await _muPdfService.pageFromLocation(
            MuPdfLocation(chapter: clampedSpine, page: 0),
          );
          return mupdfPage >= 0 ? mupdfPage : 0;
        } else if (fromMode == ReaderEngineMode.publisherFidelity &&
            toMode == ReaderEngineMode.customFlow) {
          final loc = await _muPdfService.locationFromPage(currentPage);
          return loc.chapter.clamp(0, _reflowReader!.sectionCount - 1);
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
        if (_reflowReader != null &&
            engineMode == ReaderEngineMode.customFlow) {
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

        // 1. If pageIndex is provided, resolve relative to that section/chapter
        if (pageIndex != null && pageIndex >= 0) {
          final resolved = _reflowReader!.resolveAssetPath(pageIndex, decoded);
          final bytes = _reflowReader!.loadAssetBytes(resolved);
          if (bytes != null && bytes.isNotEmpty) return bytes;
        }

        // 2. Try direct decoded path
        var bytes = _reflowReader!.loadAssetBytes(decoded);
        if (bytes != null && bytes.isNotEmpty) return bytes;

        // 3. Try raw path
        if (cleanPath != decoded) {
          bytes = _reflowReader!.loadAssetBytes(cleanPath);
          if (bytes != null && bytes.isNotEmpty) return bytes;
        }

        // 4. Try path without leading slash
        final noSlash = decoded.startsWith('/')
            ? decoded.substring(1)
            : decoded;
        if (noSlash != decoded) {
          bytes = _reflowReader!.loadAssetBytes(noSlash);
          if (bytes != null && bytes.isNotEmpty) return bytes;
        }

        // 5. Try basename fallback
        final base = p.posix.basename(decoded);
        bytes = _reflowReader!.loadAssetBytes(base);
        if (bytes != null && bytes.isNotEmpty) return bytes;

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
