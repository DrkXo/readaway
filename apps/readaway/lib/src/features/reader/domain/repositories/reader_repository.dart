import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../entity/reader_document_info.dart';
import '../entity/reader_page_data.dart';

export '../entity/reader_document_info.dart';
export '../entity/reader_page_data.dart';

/// Abstract contract for reading, loading, and parsing documents.
abstract interface class ReaderRepository {
  /// Opens a document at [path] and extracts its metadata and outline.
  TaskEither<Failure, ReaderDocumentInfo> openDocument(
    String path, {
    String? defaultTitle,
  });

  /// Loads the structured page content at [pageIndex].
  TaskEither<Failure, ReaderPageData> loadPage(int pageIndex);

  /// Extracts plain text from the page at [pageIndex] (for display and analysis).
  TaskEither<Failure, String> extractPageText(int pageIndex);

  /// Extracts speech-conditioned plain text from the page at [pageIndex] (for natural TTS playback).
  TaskEither<Failure, String> extractSpeechText(int pageIndex);

  /// Attempts to resolve a footnote from [url] within the current or targeted section.
  TaskEither<Failure, Option<FootnoteItem>> resolveFootnote(
    String url, {
    int? currentChapterIndex,
  });

  /// Resolves cover art URI for the current document.
  TaskEither<Failure, Uri?> getCoverArtUri({
    required String filePath,
    required String fileName,
    required int pageCount,
  });

  /// Sets the application window title to [title] or restores default if null.
  TaskEither<Failure, Unit> updateWindowTitle(String? title);

  /// Requests notification/foreground permissions required for background audio playback.
  TaskEither<Failure, bool> requestAudioPermissions();

  /// Retrieves raw binary content for an embedded asset at [assetPath] (e.g. image, font).
  ///
  /// Optionally supply [pageIndex] to resolve relative URIs against the chapter/section.
  TaskEither<Failure, Uint8List?> loadAssetBytes(
    String assetPath, {
    int? pageIndex,
  });

  /// Resolves an internal link or chapter href to a section/chapter index in a reflowable document.
  TaskEither<Failure, int?> resolveReflowableLink(String uri);

  /// Updates saved reading progress for the document at [path].
  ///
  /// [page] is the last read page (chapter index in continuous mode, global
  /// page in paged mode). [anchor] is the stable reflow-independent position;
  /// when non-null it is persisted and used for progress and restore. When
  /// null, any previously stored anchor is preserved.
  TaskEither<Failure, Unit> updateReadingProgress({
    required String path,
    required int page,
    required int pageCount,
    ReadingAnchor? anchor,
  });

  /// Retrieves the saved last read page index for the document at [path].
  TaskEither<Failure, int> getLastReadPage(String path);

  /// Retrieves the saved stable reading anchor for the document at [path],
  /// or `null` when none has been saved yet.
  TaskEither<Failure, ReadingAnchor?> getLastReadAnchor(String path);

  /// Closes the currently opened document.
  TaskEither<Failure, Unit> closeDocument();
}
