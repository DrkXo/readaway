import 'dart:typed_data';

import '../zip_container.dart';

/// Reads an EPUB (ZIP) container using `package:archive`.
///
/// Thin wrapper over [ZipContainer] with EPUB-specific error messages. The
/// container is decoded once into memory; individual entries are decompressed
/// lazily on first access via [readEntry].
class EpubContainer {
  final ZipContainer _container;

  EpubContainer._(this._container);

  /// Opens the EPUB container at [filePath].
  static EpubContainer openFile(String filePath) =>
      EpubContainer._(ZipContainer.openFile(filePath, formatName: 'EPUB'));

  /// Opens an EPUB container from raw [bytes].
  static EpubContainer openBytes(Uint8List bytes) =>
      EpubContainer._(ZipContainer.openBytes(bytes, formatName: 'EPUB'));

  /// Whether the container has an entry at [path].
  bool hasEntry(String path) => _container.hasEntry(path);

  /// Reads the raw bytes of the entry at [path], or `null` if absent.
  Uint8List? readEntry(String path) => _container.readEntry(path);

  /// Lists all entry paths in the container.
  List<String> listEntries() => _container.listEntries();

  /// Releases the container. Must not be used afterwards.
  void dispose() => _container.dispose();
}
