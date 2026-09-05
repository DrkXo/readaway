import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../settings/domain/entity/reader_preferences.dart';

/// Contract for persisting and retrieving user reading preferences.
abstract interface class ReaderPreferencesRepository {
  /// Fetches global reading preferences.
  TaskEither<Failure, ReaderPreferences> getGlobalPreferences();

  /// Saves global reading preferences.
  TaskEither<Failure, Unit> saveGlobalPreferences(ReaderPreferences prefs);

  /// Fetches document-specific reading preferences.
  TaskEither<Failure, Option<ReaderPreferences>> getDocumentPreferences(String path);

  /// Saves document-specific reading preferences.
  TaskEither<Failure, Unit> saveDocumentPreferences(String path, ReaderPreferences prefs);

  /// Resets all reading preferences in storage.
  TaskEither<Failure, Unit> resetAllPreferences();

  /// Imports and overrides global reading preferences.
  TaskEither<Failure, Unit> importGlobalPreferences(ReaderPreferences prefs);
}

