import 'dart:io';
import 'dart:typed_data';

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

final class _LruPageCache {
  final int maxSize;
  final _entries = <_CacheKey, Uint8List>{};

  _LruPageCache(this.maxSize);

  Uint8List? get(_CacheKey key) {
    final v = _entries.remove(key);
    if (v != null) {
      _entries[key] = v;
    }
    return v;
  }

  void put(_CacheKey key, Uint8List value) {
    _entries.remove(key);
    while (_entries.length >= maxSize && _entries.isNotEmpty) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = value;
  }

  Uint8List? getDefaultRender(int pageIndex) =>
      get((pageIndex, 1.0, null, null));

  void clear() => _entries.clear();
}

/// High-performance PDF reader backed by pdfrx / PDFium.
class PdfDocumentReader with DisposableMixin implements PageDocumentReader {
  final String filePath;
  final PdfDocument _pdfDoc;
  final String? _title;
  final DocumentMetadata? _metadata;
  final List<OutlineItem> _outline;

  final _LruPageCache _pageCache;
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
  }) : _pageCache = _LruPageCache(imageCacheSize),
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
      return _coverBytes ?? _pageCache.getDefaultRender(0);
    }
    if (assetPath.startsWith('page:')) {
      final pageIndex = int.tryParse(assetPath.substring(5));
      if (pageIndex != null) {
        return _pageCache.getDefaultRender(pageIndex);
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

    final bytes = encodeBgraToPng(
      pdfImage.pixels,
      width: pdfImage.width,
      height: pdfImage.height,
    );
    pdfImage.dispose();

    _pageCache.put(cacheKey, bytes);
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
      _pageCache.getDefaultRender(pageIndex);

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
