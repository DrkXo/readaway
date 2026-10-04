import 'dart:io';

import 'package:crypto/crypto.dart';
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

  /// Legacy per-book key kept for records saved before content-based identity.
  static String _legacyDocKey(String path) => 'reader_doc_$path';

  /// Content-based per-book key so settings follow an unchanged book across
  /// moves and renames. Identical copies intentionally share the same key.
  static String _contentDocKey(String fingerprint) =>
      'reader_doc_sha256_$fingerprint';

  /// Cached SHA-256 digests keyed by path, invalidated when the file's size or
  /// modification time changes. Avoids re-hashing a whole book on every
  /// preference update during rapid slider drags.
  final Map<String, ({int size, DateTime modified, String fingerprint})>
  _fingerprintCache = {};

  ReaderPreferencesRepositoryImpl(this._storage);

  Future<String?> _contentFingerprint(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final stat = await file.stat();
    final cached = _fingerprintCache[path];
    if (cached != null &&
        cached.size == stat.size &&
        cached.modified == stat.modified) {
      return cached.fingerprint;
    }
    final fingerprint = (await sha256.bind(file.openRead()).first).toString();
    _fingerprintCache[path] = (
      size: stat.size,
      modified: stat.modified,
      fingerprint: fingerprint,
    );
    return fingerprint;
  }

  Future<String> _docKey(String path) async {
    final fingerprint = await _contentFingerprint(path);
    return fingerprint == null
        ? _legacyDocKey(path)
        : _contentDocKey(fingerprint);
  }

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
  Future<Result<ReaderPreferences?>> getDocumentPreferences(String path) async {
    return guard(
      () async {
        final legacyKey = _legacyDocKey(path);
        final fingerprint = await _contentFingerprint(path);
        if (fingerprint == null) {
          return _storage.readerBox.get(legacyKey);
        }
        final contentKey = _contentDocKey(fingerprint);
        final current = _storage.readerBox.get(contentKey);
        if (current != null) return current;

        // Migrate legacy path-keyed preferences only when the source file is
        // available and its content provides a confident identity.
        final legacy = _storage.readerBox.get(legacyKey);
        if (legacy != null) await _storage.readerBox.put(contentKey, legacy);
        return legacy;
      },
      onError: (error, stack) => StorageReadFailure(
        _legacyDocKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> saveDocumentPreferences(
    String path,
    ReaderPreferences prefs,
  ) async {
    return guard(
      () async {
        await _storage.readerBox.put(await _docKey(path), prefs);
      },
      onError: (error, stack) => StorageWriteFailure(
        _legacyDocKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> clearDocumentPreferences(String path) async {
    return guard(
      () async {
        await _storage.readerBox.delete(await _docKey(path));
        await _storage.readerBox.delete(_legacyDocKey(path));
      },
      onError: (error, stack) => StorageWriteFailure(
        _legacyDocKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }

  @override
  Future<Result<void>> resetAllPreferences() {
    return guard(
      () async {
        _fingerprintCache.clear();
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
