import '../../../../core/result/result.dart';
import '../../../settings/domain/entity/reader_preferences.dart';

/// Contract for persisting and retrieving user reading preferences.
abstract interface class ReaderPreferencesRepository {
  /// Fetches global reading preferences.
  Future<Result<ReaderPreferences>> getGlobalPreferences();

  /// Saves global reading preferences.
  Future<Result<void>> saveGlobalPreferences(ReaderPreferences prefs);

  /// Fetches document-specific reading preferences.
  Future<Result<ReaderPreferences?>> getDocumentPreferences(String path);

  /// Saves document-specific reading preferences.
  Future<Result<void>> saveDocumentPreferences(
    String path,
    ReaderPreferences prefs,
  );

  /// Removes document-specific reading preferences so the document falls back
  /// to the global preferences.
  Future<Result<void>> clearDocumentPreferences(String path);

  /// Resets all reading preferences in storage.
  Future<Result<void>> resetAllPreferences();

  /// Imports and overrides global reading preferences.
  Future<Result<void>> importGlobalPreferences(ReaderPreferences prefs);
}
