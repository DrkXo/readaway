import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../abstracts/document_reader.dart';
import '../errors/document_exception.dart';
import '../models/models.dart';
import '../rust/api/document.dart' as doc_api;
import '../rust/rust_init.dart';

/// High-performance CBZ comic document reader backed by native Rust.
class RustCbzDocumentReader implements DocumentReader {
  final String filePath;
  final List<String> _pagePaths;
  final String? _title;
  final Map<int, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _assetCache = {};
  bool _disposed = false;

  RustCbzDocumentReader._({
    required this.filePath,
    required List<String> pagePaths,
    this._title,
  })  : _pagePaths = List.unmodifiable(pagePaths);

  /// Opens a CBZ comic archive from [filePath].
  static Future<RustCbzDocumentReader> open(String filePath) async {
    await ensureRustInitialized();
    final pagePaths = doc_api.getCbzPagePaths(path: filePath);

    if (pagePaths.isEmpty) {
      throw const DocumentParseException('No image pages found in CBZ');
    }
    return RustCbzDocumentReader._(
      filePath: filePath,
      pagePaths: pagePaths,
      title: p.basenameWithoutExtension(filePath),
    );
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
  String? get coverImagePath => _pagePaths.isNotEmpty ? _pagePaths.first : null;

  /// Total number of pages in the comic.
  int get pageCount => _pagePaths.length;

  /// List of image asset paths in page order.
  List<String> get pagePaths => List.unmodifiable(_pagePaths);

  @override
  Uint8List? loadAsset(String assetPath) {
    if (_disposed) return null;
    final cached = _assetCache[assetPath];
    if (cached != null) return cached;

    try {
      final bytes = doc_api.readCbzAssetSync(
        path: filePath,
        assetPath: assetPath,
      );
      _assetCache[assetPath] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Loads image bytes for page at [pageIndex] synchronously.
  Uint8List loadPageSync(int pageIndex) {
    if (_disposed) {
      throw const DocumentDisposedException('Document disposed');
    }
    if (pageIndex < 0 || pageIndex >= _pagePaths.length) {
      throw RangeError.range(pageIndex, 0, _pagePaths.length - 1, 'pageIndex');
    }
    final cached = _imageCache[pageIndex];
    if (cached != null) return cached;

    final bytes = doc_api.readCbzPageImageSync(
      path: filePath,
      pageIndex: BigInt.from(pageIndex),
    );
    _imageCache[pageIndex] = bytes;
    return bytes;
  }

  /// Loads image bytes for page at [pageIndex] asynchronously.
  Future<Uint8List> loadPage(int pageIndex) async {
    return loadPageSync(pageIndex);
  }

  @override
  void dispose() {
    _disposed = true;
    _imageCache.clear();
    _assetCache.clear();
  }
}

/// Compatibility typedef for drop-in replacement of readaway_core's CbzDocumentReader.
typedef CbzDocumentReader = RustCbzDocumentReader;

