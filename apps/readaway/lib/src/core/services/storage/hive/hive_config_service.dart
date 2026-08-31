part of '../../services.dart';

@injectable
class HiveConfigService {
  static const String boxName = 'reader_prefs';
  static const String boxExtension = '.hive';
  static const String lockExtension = '.lock';

  String get boxFileName => '$boxName$boxExtension';
  String get lockFileName => '$boxName$lockExtension';

  Future<String> getHiveDirectory() async {
    // final dir = await getApplicationDocumentsDirectory();
    final dir = await getApplicationSupportDirectory();

    return p.join(dir.path, 'config');
  }

  Future<String> getBoxPath() async {
    final dir = await getHiveDirectory();
    return p.join(dir, boxFileName);
  }

  Future<File> getBoxFile() async {
    final path = await getBoxPath();
    return File(path);
  }

  Future<List<File>> getAllBoxFiles() async {
    final boxFile = await getBoxFile();
    return [
      boxFile,
      File(p.join(p.dirname(boxFile.path), lockFileName)),
    ];
  }
}
