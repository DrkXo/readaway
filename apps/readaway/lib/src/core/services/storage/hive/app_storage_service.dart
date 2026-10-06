import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../features/annotations/domain/entity/document_notes.dart';
import '../../../../features/library/domain/entity/recent_document.dart';
import '../../../../features/settings/domain/entity/reader_preferences.dart';
import '../../../../features/settings/domain/entity/settings.dart';
import 'hive_boxes.dart';
import 'hive_config_service.dart';
import 'hive_registrar.g.dart';

@Singleton()
class AppStorageService {
  final HiveConfigService _config;
  final HiveBoxes _boxes;

  late final Box<Settings> _settingsBox;
  late final Box<RecentDocument> _libraryBox;
  late final Box<ReaderPreferences> _readerBox;
  late final Box<dynamic> _ttsBox;
  late final Box<DocumentNotes> _annotationsBox;

  Box<Settings> get settingsBox => _settingsBox;
  Box<RecentDocument> get libraryBox => _libraryBox;
  Box<ReaderPreferences> get readerBox => _readerBox;
  Box<dynamic> get ttsBox => _ttsBox;
  Box<DocumentNotes> get annotationsBox => _annotationsBox;

  static bool _adaptersRegistered = false;

  AppStorageService({
    required this._config,
    required this._boxes,
  });

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final hiveDir = await _config.getHiveDirectory();
    Hive.init(hiveDir);
    if (!_adaptersRegistered) {
      Hive.registerAdapters();
      _adaptersRegistered = true;
    }

    _settingsBox = await Hive.openBox<Settings>(_boxes.settings);
    _libraryBox = await Hive.openBox<RecentDocument>(_boxes.library);
    _readerBox = await Hive.openBox<ReaderPreferences>(_boxes.reader);
    _ttsBox = await Hive.openBox<dynamic>(_boxes.tts);
    _annotationsBox = await Hive.openBox<DocumentNotes>(_boxes.annotations);
  }

  Future<void> resetStorage({bool reopen = false}) async {
    try {
      await Future.wait([
        _settingsBox.close(),
        _libraryBox.close(),
        _readerBox.close(),
        _ttsBox.close(),
        _annotationsBox.close(),
      ]);
      final files = await _config.getAllBoxFiles();
      for (final file in files) {
        if (await file.exists()) await file.delete();
      }
      if (reopen) {
        _settingsBox = await Hive.openBox<Settings>(_boxes.settings);
        _libraryBox = await Hive.openBox<RecentDocument>(_boxes.library);
        _readerBox = await Hive.openBox<ReaderPreferences>(_boxes.reader);
        _ttsBox = await Hive.openBox<dynamic>(_boxes.tts);
        _annotationsBox = await Hive.openBox<DocumentNotes>(
          _boxes.annotations,
        );
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
      _annotationsBox.close(),
    ]);
  }
}

class AppStorageException implements Exception {
  final String message;
  const AppStorageException(this.message);

  @override
  String toString() => 'AppStorageException: $message';
}
