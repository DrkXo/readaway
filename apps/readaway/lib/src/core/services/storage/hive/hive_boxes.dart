import 'package:injectable/injectable.dart';

/// Constants for all feature-scoped Hive boxes in the application.

@lazySingleton
final class HiveBoxes {
  /// Box for general app settings (theme, window, appearance).
  final String settings = 'settings_box';

  /// Box for user library records and document history.
  final String library = 'library_box';

  /// Box for global and per-book reader style preferences.
  final String reader = 'reader_box';

  /// Box for offline TTS model catalog, download indexes, and checksums.
  final String tts = 'tts_box';

  /// List of all active feature boxes.
  List<String> get all => [
    settings,
    library,
    reader,
    tts,
  ];
}
