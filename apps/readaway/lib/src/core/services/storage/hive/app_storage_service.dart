part of '../../services.dart';

AppStorageService get appStorageService => GetIt.I.get<AppStorageService>();

/// Standalone entry point function required by [Isolate.spawn].
/// Must be a top-level or static function.
void _appStorageIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is! Map) return;

    final id = message['id'];
    final action = message['action'] as String?;

    try {
      switch (action) {
        case 'decodeJson':
          final rawJson = message['rawJson'] as String;
          final decoded = jsonDecode(rawJson);
          mainSendPort.send({'id': id, 'result': decoded});
          break;

        case 'encodeJson':
          final data = message['data'];
          final encoded = jsonEncode(data);
          mainSendPort.send({'id': id, 'result': encoded});
          break;

        case 'encodeExport':
          final schemaVersion = message['schemaVersion'] as int;
          final global = message['global'] as Map<String, dynamic>?;
          final docs = message['docs'] as Map<String, dynamic>;

          final exportMap = <String, dynamic>{
            'schemaVersion': schemaVersion,
            'global': global,
            for (final entry in docs.entries) entry.key: entry.value,
          };

          final encoded = jsonEncode(exportMap);
          mainSendPort.send({'id': id, 'result': encoded});
          break;

        default:
          mainSendPort.send({'id': id, 'error': 'Unknown action: $action'});
      }
    } catch (e) {
      mainSendPort.send({'id': id, 'error': e.toString()});
    }
  });
}

@Singleton()
class AppStorageService {
  final HiveConfigService _config;
  final IsolateService _isolateService;

  late final Box<String> _box;

  Box<String> get box => _box;

  static const String _isolateName = 'app_storage_worker';
  static const String _schemaVersionKey = 'schema_version';
  static const int _schemaVersion = 1;

  AppStorageService({
    required this._config,
    required this._isolateService,
  });

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final hiveDir = await _config.getHiveDirectory();
    Hive.init(hiveDir);

    _box = await Hive.openBox<String>(HiveConfigService.boxName);

    // Spawn the worker isolate during initialization
    await _isolateService.spawn(
      name: _isolateName,
      entryPoint: _appStorageIsolateEntryPoint,
    );

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
    await _isolateService.disposeIsolate(_isolateName);
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

  Future<ReaderPreferences> readReaderGlobalPrefs() async {
    final value = readAsString('reader_global');
    if (value == null) return const ReaderPreferences();
    try {
      final decoded = await _isolateService.sendCommand<Map<String, dynamic>>(
        _isolateName,
        {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'action': 'decodeJson',
          'rawJson': value,
        },
      );
      return ReaderPreferences.fromJson(decoded);
    } catch (e) {
      logger.e('Failed to parse reader global prefs: $e');
      return const ReaderPreferences();
    }
  }

  Future<void> writeReaderGlobalPrefs(ReaderPreferences prefs) async {
    try {
      final jsonString = await _isolateService.sendCommand<String>(
        _isolateName,
        {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'action': 'encodeJson',
          'data': prefs.toJson(),
        },
      );
      await writeAsString('reader_global', jsonString);
    } catch (e) {
      logger.e('Failed to write reader global prefs: $e');
      rethrow;
    }
  }

  Future<ReaderPreferences?> readReaderDocumentPrefs(String path) async {
    final value = readAsString('reader_doc_$path');
    if (value == null) return null;
    try {
      final decoded = await _isolateService.sendCommand<Map<String, dynamic>>(
        _isolateName,
        {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'action': 'decodeJson',
          'rawJson': value,
        },
      );
      return ReaderPreferences.fromJson(decoded);
    } catch (e) {
      logger.e('Failed to parse reader doc prefs for $path: $e');
      return null;
    }
  }

  Future<void> writeReaderDocumentPrefs(
    String path,
    ReaderPreferences prefs,
  ) async {
    try {
      final jsonString = await _isolateService.sendCommand<String>(
        _isolateName,
        {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'action': 'encodeJson',
          'data': prefs.toJson(),
        },
      );
      await writeAsString('reader_doc_$path', jsonString);
    } catch (e) {
      logger.e('Failed to write reader document prefs for $path: $e');
      rethrow;
    }
  }

  Future<void> deleteReaderDocumentPrefs(String path) async {
    await delete('reader_doc_$path');
  }

  Future<Map<String, ReaderPreferences>> readAllReaderDocumentPrefs() async {
    final result = <String, ReaderPreferences>{};
    for (final key in _box.keys.cast<String>()) {
      if (key.startsWith('reader_doc_')) {
        final path = key.substring('reader_doc_'.length);
        final prefs = await readReaderDocumentPrefs(path);
        if (prefs != null) {
          result[path] = prefs;
        }
      }
    }
    return result;
  }

  Future<String> exportAll() async {
    final global = await readReaderGlobalPrefs();
    final docs = await readAllReaderDocumentPrefs();

    final docsJson = <String, dynamic>{
      for (final entry in docs.entries) entry.key: entry.value.toJson(),
    };

    return await _isolateService.sendCommand<String>(
      _isolateName,
      {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'action': 'encodeExport',
        'schemaVersion': _schemaVersion,
        'global': global.toJson(),
        'docs': docsJson,
      },
    );
  }
}

class AppStorageException implements Exception {
  final String message;
  const AppStorageException(this.message);

  @override
  String toString() => 'AppStorageException: $message';
}
