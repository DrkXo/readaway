part of '../../services.dart';

AppStorageService get appStorageService => GetIt.I.get<AppStorageService>();

@Singleton()
class AppStorageService {
  final HiveConfigService _config;

  late final Box<String> _box;

  Box<String> get box => _box;

  static const String _schemaVersionKey = 'schema_version';
  static const int _schemaVersion = 1;

  AppStorageService({
    required this._config,
  });

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final hiveDir = await _config.getHiveDirectory();
    Hive.init(hiveDir);

    _box = await Hive.openBox<String>(HiveConfigService.boxName);

    await _handleStaleData();
  }

  Future<void> _handleStaleData() async {
    try {
      final storedVersion = readAsInt(_schemaVersionKey);

      if (storedVersion != _schemaVersion) {
        logger.d(
          'Detected schema update or fresh install, clearing stale Hive data',
        );
        await deleteAll();
        await writeAsInt(_schemaVersionKey, _schemaVersion);
      }
    } catch (e) {
      logger.e('Error handling stale data: $e');
      try {
        await deleteAll();
      } catch (clearError) {
        logger.e('Error clearing Hive storage: $clearError');
      }
    }
  }

  Future<void> resetStorage() async {
    try {
      await _box.close();

      final files = await _config.getAllBoxFiles();
      for (final file in files) {
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      throw AppStorageException('Failed to reset Hive storage: $e');
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    await _box.close();
  }

  Future<void> writeAsString(String key, String value) async {
    try {
      await _box.put(key, value);
    } catch (e) {
      logger.e('Failed to write string for key $key: $e');
      rethrow;
    }
  }

  Future<void> writeAsInt(String key, int value) async {
    try {
      await _box.put(key, value.toString());
    } catch (e) {
      logger.e('Failed to write int for key $key: $e');
      rethrow;
    }
  }

  String? readAsString(String key) {
    try {
      return _box.get(key);
    } catch (e) {
      logger.e('Failed to read string for key $key: $e');
      return null;
    }
  }

  int? readAsInt(String key) {
    final value = readAsString(key);
    if (value == null || value.isEmpty) return null;
    try {
      return int.parse(value);
    } catch (e) {
      logger.e('Failed to parse int for key $key: $e');
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _box.delete(key);
    } catch (e) {
      logger.e('Failed to delete key $key: $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      await _box.clear();
    } catch (e) {
      logger.e('Failed to delete all keys: $e');
    }
  }

  ReaderPreferences? readReaderGlobalPrefs() {
    final value = readAsString('reader_global');
    if (value == null) return null;
    try {
      return ReaderPreferences.fromJson(jsonDecode(value));
    } catch (e) {
      logger.e('Failed to parse reader global prefs: $e');
      return null;
    }
  }

  Future<void> writeReaderGlobalPrefs(ReaderPreferences prefs) async {
    await writeAsString('reader_global', jsonEncode(prefs.toJson()));
  }

  ReaderPreferences? readReaderDocumentPrefs(String path) {
    final value = readAsString('reader_doc_$path');
    if (value == null) return null;
    try {
      return ReaderPreferences.fromJson(jsonDecode(value));
    } catch (e) {
      logger.e('Failed to parse reader doc prefs for $path: $e');
      return null;
    }
  }

  Future<void> writeReaderDocumentPrefs(
    String path,
    ReaderPreferences prefs,
  ) async {
    await writeAsString('reader_doc_$path', jsonEncode(prefs.toJson()));
  }

  Future<void> deleteReaderDocumentPrefs(String path) async {
    await delete('reader_doc_$path');
  }

  Future<Map<String, ReaderPreferences>> readAllReaderDocumentPrefs() async {
    final result = <String, ReaderPreferences>{};
    for (final key in _box.keys.cast<String>()) {
      if (key.startsWith('reader_doc_')) {
        final path = key.substring('reader_doc_'.length);
        final prefs = readReaderDocumentPrefs(path);
        if (prefs != null) {
          result[path] = prefs;
        }
      }
    }
    return result;
  }

  Future<String> exportAll() async {
    final global = readReaderGlobalPrefs();
    final docs = await readAllReaderDocumentPrefs();

    final map = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'global': global?.toJson(),
      for (final entry in docs.entries) entry.key: entry.value.toJson(),
    };

    return jsonEncode(map);
  }
}

class AppStorageException implements Exception {
  final String message;
  const AppStorageException(this.message);

  @override
  String toString() => 'AppStorageException: $message';
}
