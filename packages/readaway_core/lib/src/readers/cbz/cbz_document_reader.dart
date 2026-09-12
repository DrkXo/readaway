import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../abstracts/pdf_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../models/models.dart';
import '../zip_container.dart';
import 'natural_sort.dart';

/// Pure-Dart CBZ (Comic Book ZIP) implementation of [PdfDocumentReader].
///
/// A CBZ is a ZIP archive of page images (JPEG, PNG, WebP, GIF, BMP, TIFF).
/// Each image is one fixed-layout page. Page order follows the natural sort of
/// the image entry names so that `page2` precedes `page10`.
class CbzDocumentReader implements PdfDocumentReader {
  /// Image extensions treated as pages.
  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.tif',
    '.tiff',
  };

  final ZipContainer _container;
  final List<String> _pagePaths;
  final String? _title;
  bool _disposed = false;

  CbzDocumentReader._({
    required this._container,
    required this._pagePaths,
    required this._title,
  });

  /// Opens a CBZ document from [filePath].
  static CbzDocumentReader fromFile(String filePath) {
    final container = ZipContainer.openFile(filePath, formatName: 'CBZ');
    try {
      return _open(container, title: p.basenameWithoutExtension(filePath));
    } catch (_) {
      container.dispose();
      rethrow;
    }
  }

  /// Opens a CBZ document from raw [bytes].
  static CbzDocumentReader fromBytes(Uint8List bytes) {
    final container = ZipContainer.openBytes(bytes, formatName: 'CBZ');
    try {
      return _open(container, title: null);
    } catch (_) {
      container.dispose();
      rethrow;
    }
  }

  static CbzDocumentReader _open(ZipContainer container, {String? title}) {
    final pagePaths = _findPages(container);
    if (pagePaths.isEmpty) {
      throw DocumentParseException('No image pages found in CBZ');
    }
    return CbzDocumentReader._(
      container: container,
      pagePaths: pagePaths,
      title: title,
    );
  }

  /// Whether [path] names a page image (by extension).
  static bool isImagePath(String path) =>
      _imageExtensions.contains(p.extension(path).toLowerCase());

  /// Collects image entries, sorted naturally.
  static List<String> _findPages(ZipContainer container) {
    final pages = <String>[];
    for (final path in container.listEntries()) {
      if (isImagePath(path)) {
        pages.add(path);
      }
    }
    pages.sort(naturalCompare);
    return pages;
  }

  @override
  String get format => 'cbz';

  @override
  bool get isReflowable => false;

  @override
  String? get title => _title;

  @override
  DocumentMetadata? get metadata => null;

  @override
  List<OutlineItem> get outline => const [];

  @override
  String? get coverImagePath => _pagePaths.isEmpty ? null : _pagePaths.first;

  @override
  int get pageCount => _pagePaths.length;

  @override
  Uint8List? loadAsset(String assetPath) {
    _checkNotDisposed();
    return _container.readEntry(assetPath);
  }

  @override
  Future<RenderedPage> renderPage(
    int index, {
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool alpha = false,
    int colorSpace = 0,
  }) async {
    _checkNotDisposed();
    if (index < 0 || index >= _pagePaths.length) {
      throw RangeError.range(index, 0, _pagePaths.length - 1, 'index');
    }
    final bytes = _container.readEntry(_pagePaths[index]);
    if (bytes == null || bytes.isEmpty) {
      throw DocumentParseException(
        'Page $index is empty: ${_pagePaths[index]}',
      );
    }
    // ALWAYS decode in a background isolate — full-res scans are CPU/memory
    // heavy and must never block the calling isolate.
    return Isolate.run(
      () => _decodePage(bytes, scaleX: scaleX, scaleY: scaleY),
    );
  }

  /// Decodes [bytes] to a [RenderedPage]. Runs in a background isolate.
  static RenderedPage _decodePage(
    Uint8List bytes, {
    required double scaleX,
    required double scaleY,
  }) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      throw DocumentParseException('Unsupported or corrupt page image');
    }
    if (decoded == null) {
      throw DocumentParseException('Unsupported or corrupt page image');
    }
    var image = decoded;
    if (scaleX != 1.0 || scaleY != 1.0) {
      final width = (image.width * scaleX).round().clamp(1, 1 << 30);
      final height = (image.height * scaleY).round().clamp(1, 1 << 30);
      image = img.copyResize(image, width: width, height: height);
    }
    final rgba = image.convert(numChannels: 4);
    final pixels = rgba.getBytes(order: img.ChannelOrder.rgba);
    return RenderedPage(
      width: rgba.width,
      height: rgba.height,
      stride: rgba.width * 4,
      components: 4,
      pixels: pixels,
    );
  }

  @override
  Future<String> extractText(int index) async => '';

  @override
  Future<String> extractHtml(int index, {bool preserveImages = false}) async {
    _checkNotDisposed();
    if (index < 0 || index >= _pagePaths.length) {
      throw RangeError.range(index, 0, _pagePaths.length - 1, 'index');
    }
    final path = _pagePaths[index];
    final bytes = _container.readEntry(path);
    if (bytes == null || bytes.isEmpty) {
      return '<html><body></body></html>';
    }
    final base64 = base64Encode(bytes);
    final mime = _mimeFor(path);
    return '<html><body><img src="data:$mime;base64,$base64" /></body></html>';
  }

  @override
  Future<List<SearchHit>> search(int index, String needle) async => const [];

  @override
  Future<List<PageLink>> pageLinks(int index) async => const [];

  @override
  Future<int?> resolvePage(String href) async => null;

  @override
  void dispose() {
    _disposed = true;
    _container.dispose();
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw DocumentDisposedException('CbzDocumentReader has been disposed');
    }
  }

  static String _mimeFor(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.tif':
      case '.tiff':
        return 'image/tiff';
      default:
        return 'application/octet-stream';
    }
  }
}
