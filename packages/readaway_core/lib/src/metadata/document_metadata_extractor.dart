import 'dart:typed_data';

import '../isolate/document_session.dart';
import '../logger/app_logger.dart';
import '../models/models.dart';

/// Aggregated metadata extracted from a document.
class ExtractedDocumentMetadata {
  final String filePath;
  final String title;
  final String? author;
  final int pageCount;
  final int sectionCount;
  final String? coverImagePath;
  final Uint8List? coverImageBytes;
  final bool isReflowable;
  final String format;
  final DocumentMetadata? metadata;
  final List<OutlineItem> outline;

  const ExtractedDocumentMetadata({
    required this.filePath,
    required this.title,
    this.author,
    required this.pageCount,
    required this.sectionCount,
    this.coverImagePath,
    this.coverImageBytes,
    required this.isReflowable,
    required this.format,
    this.metadata,
    this.outline = const [],
  });
}

/// Standalone high-performance metadata and cover image extractor.
///
/// Runs via [DocumentSession] to prevent blocking the UI thread and ensures
/// fast, memory-safe metadata extraction with thumbnail scaling.
class DocumentMetadataExtractor {
  static final _log = AppLogger.instance.scope('DocumentMetadataExtractor');

  const DocumentMetadataExtractor._();

  /// Extracts comprehensive metadata and cover image bytes from [filePath]
  /// inside a dedicated session.
  ///
  /// [thumbnailWidth] specifies the target width for rendered page covers (e.g. PDF/comics).
  static Future<ExtractedDocumentMetadata> extract(
    String filePath, {
    String? password,
    int thumbnailWidth = 480,
  }) async {
    _log.i('Extracting metadata for document: $filePath');
    final session = await DocumentSession.open(
      filePath,
      password: password,
    );
    try {
      final metaTitle = session.title;
      final rawTitle =
          (metaTitle != null && metaTitle.trim().isNotEmpty)
              ? metaTitle.trim()
              : '';
      final author =
          (session.metadata?.author?.trim().isNotEmpty == true)
              ? session.metadata!.author!.trim()
              : (session.metadata?.creator?.trim().isNotEmpty == true)
              ? session.metadata!.creator!.trim()
              : null;

      final count =
          session.isReflowable ? session.sectionCount : session.pageCount;

      Uint8List? coverBytes;
      final coverImgPath = session.coverImagePath;

      if (coverImgPath != null && coverImgPath.isNotEmpty) {
        if (coverImgPath.startsWith('page:')) {
          final pageIndex = int.tryParse(coverImgPath.substring(5)) ?? 0;
          try {
            coverBytes = await session.loadPageImage(
              pageIndex,
              targetWidth: thumbnailWidth,
            );
          } catch (e, st) {
            _log.w(
              'Failed to render page cover for $filePath',
              error: e,
              stackTrace: st,
            );
          }
        } else {
          try {
            coverBytes = await session.loadAsset(coverImgPath);
          } catch (e, st) {
            _log.w(
              'Failed to load asset cover for $filePath',
              error: e,
              stackTrace: st,
            );
          }
          if ((coverBytes == null || coverBytes.isEmpty) &&
              !session.isReflowable &&
              session.pageCount > 0) {
            try {
              coverBytes = await session.loadPageImage(
                0,
                targetWidth: thumbnailWidth,
              );
            } catch (_) {}
          }
        }
      } else if (!session.isReflowable && session.pageCount > 0) {
        try {
          coverBytes = await session.loadPageImage(
            0,
            targetWidth: thumbnailWidth,
          );
        } catch (_) {}
      }

      _log.i(
        'Metadata extracted successfully for $filePath (title: "$rawTitle", pages: $count, hasCover: ${coverBytes != null})',
      );

      return ExtractedDocumentMetadata(
        filePath: filePath,
        title: rawTitle,
        author: author,
        pageCount: count,
        sectionCount: session.sectionCount,
        coverImagePath: coverImgPath,
        coverImageBytes: coverBytes,
        isReflowable: session.isReflowable,
        format: session.format,
        metadata: session.metadata,
        outline: session.outline,
      );
    } finally {
      await session.dispose();
    }
  }
}
