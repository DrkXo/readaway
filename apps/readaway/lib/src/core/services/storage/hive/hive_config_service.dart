import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../path_service.dart';
import 'hive_boxes.dart';

@lazySingleton
class HiveConfigService {
  final AppPathService _pathService;
  final HiveBoxes _boxes;

  HiveConfigService(this._pathService, this._boxes);

  static const String boxExtension = '.hive';
  static const String lockExtension = '.lock';

  Future<String> getHiveDirectory() async {
    final dir = await _pathService.getHiveDirectory();
    return dir.path;
  }

  Future<List<File>> getAllBoxFiles() async {
    final hiveDir = await getHiveDirectory();
    final files = <File>[];

    for (final name in _boxes.all) {
      files.add(File(p.join(hiveDir, '$name$boxExtension')));
      files.add(File(p.join(hiveDir, '$name$lockExtension')));
    }

    return files;
  }
}
