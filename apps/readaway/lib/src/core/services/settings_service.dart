import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../features/settings/domain/entity/settings.dart';
import 'storage/hive/app_storage_service.dart';

SettingsService get settingsService => GetIt.I.get<SettingsService>();

@Singleton()
class SettingsService {
  final _log = AppLogger.instance.scope('SettingsService');

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
    final stored = _storage.settingsBox.get(_key);

    if (stored == null) {
      _log.d('No stored settings found, creating defaults');
      await save(const Settings());
      return;
    }

    _settings = stored;
    _log.d('Settings loaded');
  }

  Future<void> save(Settings settings) async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _settings = settings;
    try {
      await _storage.settingsBox.put(_key, settings);
      _changesController.add(settings);
    } catch (e, st) {
      _log.e('Failed to persist settings', error: e, stackTrace: st);
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
