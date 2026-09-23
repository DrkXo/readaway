import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';

import '../../../../core/result/result.dart';
import '../entity/reader_document_info.dart';
import '../entity/reader_page_data.dart';

export '../entity/reader_document_info.dart';
export '../entity/reader_page_data.dart';

/// Abstract contract for reading, loading, and parsing documents.
abstract interface class ReaderRepository {
  /// Opens a document at [path] with optional [password] and extracts its metadata and outline.
  Future<Result<ReaderDocumentInfo>> openDocument(
    String path, {
    String? defaultTitle,
    String? password,
  });

  /// Loads the structured page content at [pageIndex] for reflowable documents.
  Future<Result<ReaderPageData>> loadPage(int pageIndex);

  /// Loads the rasterized page image at [pageIndex] for fixed-layout documents.
  Future<Result<Uint8List>> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  });

  /// Retrieves dimensions for the page at [pageIndex] in fixed-layout documents.
  Future<Result<PageSize?>> getPageSize(int pageIndex);

  /// Extracts plain text from the page at [pageIndex] (for display and analysis).
  Future<Result<String>> extractPageText(int pageIndex);

  /// Extracts speech-conditioned plain text from the page at [pageIndex] (for natural TTS playback).
  Future<Result<String>> extractSpeechText(int pageIndex);

  /// Attempts to resolve a footnote from [url] within the current or targeted section.
  Future<Result<FootnoteItem?>> resolveFootnote(
    String url, {
    int? currentChapterIndex,
  });

  /// Resolves cover art URI for the current document.
  Future<Result<Uri?>> getCoverArtUri({
    required String filePath,
    required String fileName,
    required int pageCount,
  });

  /// Sets the application window title to [title] or restores default if null.
  Future<Result<void>> updateWindowTitle(String? title);

  /// Requests notification/foreground permissions required for background audio playback.
  Future<Result<bool>> requestAudioPermissions();

  /// Retrieves raw binary content for an embedded asset at [assetPath] (e.g. image, font).
  ///
  /// Optionally supply [pageIndex] to resolve relative URIs against the chapter/section.
  Future<Result<Uint8List?>> loadAssetBytes(
    String assetPath, {
    int? pageIndex,
  });

  /// Resolves an internal link or chapter href to a section/chapter index in a reflowable document.
  Future<Result<int?>> resolveReflowableLink(String uri);

  /// Updates saved reading progress for the document at [path].
  ///
  /// [page] is the last read page (chapter index in continuous mode, global
  /// page in paged mode). [anchor] is the stable reflow-independent position;
  /// when non-null it is persisted and used for progress and restore. When
  /// null, any previously stored anchor is preserved.
  Future<Result<void>> updateReadingProgress({
    required String path,
    required int page,
    required int pageCount,
    ReadingAnchor? anchor,
  });

  /// Retrieves the saved last read page index for the document at [path].
  Future<Result<int>> getLastReadPage(String path);

  /// Retrieves the saved stable reading anchor for the document at [path],
  /// or `null` when none has been saved yet.
  Future<Result<ReadingAnchor?>> getLastReadAnchor(String path);

  /// Closes the currently opened document.
  Future<Result<void>> closeDocument();
}
