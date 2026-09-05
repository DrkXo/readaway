import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entity/reader_document_info.dart';
import '../entity/reader_page_data.dart';

export '../entity/reader_document_info.dart';
export '../entity/reader_page_data.dart';

/// Abstract contract for reading, loading, and parsing documents.
abstract interface class ReaderRepository {
  /// Opens a document at [path] and extracts its metadata and outline.
  TaskEither<Failure, ReaderDocumentInfo> openDocument(String path, {String? defaultTitle});

  /// Loads the structured page content at [pageIndex].
  TaskEither<Failure, ReaderPageData> loadPage(int pageIndex, {required bool isReflowable});

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

  /// Closes the currently opened document.
  TaskEither<Failure, Unit> closeDocument();
}
