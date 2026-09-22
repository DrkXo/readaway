import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../errors/document_exception.dart';

/// Unified interface for accessing archived comic book containers (ZIP, TAR, RAR, 7Z).
abstract class ComicArchiveAdapter {
  /// Ordered list of normalized relative paths for all image pages.
  List<String> listImageEntries();

  /// Reads raw bytes for an archive entry at [entryPath].
  Uint8List? loadEntryBytes(String entryPath);

  /// Reads the raw text content of `ComicInfo.xml` if present in the archive.
  String? loadComicInfoXml();

  /// Closes and releases any held streams or memory buffers.
  void dispose();

  /// Normalized check for image extensions.
  static bool isImageFile(String name) {
    final lower = name.toLowerCase();
    return (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.avif') ||
            lower.endsWith('.bmp')) &&
        !lower.contains('__macosx') &&
        !p.basename(lower).startsWith('.');
  }

  /// Normalizes archive internal paths.
  static String normalizePath(String path) {
    var pStr = path.replaceAll(r'\', '/').trim();
    while (pStr.startsWith('/')) {
      pStr = pStr.substring(1);
    }
    return p.posix.normalize(pStr);
  }

  /// Natural alphanumeric sorting comparator (e.g. `page_1.jpg` before `page_10.jpg`).
  static int compareAlphanumeric(String a, String b) {
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

/// Pure Dart ZIP archive adapter for `.cbz` and `.zip` comic books.
class ZipComicArchiveAdapter implements ComicArchiveAdapter {
  final Map<String, ArchiveFile> _entriesByName;
  final InputFileStream? _inputStream;
  final List<String> _imageEntries;
  final String? _comicInfoXml;

  ZipComicArchiveAdapter._({
    required this._entriesByName,
    required List<String> imageEntries,
    this._inputStream,
    this._comicInfoXml,
  })  : _imageEntries = List.unmodifiable(imageEntries);

  /// Creates a [ZipComicArchiveAdapter] from a file at [filePath].
  static Future<ZipComicArchiveAdapter> fromFile(
    String filePath, {
    String? password,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('CBZ file not found: $filePath');
    }

    final stream = InputFileStream(filePath);
    try {
      final archive = ZipDecoder().decodeStream(stream, verify: false, password: password);
      return _build(archive, inputStream: stream);
    } on ArchiveException catch (e) {
      await stream.close();
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') || msg.contains('encrypted') || msg.contains('decrypt')) {
        throw DocumentEncryptedException(
          'Encrypted CBZ archive: $e',
          isInvalidPassword: password != null,
          cause: e,
        );
      }
      throw DocumentParseException('Failed to parse CBZ zip archive: $e', cause: e);
    } catch (e) {
      await stream.close();
      throw DocumentParseException('Failed to parse CBZ zip archive: $e', cause: e);
    }
  }

  /// Creates a [ZipComicArchiveAdapter] from in-memory [bytes].
  static Future<ZipComicArchiveAdapter> fromBytes(
    Uint8List bytes, {
    String? password,
  }) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false, password: password);
      return _build(archive);
    } on ArchiveException catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('password') || msg.contains('encrypted') || msg.contains('decrypt')) {
        throw DocumentEncryptedException(
          'Encrypted CBZ archive: $e',
          isInvalidPassword: password != null,
          cause: e,
        );
      }
      throw DocumentParseException('Failed to parse CBZ zip archive: $e', cause: e);
    } catch (e) {
      throw DocumentParseException('Failed to parse CBZ zip archive: $e', cause: e);
    }
  }

  static ZipComicArchiveAdapter _build(
    Archive archive, {
    InputFileStream? inputStream,
  }) {
    final entries = <String, ArchiveFile>{};
    final images = <String>[];
    String? comicInfo;

    for (final entry in archive) {
      if (entry.isFile) {
        final norm = ComicArchiveAdapter.normalizePath(entry.name);
        entries[norm] = entry;
        entries[entry.name] = entry;

        if (ComicArchiveAdapter.isImageFile(entry.name)) {
          images.add(norm);
        } else if (norm.toLowerCase().endsWith('comicinfo.xml')) {
          try {
            final raw = entry.readBytes();
            if (raw != null) {
              comicInfo = utf8.decode(raw, allowMalformed: true);
            }
          } catch (_) {}
        }
      }
    }

    if (images.isEmpty) {
      throw const DocumentParseException('No image pages found in CBZ archive');
    }

    images.sort(ComicArchiveAdapter.compareAlphanumeric);

    return ZipComicArchiveAdapter._(
      entriesByName: entries,
      imageEntries: images,
      inputStream: inputStream,
      comicInfoXml: comicInfo,
    );
  }

  @override
  List<String> listImageEntries() => _imageEntries;

  @override
  Uint8List? loadEntryBytes(String entryPath) {
    final norm = ComicArchiveAdapter.normalizePath(entryPath);
    final file = _entriesByName[norm] ?? _entriesByName[entryPath];
    if (file == null) return null;
    return file.readBytes();
  }

  @override
  String? loadComicInfoXml() => _comicInfoXml;

  @override
  void dispose() {
    _entriesByName.clear();
    _inputStream?.close();
  }
}

/// Pure Dart TAR archive adapter for `.cbt` and `.tar` comic books.
class TarComicArchiveAdapter implements ComicArchiveAdapter {
  final Map<String, ArchiveFile> _entriesByName;
  final List<String> _imageEntries;
  final String? _comicInfoXml;

  TarComicArchiveAdapter._({
    required this._entriesByName,
    required List<String> imageEntries,
    this._comicInfoXml,
  })  : _imageEntries = List.unmodifiable(imageEntries);

  /// Creates a [TarComicArchiveAdapter] from a file at [filePath].
  static Future<TarComicArchiveAdapter> fromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('CBT file not found: $filePath');
    }
    final rawBytes = await file.readAsBytes();
    return fromBytes(rawBytes);
  }

  /// Creates a [TarComicArchiveAdapter] from in-memory [bytes].
  static Future<TarComicArchiveAdapter> fromBytes(Uint8List bytes) async {
    Uint8List tarBytes = bytes;
    final extLower = bytes.length > 2 && bytes[0] == 0x1F && bytes[1] == 0x8B;
    if (extLower) {
      try {
        tarBytes = Uint8List.fromList(GZipDecoder().decodeBytes(bytes));
      } catch (_) {}
    } else if (bytes.length > 3 && bytes[0] == 0x42 && bytes[1] == 0x5A && bytes[2] == 0x68) {
      try {
        tarBytes = Uint8List.fromList(BZip2Decoder().decodeBytes(bytes));
      } catch (_) {}
    }

    try {
      final archive = TarDecoder().decodeBytes(tarBytes);
      final entries = <String, ArchiveFile>{};
      final images = <String>[];
      String? comicInfo;

      for (final entry in archive) {
        if (entry.isFile) {
          final norm = ComicArchiveAdapter.normalizePath(entry.name);
          entries[norm] = entry;
          entries[entry.name] = entry;

          if (ComicArchiveAdapter.isImageFile(entry.name)) {
            images.add(norm);
          } else if (norm.toLowerCase().endsWith('comicinfo.xml')) {
            try {
              final raw = entry.readBytes();
              if (raw != null) {
                comicInfo = utf8.decode(raw, allowMalformed: true);
              }
            } catch (_) {}
          }
        }
      }

      if (images.isEmpty) {
        throw const DocumentParseException('No image pages found in CBT archive');
      }

      images.sort(ComicArchiveAdapter.compareAlphanumeric);

      return TarComicArchiveAdapter._(
        entriesByName: entries,
        imageEntries: images,
        comicInfoXml: comicInfo,
      );
    } catch (e) {
      throw DocumentParseException('Failed to parse CBT tar archive: $e', cause: e);
    }
  }

  @override
  List<String> listImageEntries() => _imageEntries;

  @override
  Uint8List? loadEntryBytes(String entryPath) {
    final norm = ComicArchiveAdapter.normalizePath(entryPath);
    final file = _entriesByName[norm] ?? _entriesByName[entryPath];
    if (file == null) return null;
    return file.readBytes();
  }

  @override
  String? loadComicInfoXml() => _comicInfoXml;

  @override
  void dispose() {
    _entriesByName.clear();
  }
}

/// Fallback / FFI bridge adapter for `.cbr` (RAR) archives.
class RarComicArchiveAdapter implements ComicArchiveAdapter {
  final String filePath;

  RarComicArchiveAdapter(this.filePath);

  @override
  List<String> listImageEntries() => throw UnsupportedFormatException(
        'CBR (RAR) archives require native unrar bridge plugin.',
      );

  @override
  Uint8List? loadEntryBytes(String entryPath) => null;

  @override
  String? loadComicInfoXml() => null;

  @override
  void dispose() {}
}

/// Fallback / FFI bridge adapter for `.cb7` (7z) archives.
class SevenZipComicArchiveAdapter implements ComicArchiveAdapter {
  final String filePath;

  SevenZipComicArchiveAdapter(this.filePath);

  @override
  List<String> listImageEntries() => throw UnsupportedFormatException(
        'CB7 (7z) archives require native 7z bridge plugin.',
      );

  @override
  Uint8List? loadEntryBytes(String entryPath) => null;

  @override
  String? loadComicInfoXml() => null;

  @override
  void dispose() {}
}
