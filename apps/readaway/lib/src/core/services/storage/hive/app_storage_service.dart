import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../features/library/domain/entity/recent_document.dart';
import '../../../../features/settings/domain/entity/reader_preferences.dart';
import '../../../models/models.dart';
import 'hive_boxes.dart';
import 'hive_config_service.dart';
import 'hive_registrar.g.dart';

@Singleton()
class AppStorageService {
  final HiveConfigService _config;

  late final Box<Settings> _settingsBox;
  late final Box<RecentDocument> _libraryBox;
  late final Box<ReaderPreferences> _readerBox;
  late final Box<dynamic> _ttsBox;

  Box<Settings> get settingsBox => _settingsBox;
  Box<RecentDocument> get libraryBox => _libraryBox;
  Box<ReaderPreferences> get readerBox => _readerBox;
  Box<dynamic> get ttsBox => _ttsBox;

  static bool _adaptersRegistered = false;

  AppStorageService({
    required this._config,
  });

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final hiveDir = await _config.getHiveDirectory();
    Hive.init(hiveDir);
    if (!_adaptersRegistered) {
      Hive.registerAdapters();
      _adaptersRegistered = true;
    }

    _settingsBox = await Hive.openBox<Settings>(HiveBoxes.settings);
    _libraryBox = await Hive.openBox<RecentDocument>(HiveBoxes.library);
    _readerBox = await Hive.openBox<ReaderPreferences>(HiveBoxes.reader);
    _ttsBox = await Hive.openBox<dynamic>(HiveBoxes.tts);
  }

  Future<void> resetStorage({bool reopen = false}) async {
    try {
      await Future.wait([
        _settingsBox.close(),
        _libraryBox.close(),
        _readerBox.close(),
        _ttsBox.close(),
      ]);
      final files = await _config.getAllBoxFiles();
      for (final file in files) {
        if (await file.exists()) await file.delete();
      }
      if (reopen) {
        _settingsBox = await Hive.openBox<Settings>(HiveBoxes.settings);
        _libraryBox = await Hive.openBox<RecentDocument>(HiveBoxes.library);
        _readerBox = await Hive.openBox<ReaderPreferences>(HiveBoxes.reader);
        _ttsBox = await Hive.openBox<dynamic>(HiveBoxes.tts);
      }
    } catch (e) {
      throw AppStorageException('Failed to reset Hive storage: $e');
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    await Future.wait([
      _settingsBox.close(),
      _libraryBox.close(),
      _readerBox.close(),
      _ttsBox.close(),
    ]);
  }
}

class AppStorageException implements Exception {
  final String message;
  const AppStorageException(this.message);

  @override
  String toString() => 'AppStorageException: $message';
}
