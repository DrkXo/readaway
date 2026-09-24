import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../abstracts/page_document_reader.dart';
import '../errors/document_exception.dart';
import '../lifecycle/disposable.dart';
import '../models/models.dart';
import 'comic/comic_archive_adapter.dart';
import 'comic/comic_info_parser.dart';
import 'comic/comic_toc_extractor.dart';
import 'comic/image_header_parser.dart';

/// High-performance comic document reader supporting CBZ, CBT, CBR, and CB7 containers.
class ComicBookDocumentReader
    with DisposableMixin
    implements PageDocumentReader {
  final String filePath;
  final String _format;
  final ComicArchiveAdapter _adapter;
  final List<String> _pagePaths;
  final String? _title;
  final DocumentMetadata? _metadata;
  final List<OutlineItem> _outline;

  final Map<int, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _assetCache = {};
  final Map<int, PageSize> _pageSizeCache = {};

  ComicBookDocumentReader._({
    required this.filePath,
    required this._format,
    required this._adapter,
    required List<String> pagePaths,
    this._title,
    this._metadata,
    List<OutlineItem> outline = const [],
  }) : _pagePaths = List.unmodifiable(pagePaths),
       _outline = List.unmodifiable(outline);

  /// Opens a comic document archive from [filePath].
  static Future<ComicBookDocumentReader> open(
    String filePath, {
    String? password,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('Comic archive not found: $filePath');
    }

    final ext = p.extension(filePath).toLowerCase();
    final ComicArchiveAdapter adapter;
    final String format;

    if (ext == '.cbt' || ext == '.tar') {
      format = 'cbt';
      adapter = await TarComicArchiveAdapter.fromFile(filePath);
    } else if (ext == '.cbr' || ext == '.rar') {
      format = 'cbr';
      adapter = RarComicArchiveAdapter(filePath);
    } else if (ext == '.cb7' || ext == '.7z') {
      format = 'cb7';
      adapter = SevenZipComicArchiveAdapter(filePath);
    } else {
      // Default to CBZ / ZIP
      format = 'cbz';
      adapter = await ZipComicArchiveAdapter.fromFile(
        filePath,
        password: password,
      );
    }

    return _build(filePath: filePath, format: format, adapter: adapter);
  }

  /// Opens a comic document from in-memory [bytes].
  static Future<ComicBookDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'comic.cbz',
    String? password,
  }) async {
    final ext = p.extension(filePath).toLowerCase();
    final ComicArchiveAdapter adapter;
    final String format;

    if (ext == '.cbt' || ext == '.tar') {
      format = 'cbt';
      adapter = await TarComicArchiveAdapter.fromBytes(bytes);
    } else {
      format = 'cbz';
      adapter = await ZipComicArchiveAdapter.fromBytes(
        bytes,
        password: password,
      );
    }

    return _build(filePath: filePath, format: format, adapter: adapter);
  }

  static ComicBookDocumentReader _build({
    required String filePath,
    required String format,
    required ComicArchiveAdapter adapter,
  }) {
    final imagePaths = adapter.listImageEntries();
    if (imagePaths.isEmpty) {
      adapter.dispose();
      throw const DocumentParseException(
        'No image pages found in comic archive',
      );
    }

    String? title = p.basenameWithoutExtension(filePath);
    DocumentMetadata? metadata;
    final outline = <OutlineItem>[];

    final xmlContent = adapter.loadComicInfoXml();
    if (xmlContent != null && xmlContent.isNotEmpty) {
      final comicInfo = ComicInfoParser.parse(xmlContent);
      if (comicInfo != null) {
        metadata = comicInfo.toDocumentMetadata();
        if (comicInfo.title != null && comicInfo.title!.isNotEmpty) {
          title = comicInfo.title;
        } else if (comicInfo.series != null) {
          title = '${comicInfo.series} ${comicInfo.number ?? ''}'.trim();
        }

        for (final page in comicInfo.pages) {
          if (page.bookmark != null &&
              page.bookmark!.isNotEmpty &&
              page.imageIndex >= 0 &&
              page.imageIndex < imagePaths.length) {
            outline.add(
              OutlineItem(
                title: page.bookmark!,
                href: 'page:${page.imageIndex}',
                chapterIndex: page.imageIndex,
              ),
            );
          }
        }
      }
    }

    if (outline.isEmpty) {
      outline.addAll(ComicTocExtractor.extract(imagePaths));
    }

    return ComicBookDocumentReader._(
      filePath: filePath,
      format: format,
      adapter: adapter,
      pagePaths: imagePaths,
      title: title,
      metadata: metadata,
      outline: outline,
    );
  }

  @override
  String get format => _format;

  @override
  bool get isReflowable => false;

  @override
  String? get title => _title;

  @override
  DocumentMetadata? get metadata => _metadata;

  @override
  List<OutlineItem> get outline => _outline;

  @override
  String? get coverImagePath => _pagePaths.isNotEmpty ? _pagePaths.first : null;

  @override
  int get pageCount => _pagePaths.length;

  /// Ordered list of image asset paths in the archive.
  List<String> get pagePaths => _pagePaths;

  @override
  PageSize? getPageSize(int pageIndex) {
    checkNotDisposed('getPageSize');
    if (pageIndex < 0 || pageIndex >= _pagePaths.length) return null;
    final cached = _pageSizeCache[pageIndex];
    if (cached != null) return cached;

    final bytes = loadAsset(_pagePaths[pageIndex]);
    if (bytes != null && bytes.isNotEmpty) {
      final size = ImageHeaderParser.parseDimensions(bytes);
      if (size != null) {
        _pageSizeCache[pageIndex] = size;
        return size;
      }
    }
    return null;
  }

  @override
  Uint8List? loadAsset(String assetPath) {
    if (isDisposed) return null;
    final cached = _assetCache[assetPath];
    if (cached != null) return cached;

    final bytes = _adapter.loadEntryBytes(assetPath);
    if (bytes != null) {
      _assetCache[assetPath] = bytes;
    }
    return bytes;
  }

  /// Loads image bytes for page at [pageIndex] synchronously.
  Uint8List loadPageSync(int pageIndex) {
    checkNotDisposed('loadPageSync');
    if (pageIndex < 0 || pageIndex >= _pagePaths.length) {
      throw RangeError.range(pageIndex, 0, _pagePaths.length - 1, 'pageIndex');
    }
    final cached = _imageCache[pageIndex];
    if (cached != null) return cached;

    final path = _pagePaths[pageIndex];
    final bytes = loadAsset(path);
    if (bytes == null) {
      throw DocumentParseException(
        'Failed to load page image at index $pageIndex: $path',
      );
    }
    _imageCache[pageIndex] = bytes;
    return bytes;
  }

  /// Loads image bytes for page at [pageIndex] asynchronously.
  Future<Uint8List> loadPage(int pageIndex) async => loadPageSync(pageIndex);

  @override
  Future<Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    return loadPageSync(pageIndex);
  }

  @override
  Uint8List? getCachedPageImage(int pageIndex) => _imageCache[pageIndex];

  @override
  void dispose() {
    super.dispose();
    _imageCache.clear();
    _assetCache.clear();
    _pageSizeCache.clear();
    _adapter.dispose();
  }
}

/// Backwards compatibility alias for [ComicBookDocumentReader].
typedef CbzDocumentReader = ComicBookDocumentReader;
