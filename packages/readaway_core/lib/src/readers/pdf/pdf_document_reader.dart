import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import '../../abstracts/page_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../lifecycle/disposable.dart';
import '../../models/models.dart';
import 'pdf_engine_manager.dart';

/// High-performance PDF reader backed by pdfrx / PDFium.
class PdfDocumentReader with DisposableMixin implements PageDocumentReader {
  final String filePath;
  final PdfDocument _pdfDoc;
  final String? _title;
  final DocumentMetadata? _metadata;
  final List<OutlineItem> _outline;

  final Map<int, Uint8List> _imageCache = {};
  final Map<int, PageSize> _pageSizeCache = {};
  Uint8List? _coverBytes;

  PdfDocumentReader._({
    required this.filePath,
    required this._pdfDoc,
    this._title,
    this._metadata,
    List<OutlineItem> outline = const [],
  }) : _outline = List.unmodifiable(outline);

  /// Opens a PDF document from [filePath] with optional decryption [password].
  static Future<PdfDocumentReader> open(
    String filePath, {
    String? password,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('PDF file not found: $filePath');
    }

    await PdfEngineManager.acquire();

    var attempts = 0;
    final String? Function()? passwordProvider = password != null
        ? () {
            if (attempts++ == 0) return password;
            return null;
          }
        : null;

    try {
      final pdfDoc = await PdfDocument.openFile(
        filePath,
        passwordProvider: passwordProvider,
      );
      return await _fromPdfDocument(pdfDoc, filePath: filePath);
    } on PdfPasswordException catch (e) {
      PdfEngineManager.release();
      throw DocumentEncryptedException(
        'Password required or incorrect for PDF: $filePath',
        isInvalidPassword: password != null,
        cause: e,
      );
    } catch (e) {
      PdfEngineManager.release();
      if (e is DocumentException) rethrow;
      throw DocumentParseException('Failed to open PDF document: $e', cause: e);
    }
  }

  /// Opens a PDF document from in-memory [bytes] with optional decryption [password].
  static Future<PdfDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'document.pdf',
    String? password,
  }) async {
    await PdfEngineManager.acquire();

    var attempts = 0;
    final String? Function()? passwordProvider = password != null
        ? () {
            if (attempts++ == 0) return password;
            return null;
          }
        : null;

    try {
      final pdfDoc = await PdfDocument.openData(
        bytes,
        passwordProvider: passwordProvider,
      );
      return await _fromPdfDocument(pdfDoc, filePath: filePath);
    } on PdfPasswordException catch (e) {
      PdfEngineManager.release();
      throw DocumentEncryptedException(
        'Password required or incorrect for PDF: $filePath',
        isInvalidPassword: password != null,
        cause: e,
      );
    } catch (e) {
      PdfEngineManager.release();
      if (e is DocumentException) rethrow;
      throw DocumentParseException('Failed to open PDF document: $e', cause: e);
    }
  }

  static Future<PdfDocumentReader> _fromPdfDocument(
    PdfDocument pdfDoc, {
    required String filePath,
  }) async {
    final title = p.basenameWithoutExtension(filePath);
    final outlineItems = <OutlineItem>[];

    try {
      final outlineNodes = await pdfDoc.loadOutline();
      _convertOutlines(outlineNodes, outlineItems);
    } catch (_) {}

    return PdfDocumentReader._(
      filePath: filePath,
      pdfDoc: pdfDoc,
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
      return _coverBytes;
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

    final cached = _imageCache[pageIndex];
    if (cached != null &&
        scale == 1.0 &&
        targetWidth == null &&
        targetHeight == null) {
      return cached;
    }

    final page = _pdfDoc.pages[pageIndex];
    final width = targetWidth ?? (page.width * scale).toInt();
    final height = targetHeight ?? (page.height * scale).toInt();

    final pdfImage = await page.render(
      width: width > 0 ? width : page.width.toInt(),
      height: height > 0 ? height : page.height.toInt(),
    );

    if (pdfImage == null) {
      throw DocumentParseException('Failed to render PDF page $pageIndex');
    }

    final bytes = Uint8List.fromList(pdfImage.pixels);
    pdfImage.dispose();

    if (scale == 1.0 && targetWidth == null && targetHeight == null) {
      _imageCache[pageIndex] = bytes;
      if (pageIndex == 0) {
        _coverBytes = bytes;
      }
    }
    return bytes;
  }

  @override
  Uint8List? getCachedPageImage(int pageIndex) => _imageCache[pageIndex];

  @override
  void dispose() {
    if (isDisposed) return;
    super.dispose();
    _imageCache.clear();
    _pageSizeCache.clear();
    _coverBytes = null;
    _pdfDoc.dispose();
    PdfEngineManager.release();
  }
}
