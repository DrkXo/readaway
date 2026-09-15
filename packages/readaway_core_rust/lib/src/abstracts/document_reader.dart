import 'dart:typed_data';
import '../models/document_metadata.dart';
import '../models/outline_item.dart';

/// Unified interface for all document types (reflowable and fixed-layout).
abstract class DocumentReader {
  /// Canonical format identifier (e.g. `epub`, `cbz`, `html`, `txt`).
  String get format;

  /// Whether the document reflows its content rather than presenting fixed pages.
  bool get isReflowable;

  /// Document title, if available.
  String? get title;

  /// Bibliographic metadata, if available.
  DocumentMetadata? get metadata;

  /// Hierarchical table of contents / outline.
  List<OutlineItem> get outline;

  /// Path of the cover image asset, if declared.
  String? get coverImagePath;

  /// Loads raw bytes for an embedded asset at [assetPath].
  Uint8List? loadAsset(String assetPath);

  /// Releases any resources or caches held by this reader.
  void dispose();
}
