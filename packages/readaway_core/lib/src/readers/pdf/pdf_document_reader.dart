import 'dart:io';
import 'dart:typed_data';

import 'package:cacherine/cacherine.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import '../../abstracts/page_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../lifecycle/disposable.dart';
import '../../logger/app_logger.dart';
import '../../models/models.dart';
import 'pdf_engine_manager.dart';
import 'pdf_image_encoder.dart';
import 'pdf_toc_extractor.dart';

final _log = AppLogger.instance.scope('PdfDocumentReader');

typedef _CacheKey = (
  int pageIndex,
  double scale,
  int? targetWidth,
  int? targetHeight,
);

/// The cache key for a page rendered at its natural size — the "default"
/// render used for covers and for `getCachedPageImage`.
_CacheKey _defaultRenderKey(int pageIndex) => (pageIndex, 1.0, null, null);

/// High-performance PDF reader backed by pdfrx / PDFium.
class PdfDocumentReader with DisposableMixin implements PageDocumentReader {
  final String filePath;
  final PdfDocument _pdfDoc;
  final String? _title;
  final DocumentMetadata? _metadata;
  final List<OutlineItem> _outline;

  final SimpleLRUCache<_CacheKey, Uint8List> _pageCache;
  final Map<int, PageSize> _pageSizeCache;
  Uint8List? _coverBytes;

  PdfDocumentReader._({
    required this.filePath,
    required this._pdfDoc,
    required this._pageSizeCache,
    int imageCacheSize = 10,
    this._title,
    this._metadata,
    List<OutlineItem> outline = const [],
  }) : _pageCache = SimpleLRUCache<_CacheKey, Uint8List>(
         // cacherine rejects a non-positive cap outright, whereas the old
         // hand-rolled cache quietly held a single entry for `0`. Clamp so this
         // public parameter keeps behaving for existing callers.
         imageCacheSize < 1 ? 1 : imageCacheSize,
       ),
       _outline = List.unmodifiable(outline);

  static String? Function()? _buildPasswordProvider(String? password) {
    if (password == null) return null;
    var attempts = 0;
    return () {
      if (attempts++ == 0) return password;
      return null;
    };
  }

  /// Opens a PDF document from [filePath] with optional decryption [password].
  static Future<PdfDocumentReader> open(
    String filePath, {
    String? password,
    int imageCacheSize = 10,
  }) async {
    _log.i('Opening PDF file: $filePath');
    final file = File(filePath);
    if (!file.existsSync()) {
      _log.e('PDF file not found: $filePath');
      throw DocumentOpenException('PDF file not found: $filePath');
    }

    await PdfEngineManager.acquire();

    final passwordProvider = _buildPasswordProvider(password);

    try {
      final pdfDoc = await PdfDocument.openFile(
        filePath,
        passwordProvider: passwordProvider,
      );
      return await _fromPdfDocument(
        pdfDoc,
        filePath: filePath,
        imageCacheSize: imageCacheSize,
      );
    } on PdfPasswordException catch (e, st) {
      _log.w(
        'PDF requires password or password incorrect: $filePath',
        error: e,
        stackTrace: st,
      );
      await PdfEngineManager.release();
      throw DocumentEncryptedException(
        'Password required or incorrect for PDF: $filePath',
        isInvalidPassword: password != null,
        cause: e,
      );
    } catch (e, st) {
      _log.e(
        'Failed to open PDF document: $filePath',
        error: e,
        stackTrace: st,
      );
      await PdfEngineManager.release();
      if (e is DocumentException) rethrow;
      throw DocumentParseException('Failed to open PDF document: $e', cause: e);
    }
  }

  /// Opens a PDF document from in-memory [bytes] with optional decryption [password].
  static Future<PdfDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'document.pdf',
    String? password,
    int imageCacheSize = 10,
  }) async {
    _log.i('Opening PDF from bytes: $filePath (${bytes.length} bytes)');
    await PdfEngineManager.acquire();

    final passwordProvider = _buildPasswordProvider(password);

    try {
      final pdfDoc = await PdfDocument.openData(
        bytes,
        passwordProvider: passwordProvider,
      );
      return await _fromPdfDocument(
        pdfDoc,
        filePath: filePath,
        imageCacheSize: imageCacheSize,
      );
    } on PdfPasswordException catch (e, st) {
      _log.w(
        'PDF from bytes requires password: $filePath',
        error: e,
        stackTrace: st,
      );
      await PdfEngineManager.release();
      throw DocumentEncryptedException(
        'Password required or incorrect for PDF: $filePath',
        isInvalidPassword: password != null,
        cause: e,
      );
    } catch (e, st) {
      _log.e(
        'Failed to open PDF from bytes: $filePath',
        error: e,
        stackTrace: st,
      );
      await PdfEngineManager.release();
      if (e is DocumentException) rethrow;
      throw DocumentParseException('Failed to open PDF document: $e', cause: e);
    }
  }

  static Future<PdfDocumentReader> _fromPdfDocument(
    PdfDocument pdfDoc, {
    required String filePath,
    int imageCacheSize = 10,
  }) async {
    final title = p.basenameWithoutExtension(filePath);
    var outlineItems = <OutlineItem>[];

    final pageSizeCache = <int, PageSize>{};
    for (var i = 0; i < pdfDoc.pages.length; i++) {
      final page = pdfDoc.pages[i];
      pageSizeCache[i] = PageSize(width: page.width, height: page.height);
    }

    try {
      final outlineNodes = await pdfDoc.loadOutline();
      _convertOutlines(outlineNodes, outlineItems);
    } catch (e, st) {
      _log.w(
        'Failed to load native PDF outline for $filePath: $e',
        error: e,
        stackTrace: st,
      );
    }

    if (outlineItems.isEmpty) {
      try {
        outlineItems = await PdfTocExtractor.extract(pdfDoc);
      } catch (e, st) {
        _log.w(
          'Failed to extract TOC for $filePath: $e',
          error: e,
          stackTrace: st,
        );
      }
    }

    // A page-based document is still navigable page by page even without a
    // meaningful bookmark TOC, so fall back to one entry per page instead of
    // an empty or near-empty contents list (mirrors the comic reader's page
    // fallback). A single leaf bookmark — e.g. a stray figure anchor — is not
    // a real TOC.
    if (!PdfDocumentReader.hasUsableOutline(outlineItems) &&
        pdfDoc.pages.isNotEmpty) {
      outlineItems = PdfDocumentReader.buildPageOutline(pdfDoc.pages.length);
    }

    _log.i(
      'PDF loaded successfully: $filePath (${pdfDoc.pages.length} pages, outline: ${outlineItems.length})',
    );

    return PdfDocumentReader._(
      filePath: filePath,
      pdfDoc: pdfDoc,
      pageSizeCache: pageSizeCache,
      imageCacheSize: imageCacheSize,
      title: title,
      metadata: DocumentMetadata(title: title),
      outline: outlineItems,
    );
  }

  static void _convertOutlines(
    List<PdfOutlineNode> nodes,
    List<OutlineItem> targetList, {
    int level = 0,
  }) {
    for (final node in nodes) {
      final pageNumber = node.dest?.pageNumber;
      final pageIndex = pageNumber != null ? pageNumber - 1 : null;
      final childItems = <OutlineItem>[];
      if (node.children.isNotEmpty) {
        _convertOutlines(node.children, childItems, level: level + 1);
      }

      targetList.add(
        OutlineItem(
          title: node.title,
          href: pageIndex != null ? 'page:$pageIndex' : null,
          level: level,
          chapterIndex: pageIndex,
          children: childItems,
        ),
      );
    }
  }

  /// Flat, one-entry-per-page outline used when the document provides no
  /// native bookmarks and no scraped printed table of contents, so a
  /// non-reflowable document always has a navigable contents list (mirrors
  /// [ComicTocExtractor]'s page fallback).
  static List<OutlineItem> buildPageOutline(int pageCount) {
    return [
      for (var i = 0; i < pageCount; i++)
        OutlineItem(
          title: 'Page ${i + 1}',
          href: 'page:$i',
          level: 0,
          chapterIndex: i,
        ),
    ];
  }

  /// Whether [outline] is meaningful enough to serve as the document's TOC.
  ///
  /// A single leaf bookmark (e.g. a stray figure anchor) does not count, so a
  /// fixed-layout document carrying only one unusable bookmark falls back to a
  /// per-page outline instead.
  static bool hasUsableOutline(List<OutlineItem> outline) =>
      outline.isNotEmpty &&
      !(outline.length == 1 && outline.single.children.isEmpty);

  @override
  String get format => 'pdf';

  @override
  bool get isReflowable => false;

  @override
  String? get title => _title;

  @override
  DocumentMetadata? get metadata => _metadata;

  @override
  List<OutlineItem> get outline => _outline;

  @override
  String? get coverImagePath => 'page:0';

  @override
  int get pageCount => _pdfDoc.pages.length;

  @override
  PageSize? getPageSize(int pageIndex) {
    checkNotDisposed('getPageSize');
    if (pageIndex < 0 || pageIndex >= _pdfDoc.pages.length) return null;
    final cached = _pageSizeCache[pageIndex];
    if (cached != null) return cached;

    final page = _pdfDoc.pages[pageIndex];
    final size = PageSize(width: page.width, height: page.height);
    _pageSizeCache[pageIndex] = size;
    return size;
  }

  @override
  Uint8List? loadAsset(String assetPath) {
    if (isDisposed) return null;
    if (assetPath == 'page:0' || assetPath == 'cover') {
      return _coverBytes ?? _pageCache.get(_defaultRenderKey(0));
    }
    if (assetPath.startsWith('page:')) {
      final pageIndex = int.tryParse(assetPath.substring(5));
      if (pageIndex != null) {
        return _pageCache.get(_defaultRenderKey(pageIndex));
      }
    }
    return null;
  }

  @override
  Future<Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    checkNotDisposed('loadPageImage');
    if (pageIndex < 0 || pageIndex >= _pdfDoc.pages.length) {
      throw RangeError.range(
        pageIndex,
        0,
        _pdfDoc.pages.length - 1,
        'pageIndex',
      );
    }

    final cacheKey = (pageIndex, scale, targetWidth, targetHeight);
    final cached = _pageCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final page = _pdfDoc.pages[pageIndex];
    final width = targetWidth ?? (page.width * scale).toInt();
    final height = targetHeight ?? (page.height * scale).toInt();
    final renderWidth = width > 0 ? width : page.width.toInt();
    final renderHeight = height > 0 ? height : page.height.toInt();

    final pdfImage = await page.render(
      fullWidth: renderWidth.toDouble(),
      fullHeight: renderHeight.toDouble(),
      width: renderWidth,
      height: renderHeight,
    );

    if (pdfImage == null) {
      throw DocumentParseException('Failed to render PDF page $pageIndex');
    }

    final bytes = encodeBgraToBmp(
      pdfImage.pixels,
      width: pdfImage.width,
      height: pdfImage.height,
    );
    pdfImage.dispose();

    _pageCache.set(cacheKey, bytes);
    if (pageIndex == 0 &&
        scale == 1.0 &&
        targetWidth == null &&
        targetHeight == null) {
      _coverBytes = bytes;
    }
    return bytes;
  }

  @override
  Uint8List? getCachedPageImage(int pageIndex) =>
      _pageCache.peek(_defaultRenderKey(pageIndex));

  @override
  Future<void> dispose() async {
    if (isDisposed) return;
    _log.d('Disposing PdfDocumentReader for: $filePath');
    super.dispose();
    _pageCache.clear();
    _pageSizeCache.clear();
    _coverBytes = null;
    await _pdfDoc.dispose();
    await PdfEngineManager.release();
  }
}
