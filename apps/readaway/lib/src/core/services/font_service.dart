part of 'services.dart';

/// Loads and registers user-added font files so Flutter can render them.
///
/// Custom fonts are picked from disk, copied into the app documents
/// directory, and registered at runtime via [FontLoader]. The registered
/// family names are then available to the reader's font pickers and to
/// [TextStyle.fontFamily] resolution.
@Singleton()
class FontService {
  static const String _fontsDirName = 'custom_fonts';

  final SettingsService _settings;

  /// Family names currently registered with the engine.
  final Set<String> _registered = <String>{};

  /// Directory where copied font files live.
  Directory? _fontsDir;

  FontService({required this._settings});

  /// Family names of all custom fonts (registered or pending registration).
  List<String> get customFontFamilyNames =>
      _settings.settings.customFonts.map((f) => f.name).toList();

  /// Whether [familyName] is a registered custom font.
  bool isRegistered(String familyName) => _registered.contains(familyName);

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    final docs = await getApplicationSupportDirectory();
    _fontsDir = Directory(p.join(docs.path, F.name, _fontsDirName));
    if (!await _fontsDir!.exists()) {
      await _fontsDir!.create(recursive: true);
    }
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

  /// Copies [sourcePath] into app storage and registers it, returning the
  /// persisted [CustomFont]. The caller is responsible for persisting the
  /// returned entry into `Settings.customFonts`.
  Future<CustomFont> addFont(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FilePickerException('Font file not found: $sourcePath');
    }

    final fileName = p.basename(sourcePath);
    final destPath = p.join(_fontsDir!.path, fileName);
    final dest = File(destPath);
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(destPath);

    // Derive a stable family name from the file name (strip extension).
    final familyName = p.basenameWithoutExtension(fileName);

    await _registerFont(familyName, destPath);

    return CustomFont(
      id: _newId(),
      name: familyName,
      path: destPath,
    );
  }

  /// Removes a custom font: unregisters it and deletes its file.
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
      throw FilePickerException('Font file not found: $path');
    }
    final bytes = await file.readAsBytes();
    final loader = FontLoader(familyName)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
    _registered.add(familyName);
    logger.d('Registered custom font: $familyName');
  }

  String _newId() {
    // Simple unique id; collisions are unlikely for a handful of fonts.
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
