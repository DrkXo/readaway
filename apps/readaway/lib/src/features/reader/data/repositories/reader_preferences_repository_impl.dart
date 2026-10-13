import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/storage/drift/daos/reader_preferences_dao.dart';
import '../../domain/entity/reader_preferences.dart';
import '../../domain/repositories/reader_preferences_repository.dart';

@LazySingleton(as: ReaderPreferencesRepository)
class ReaderPreferencesRepositoryImpl implements ReaderPreferencesRepository {
  final ReaderPreferencesDao _prefs;

  static const String _globalKey = 'reader_global';

  /// Legacy per-book identity: the path itself, used only when the file cannot
  /// be hashed (also kept as the error-label convention of this repository).
  static String _legacyDocKey(String path) => 'reader_doc_$path';

  /// Cached SHA-256 digests keyed by path, invalidated when the file's size or
  /// modification time changes. Avoids re-hashing a whole book on every
  /// preference update during rapid slider drags.
  final Map<String, ({int size, DateTime modified, String fingerprint})>
  _fingerprintCache = {};

  ReaderPreferencesRepositoryImpl(this._prefs);

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

  @override
  Future<Result<ReaderPreferences>> getGlobalPreferences() {
    return guard(
      () async =>
          await _prefs.get(
            scope: ReaderPreferencesDao.globalScope,
            ownerKey: ReaderPreferencesDao.globalOwnerKey,
          ) ??
          const ReaderPreferences(),
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
        await _prefs.put(
          scope: ReaderPreferencesDao.globalScope,
          ownerKind: 'global',
          ownerKey: ReaderPreferencesDao.globalOwnerKey,
          prefs: prefs,
        );
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
        final fingerprint = await _contentFingerprint(path);
        if (fingerprint == null) {
          return _prefs.get(
            scope: ReaderPreferencesDao.readerScope,
            ownerKey: path,
          );
        }
        final current = await _prefs.get(
          scope: ReaderPreferencesDao.readerScope,
          ownerKey: fingerprint,
        );
        if (current != null) return current;

        // Migrate legacy path-keyed preferences only when the source file is
        // available and its content provides a confident identity.
        final legacy = await _prefs.get(
          scope: ReaderPreferencesDao.readerScope,
          ownerKey: path,
        );
        if (legacy != null) {
          await _prefs.put(
            scope: ReaderPreferencesDao.readerScope,
            ownerKind: 'content',
            ownerKey: fingerprint,
            prefs: legacy,
          );
        }
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
        final fingerprint = await _contentFingerprint(path);
        if (fingerprint == null) {
          await _prefs.put(
            scope: ReaderPreferencesDao.readerScope,
            ownerKind: 'path',
            ownerKey: path,
            prefs: prefs,
          );
        } else {
          await _prefs.put(
            scope: ReaderPreferencesDao.readerScope,
            ownerKind: 'content',
            ownerKey: fingerprint,
            prefs: prefs,
          );
        }
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
        final fingerprint = await _contentFingerprint(path);
        if (fingerprint != null) {
          await _prefs.remove(
            scope: ReaderPreferencesDao.readerScope,
            ownerKey: fingerprint,
          );
        }
        await _prefs.remove(
          scope: ReaderPreferencesDao.readerScope,
          ownerKey: path,
        );
      },
      onError: (error, stack) => StorageWriteFailure(
        _legacyDocKey(path),
        cause: error,
        stackTrace: stack,
      ),
    );
  }
}
