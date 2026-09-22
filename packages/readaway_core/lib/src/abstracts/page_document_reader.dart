import 'dart:typed_data';

import '../models/models.dart';
import 'document_reader.dart';

/// A document with fixed page layouts (PDF, Comic Book Archives CBZ/CBR/CB7/CBT).
abstract class PageDocumentReader implements DocumentReader {
  /// Total number of pages in the fixed-layout document.
  int get pageCount;

  /// Retrieves dimensions (width, height, aspect ratio) of the page at [pageIndex].
  PageSize? getPageSize(int pageIndex);

  /// Loads / renders the image for [pageIndex] at [scale] or target dimensions.
  ///
  /// Returns encoded image bytes (e.g. PNG/JPEG) or raw pixel buffer.
  Future<Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  });

  /// Synchronous access to cached page image bytes if already decoded/rendered in memory.
  Uint8List? getCachedPageImage(int pageIndex);
}
