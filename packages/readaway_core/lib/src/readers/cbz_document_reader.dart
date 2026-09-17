import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../abstracts/document_reader.dart';
import '../errors/document_exception.dart';
import '../lifecycle/disposable.dart';
import '../models/models.dart';

/// High-performance pure Dart CBZ comic document reader with natural sorting.
class CbzDocumentReader with DisposableMixin implements DocumentReader {
  final String filePath;
  final List<String> _pagePaths;
  final String? _title;
  final Map<String, ArchiveFile> _entriesByName;
  final InputFileStream? _inputStream;
  final Map<int, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _assetCache = {};

  CbzDocumentReader._({
    required this.filePath,
    required List<String> pagePaths,
    required this._entriesByName,
    this._title,
    this._inputStream,
  }) : _pagePaths = List.unmodifiable(pagePaths);

  /// Opens a CBZ comic archive from [filePath].
  static Future<CbzDocumentReader> open(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('CBZ file not found: $filePath');
    }
    final stream = InputFileStream(filePath);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(stream, verify: false);
    } catch (e) {
      await stream.close();
      throw DocumentParseException('Failed to parse CBZ zip archive: $e');
    }
    return _fromArchive(
      archive,
      filePath: filePath,
      inputStream: stream,
    );
  }

  /// Opens a CBZ comic archive from in-memory [bytes].
  static Future<CbzDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'comic.cbz',
  }) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (e) {
      throw DocumentParseException('Failed to parse CBZ zip archive: $e');
    }
    return _fromArchive(archive, filePath: filePath);
  }

  static Future<CbzDocumentReader> _fromArchive(
    Archive archive, {
    required String filePath,
    InputFileStream? inputStream,
  }) async {
    final entriesByName = <String, ArchiveFile>{};
    final imagePaths = <String>[];

    for (final entry in archive) {
      if (entry.isFile) {
        entriesByName[entry.name] = entry;
        final norm = _normalizePath(entry.name);
        entriesByName[norm] = entry;

        if (_isImageFile(entry.name)) {
          imagePaths.add(norm);
        }
      }
    }

    if (imagePaths.isEmpty) {
      throw const DocumentParseException('No image pages found in CBZ');
    }

    // Natural alphanumeric sort
    imagePaths.sort(_compareAlphanumeric);

    return CbzDocumentReader._(
      filePath: filePath,
      pagePaths: imagePaths,
      entriesByName: entriesByName,
      title: p.basenameWithoutExtension(filePath),
      inputStream: inputStream,
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
  List<String> get pagePaths => _pagePaths;

  @override
  Uint8List? loadAsset(String assetPath) {
    if (isDisposed) return null;
    final cached = _assetCache[assetPath];
    if (cached != null) return cached;

    final norm = _normalizePath(assetPath);
    final file = _entriesByName[norm] ?? _entriesByName[assetPath];
    if (file == null) return null;

    final bytes = _extractBytes(file);
    _assetCache[assetPath] = bytes;
    _assetCache[norm] = bytes;
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
  void dispose() {
    super.dispose();
    _imageCache.clear();
    _assetCache.clear();
    _entriesByName.clear();
    _inputStream?.close();
  }

  static Uint8List _extractBytes(ArchiveFile file) {
    return file.readBytes() ?? Uint8List(0);
  }

  static bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif')) &&
        !lower.contains('__macosx') &&
        !p.basename(lower).startsWith('.');
  }

  static String _normalizePath(String path) {
    var pStr = path.replaceAll(r'\', '/').trim();
    while (pStr.startsWith('/')) {
      pStr = pStr.substring(1);
    }
    return p.posix.normalize(pStr);
  }

  static int _compareAlphanumeric(String a, String b) {
    final aTokens = _tokenize(a);
    final bTokens = _tokenize(b);
    final minLen = aTokens.length < bTokens.length
        ? aTokens.length
        : bTokens.length;

    for (var i = 0; i < minLen; i++) {
      final tokenA = aTokens[i];
      final tokenB = bTokens[i];

      final numA = int.tryParse(tokenA);
      final numB = int.tryParse(tokenB);

      if (numA != null && numB != null) {
        final cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
      } else {
        final cmp = tokenA.toLowerCase().compareTo(tokenB.toLowerCase());
        if (cmp != 0) return cmp;
      }
    }
    return aTokens.length.compareTo(bTokens.length);
  }

  static List<String> _tokenize(String str) {
    final tokens = <String>[];
    final regex = RegExp(r'(\d+|\D+)');
    for (final match in regex.allMatches(str)) {
      final s = match.group(0);
      if (s != null && s.isNotEmpty) tokens.add(s);
    }
    return tokens;
  }
}
