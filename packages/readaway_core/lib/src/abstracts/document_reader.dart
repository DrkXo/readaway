import 'dart:typed_data';

import '../models/models.dart';

/// Unified interface for all document types (reflowable and fixed-layout).
///
/// Concrete readers:
/// - [ReflowableDocumentReader] — EPUB, HTML, plain text (section-based).
/// - [PdfDocumentReader] — fixed-layout documents (page-based).
///
/// All methods are synchronous and safe to call from any isolate; heavy
/// operations (e.g. PDF rendering) are exposed as `Future`s on the
/// page-based interface so callers can offload them.
abstract class DocumentReader {
  /// Canonical format identifier (e.g. `epub`, `pdf`, `html`, `txt`).
  String get format;

  /// Whether the document reflows its content (EPUB/HTML/TXT) rather than
  /// presenting fixed pages (PDF/XPS).
  bool get isReflowable;

  /// Document title, if available.
  String? get title;

  /// Bibliographic metadata, if available.
  DocumentMetadata? get metadata;

  /// Hierarchical table of contents / outline.
  List<OutlineItem> get outline;

  /// Path of the cover image asset, if the document declares one.
  String? get coverImagePath;

  /// Loads raw bytes for an embedded asset at [assetPath].
  ///
  /// Returns `null` when the asset does not exist.
  Uint8List? loadAsset(String assetPath);

  /// Releases any file handles or caches held by this reader.
  ///
  /// The reader must not be used after disposal.
  void dispose();
}
