import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../features/settings/domain/entity/settings.dart';
import 'storage/drift/daos/settings_dao.dart';

SettingsService get settingsService => GetIt.I.get<SettingsService>();

@Singleton()
class SettingsService {
  final _log = AppLogger.instance.scope('SettingsService');

  static const Duration _flushDelay = Duration(milliseconds: 500);

  final SettingsDao _dao;

  Settings _settings = const Settings();
  Timer? _flushTimer;
  final _changesController = StreamController<Settings>.broadcast();

  Settings get settings => _settings;
  Stream<Settings> get changes => _changesController.stream;

  SettingsService(this._dao);

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final stored = await _dao.get();

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
      await _dao.put(settings);
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
