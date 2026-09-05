import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/hive/app_storage_service.dart';
import '../../../settings/domain/entity/reader_preferences.dart';
import '../../domain/repositories/reader_preferences_repository.dart';

@LazySingleton(as: ReaderPreferencesRepository)
class ReaderPreferencesRepositoryImpl implements ReaderPreferencesRepository {
  final AppStorageService _storage;

  ReaderPreferencesRepositoryImpl(this._storage);

  @override
  TaskEither<Failure, ReaderPreferences> getGlobalPreferences() {
    return TaskEither.tryCatch(
      () => _storage.readReaderGlobalPrefs(),
      (error, stack) => StorageReadFailure(
        'reader_global',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> saveGlobalPreferences(ReaderPreferences prefs) {
    return TaskEither.tryCatch(
      () async {
        await _storage.writeReaderGlobalPrefs(prefs);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'reader_global',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Option<ReaderPreferences>> getDocumentPreferences(String path) {
    return TaskEither.tryCatch(
      () async {
        final prefs = await _storage.readReaderDocumentPrefs(path);
        return Option.fromNullable(prefs);
      },
      (error, stack) => StorageReadFailure(
        'reader_doc_$path',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> saveDocumentPreferences(String path, ReaderPreferences prefs) {
    return TaskEither.tryCatch(
      () async {
        await _storage.writeReaderDocumentPrefs(path, prefs);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'reader_doc_$path',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> resetAllPreferences() {
    return TaskEither.tryCatch(
      () async {
        await _storage.resetStorage();
        return unit;
      },
      (error, stack) => StorageResetFailure(
        'Failed to reset storage: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> importGlobalPreferences(ReaderPreferences prefs) {
    return TaskEither.tryCatch(
      () async {
        await _storage.writeReaderGlobalPrefs(prefs);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        'reader_global',
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}

