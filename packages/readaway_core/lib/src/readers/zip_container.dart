import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../errors/document_exception.dart';

/// Reads a generic ZIP container using `package:archive`.
///
/// The container is decoded once into memory; individual entries are
/// decompressed lazily on first access via [readEntry].
///
/// Used by ZIP-based formats such as EPUB ([EpubContainer]) and CBZ
/// ([CbzDocumentReader]).
class ZipContainer {
  final Map<String, ArchiveFile> _entriesByName;
  bool _disposed = false;

  ZipContainer._(this._entriesByName);

  /// Opens the ZIP container at [filePath].
  ///
  /// [formatName] is used in error messages (e.g. `EPUB`, `CBZ`).
  static ZipContainer openFile(String filePath, {String formatName = 'ZIP'}) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('$formatName file not found: $filePath');
    }
    final bytes = file.readAsBytesSync();
    return openBytes(bytes, formatName: formatName);
  }

  /// Opens a ZIP container from raw [bytes].
  static ZipContainer openBytes(Uint8List bytes, {String formatName = 'ZIP'}) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = <String, ArchiveFile>{};
      for (final file in archive.files) {
        if (file.isFile) {
          entries[_normalize(file.name)] = file;
        }
      }
      if (entries.isEmpty) {
        throw DocumentParseException(
          'Invalid $formatName container: no entries',
        );
      }
      return ZipContainer._(entries);
    } on ArchiveException catch (e) {
      throw DocumentParseException('Invalid $formatName container', cause: e);
    }
  }

  /// Normalizes an entry path: backslashes to slashes, strips leading `/`.
  static String _normalize(String name) {
    var n = name.replaceAll('\\', '/');
    while (n.startsWith('/')) {
      n = n.substring(1);
    }
    return n;
  }

  /// Whether the container has an entry at [path].
  bool hasEntry(String path) => _entriesByName.containsKey(_normalize(path));

  /// Reads the raw bytes of the entry at [path], or `null` if absent.
  Uint8List? readEntry(String path) {
    _checkNotDisposed();
    final file = _entriesByName[_normalize(path)];
    if (file == null) return null;
    return file.content as Uint8List?;
  }

  /// Lists all entry paths in the container.
  List<String> listEntries() => _entriesByName.keys.toList();

  /// Releases the container. Must not be used afterwards.
  void dispose() {
    _disposed = true;
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw DocumentDisposedException('$runtimeType has been disposed');
    }
  }
}
