import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../models/models.dart';
import 'logging_service.dart';
import 'path_service.dart';
import 'settings_service.dart';

/// Loads and registers user-added font files so Flutter can render them.
@Singleton()
class FontService {
  final SettingsService _settings;
  final AppPathService _pathService;

  final Set<String> _registered = <String>{};
  Directory? _fontsDir;

  FontService({
    required this._settings,
    required this._pathService,
  });

  List<String> get customFontFamilyNames =>
      _settings.settings.customFonts.map((f) => f.name).toList();

  bool isRegistered(String familyName) => _registered.contains(familyName);

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    _fontsDir = await _pathService.getFontsDirectory();
    await _loadRegisteredFonts();
  }

  Future<void> _loadRegisteredFonts() async {
    for (final font in _settings.settings.customFonts) {
      try {
        await _registerFont(font.name, font.path);
      } catch (e) {
        logger.e('Failed to load custom font ${font.name}: $e');
      }
    }
  }

  Future<CustomFont> addFont(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Font file not found', sourcePath);
    }

    final fileName = p.basename(sourcePath);
    final destPath = p.join(_fontsDir!.path, fileName);
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(destPath);

    final familyName = p.basenameWithoutExtension(fileName);

    await _registerFont(familyName, destPath);

    return CustomFont(
      id: _newId(),
      name: familyName,
      path: destPath,
    );
  }

  Future<void> removeFont(CustomFont font) async {
    _registered.remove(font.name);
    try {
      final file = File(font.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      logger.e('Failed to delete font file ${font.path}: $e');
    }
  }

  Future<void> _registerFont(String familyName, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('Font file not found', path);
    }
    final bytes = await file.readAsBytes();
    final loader = FontLoader(familyName)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
    _registered.add(familyName);
    logger.d('Registered custom font: $familyName');
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
