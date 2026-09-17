import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/hive/app_storage_service.dart';
import '../../../settings/domain/entity/reader_preferences.dart';
import '../../domain/repositories/reader_preferences_repository.dart';

@LazySingleton(as: ReaderPreferencesRepository)
class ReaderPreferencesRepositoryImpl implements ReaderPreferencesRepository {
  final AppStorageService _storage;

  static const String _globalKey = 'reader_global';
  static String _docKey(String path) => 'reader_doc_$path';

  ReaderPreferencesRepositoryImpl(this._storage);

  @override
  TaskEither<Failure, ReaderPreferences> getGlobalPreferences() {
    return TaskEither.tryCatch(
      () async =>
          _storage.readerBox.get(_globalKey) ?? const ReaderPreferences(),
      (error, stack) => StorageReadFailure(
        _globalKey,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> saveGlobalPreferences(ReaderPreferences prefs) {
    return TaskEither.tryCatch(
      () async {
        await _storage.readerBox.put(_globalKey, prefs);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        _globalKey,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Option<ReaderPreferences>> getDocumentPreferences(
    String path,
  ) {
    return TaskEither.tryCatch(
      () async => Option.fromNullable(_storage.readerBox.get(_docKey(path))),
      (error, stack) => StorageReadFailure(
        _docKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> saveDocumentPreferences(
    String path,
    ReaderPreferences prefs,
  ) {
    return TaskEither.tryCatch(
      () async {
        await _storage.readerBox.put(_docKey(path), prefs);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        _docKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> clearDocumentPreferences(String path) {
    return TaskEither.tryCatch(
      () async {
        await _storage.readerBox.delete(_docKey(path));
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        _docKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> resetAllPreferences() {
    return TaskEither.tryCatch(
      () async {
        await _storage.readerBox.clear();
        return unit;
      },
      (error, stack) => StorageResetFailure(
        'Failed to reset reader preferences: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> importGlobalPreferences(ReaderPreferences prefs) {
    return TaskEither.tryCatch(
      () async {
        await _storage.readerBox.put(_globalKey, prefs);
        return unit;
      },
      (error, stack) => StorageWriteFailure(
        _globalKey,
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
