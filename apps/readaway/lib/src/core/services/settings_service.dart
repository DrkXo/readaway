import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../models/models.dart';
import 'logging_service.dart';
import 'storage/hive/app_storage_service.dart';

SettingsService get settingsService => GetIt.I.get<SettingsService>();

@Singleton()
class SettingsService {
  static const String _key = 'app_settings';
  static const Duration _flushDelay = Duration(milliseconds: 500);

  final AppStorageService _storage;

  Settings _settings = const Settings();
  Timer? _flushTimer;
  final _changesController = StreamController<Settings>.broadcast();

  Settings get settings => _settings;
  Stream<Settings> get changes => _changesController.stream;

  SettingsService({required this._storage});

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final raw = _storage.readAsString(_key);

    if (raw == null) {
      logger.d('No stored settings found, creating defaults');
      await save(const Settings());
      return;
    }

    try {
      _settings = Settings.fromJson(jsonDecode(raw));
      logger.d('Settings loaded');
    } catch (e) {
      logger.e('Failed to parse stored settings, resetting to defaults: $e');
      await save(const Settings());
    }
  }

  Future<void> save(Settings settings) async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _settings = settings;
    try {
      await _storage.writeAsString(_key, jsonEncode(settings.toJson()));
      _changesController.add(settings);
    } catch (e) {
      logger.e('Failed to persist settings: $e');
      rethrow;
    }
  }

  void scheduleSave(Settings settings) {
    _settings = settings;
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushDelay, () => save(settings));
    _changesController.add(settings);
  }

  @disposeMethod
  void dispose() {
    _flushTimer?.cancel();
    _changesController.close();
  }
}
