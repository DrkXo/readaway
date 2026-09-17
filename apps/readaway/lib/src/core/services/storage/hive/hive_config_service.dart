import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../path_service.dart';
import 'hive_boxes.dart';

@injectable
class HiveConfigService {
  final AppPathService _pathService;

  HiveConfigService(this._pathService);

  static const String boxExtension = '.hive';
  static const String lockExtension = '.lock';

  Future<String> getHiveDirectory() async {
    final dir = await _pathService.getHiveDirectory();
    return dir.path;
  }

  Future<List<File>> getAllBoxFiles() async {
    final hiveDir = await getHiveDirectory();
    final files = <File>[];

    for (final name in HiveBoxes.all) {
      files.add(File(p.join(hiveDir, '$name$boxExtension')));
      files.add(File(p.join(hiveDir, '$name$lockExtension')));
    }

    return files;
  }
}
