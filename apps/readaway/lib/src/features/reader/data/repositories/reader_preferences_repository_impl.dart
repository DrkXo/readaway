import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
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
  Future<Result<ReaderPreferences>> getGlobalPreferences() {
    return guard(
      () async =>
          _storage.readerBox.get(_globalKey) ?? const ReaderPreferences(),
      onError: (error, stack) => StorageReadFailure(
        _globalKey,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> saveGlobalPreferences(ReaderPreferences prefs) {
    return guard(
      () async {
        await _storage.readerBox.put(_globalKey, prefs);
      },
      onError: (error, stack) => StorageWriteFailure(
        _globalKey,
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<ReaderPreferences?>> getDocumentPreferences(String path) {
    return guard(
      () async => _storage.readerBox.get(_docKey(path)),
      onError: (error, stack) => StorageReadFailure(
        _docKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> saveDocumentPreferences(
    String path,
    ReaderPreferences prefs,
  ) {
    return guard(
      () async {
        await _storage.readerBox.put(_docKey(path), prefs);
      },
      onError: (error, stack) => StorageWriteFailure(
        _docKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> clearDocumentPreferences(String path) {
    return guard(
      () async {
        await _storage.readerBox.delete(_docKey(path));
      },
      onError: (error, stack) => StorageWriteFailure(
        _docKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> resetAllPreferences() {
    return guard(
      () async {
        await _storage.readerBox.clear();
      },
      onError: (error, stack) => StorageResetFailure(
        'Failed to reset reader preferences: $error',
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> importGlobalPreferences(ReaderPreferences prefs) {
    return guard(
      () async {
        await _storage.readerBox.put(_globalKey, prefs);
      },
      onError: (error, stack) => StorageWriteFailure(
        _globalKey,
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
