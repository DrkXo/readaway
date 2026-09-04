part of '../../services.dart';

@injectable
class HiveConfigService {
  final AppPathService _pathService;

  HiveConfigService(this._pathService);

  static const String boxName = 'reader_prefs';
  static const String boxExtension = '.hive';
  static const String lockExtension = '.lock';

  String get boxFileName => '$boxName$boxExtension';
  String get lockFileName => '$boxName$lockExtension';

  Future<String> getHiveDirectory() async {
    final dir = await _pathService.getHiveDirectory();
    return dir.path;
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
