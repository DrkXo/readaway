import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../flavors.dart';

@lazySingleton
class AppPathService {
  Directory? _appDir;
  Directory? _tempDir;
  Directory? _documentsDir;

  /// User documents directory (`getApplicationDocumentsDirectory`).
  Future<Directory> get documentsDirectory async =>
      _documentsDir ??= await getApplicationSupportDirectory();

  /// App-private root inside the documents directory: `<documents>/.readaway`.
  ///
  /// Using a dot-prefixed folder inside documents keeps app data portable and
  /// visible to the user while staying out of the way of their own files.
  Future<Directory> get appDirectory async {
    if (_appDir != null) return _appDir!;
    final docs = await documentsDirectory;
    final dir = Directory(p.join(docs.path, '.${F.name}'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _appDir = dir;
  }

  /// Temporary directory for short-lived scratch files and archives.
  Future<Directory> get tempDirectory async =>
      _tempDir ??= await getTemporaryDirectory();

  /// Directory where Hive configuration and boxes live: `<app>/config`.
  Future<Directory> getHiveDirectory() async {
    final app = await appDirectory;
    final dir = Directory(p.join(app.path, 'config'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where custom fonts live: `<app>/custom_fonts`.
  Future<Directory> getFontsDirectory() async {
    final app = await appDirectory;
    final dir = Directory(p.join(app.path, 'custom_fonts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where HTTP cache store lives: `<app>/dio_cache`.
  Future<Directory> getHttpCacheDirectory() async {
    final app = await appDirectory;
    final dir = Directory(p.join(app.path, 'dio_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where TTS models live: `<app>/tts_models`.
  Future<Directory> getTtsModelsDirectory() async {
    final app = await appDirectory;
    final dir = Directory(p.join(app.path, 'tts_models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where temporary TTS synthesized audio chunks live: `<temp>/tts_cache`.
  Future<Directory> getTtsAudioCacheDirectory() async {
    final temp = await tempDirectory;
    final dir = Directory(p.join(temp.path, 'tts_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where cached document covers live: `<app>/covers`.
  Future<Directory> getCoversDirectory() async {
    final app = await appDirectory;
    final dir = Directory(p.join(app.path, 'covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
