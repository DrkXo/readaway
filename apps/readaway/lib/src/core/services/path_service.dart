part of 'services.dart';

@lazySingleton
class AppPathService {
  Directory? _supportDir;
  Directory? _tempDir;
  Directory? _documentsDir;

  /// Application support directory for persistent, non-user-facing files.
  Future<Directory> get supportDirectory async =>
      _supportDir ??= await getApplicationSupportDirectory();

  /// Temporary directory for short-lived scratch files and archives.
  Future<Directory> get tempDirectory async =>
      _tempDir ??= await getTemporaryDirectory();

  /// Documents directory for user-visible files.
  Future<Directory> get documentsDirectory async =>
      _documentsDir ??= await getApplicationDocumentsDirectory();

  /// Directory where Hive configuration and boxes live: `<support>/config`.
  Future<Directory> getHiveDirectory() async {
    final support = await supportDirectory;
    final dir = Directory(p.join(support.path, 'config'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where custom fonts live: `<support>/<flavor>/custom_fonts`.
  Future<Directory> getFontsDirectory() async {
    final support = await supportDirectory;
    final dir = Directory(p.join(support.path, F.name, 'custom_fonts'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where HTTP cache store lives: `<support>/dio_cache`.
  Future<Directory> getHttpCacheDirectory() async {
    final support = await supportDirectory;
    final dir = Directory(p.join(support.path, 'dio_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Directory where TTS models live: `<support>/tts_models`.
  Future<Directory> getTtsModelsDirectory() async {
    final support = await supportDirectory;
    final dir = Directory(p.join(support.path, 'tts_models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
