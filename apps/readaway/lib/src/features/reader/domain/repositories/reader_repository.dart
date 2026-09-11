import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entity/reader_document_info.dart';
import '../entity/reader_page_data.dart';

import '../../../settings/domain/entity/reader_preferences.dart';

export '../entity/reader_document_info.dart';
export '../entity/reader_page_data.dart';
export '../../../settings/domain/entity/reader_preferences.dart';

/// Abstract contract for reading, loading, and parsing documents.
abstract interface class ReaderRepository {
  /// Opens a document at [path] and extracts its metadata and outline.
  TaskEither<Failure, ReaderDocumentInfo> openDocument(
    String path, {
    String? defaultTitle,
    ReaderEngineMode engineMode = ReaderEngineMode.customFlow,
  });

  /// Loads the structured page content at [pageIndex].
  TaskEither<Failure, ReaderPageData> loadPage(
    int pageIndex, {
    required bool isReflowable,
    ReaderEngineMode engineMode = ReaderEngineMode.customFlow,
  });

  /// Converts a page number between [ReaderEngineMode.customFlow] (spine chapter)
  /// and [ReaderEngineMode.publisherFidelity] (MuPDF layout page).
  TaskEither<Failure, int> convertPagePosition({
    required int currentPage,
    required ReaderEngineMode fromMode,
    required ReaderEngineMode toMode,
  });

  /// Returns the total page count for a given [engineMode].
  TaskEither<Failure, int> getPageCountForMode(ReaderEngineMode engineMode);

  /// Extracts plain text from the page at [pageIndex] (for TTS and analysis).
  TaskEither<Failure, String> extractPageText(int pageIndex);

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

  /// Resolves an internal document destination URI to a 0-based flat page index.
  TaskEither<Failure, int> resolveLink(String uri);

  /// Retrieves raw binary content for an embedded asset at [assetPath] (e.g. image, font).
  ///
  /// Optionally supply [pageIndex] to resolve relative URIs against the chapter/section.
  TaskEither<Failure, Uint8List?> loadAssetBytes(String assetPath, {int? pageIndex});

  /// Resolves an internal link or chapter href to a section/chapter index in a reflowable document.
  TaskEither<Failure, int?> resolveReflowableLink(String uri);


  /// Updates saved reading progress for the document at [path].
  TaskEither<Failure, Unit> updateReadingProgress({
    required String path,
    required int page,
    required int pageCount,
  });

  /// Retrieves the saved last read page index for the document at [path].
  TaskEither<Failure, int> getLastReadPage(String path);

  /// Closes the currently opened document.
  TaskEither<Failure, Unit> closeDocument();
}
