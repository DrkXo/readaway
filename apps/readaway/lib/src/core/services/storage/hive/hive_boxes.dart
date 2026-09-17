/// Constants for all feature-scoped Hive boxes in the application.
abstract final class HiveBoxes {
  /// Box for general app settings (theme, window, appearance).
  static const String settings = 'settings_box';

  /// Box for user library records and document history.
  static const String library = 'library_box';

  /// Box for global and per-book reader style preferences.
  static const String reader = 'reader_box';

  /// Box for offline TTS model catalog, download indexes, and checksums.
  static const String tts = 'tts_box';

  /// List of all active feature boxes.
  static const List<String> all = [
    settings,
    library,
    reader,
    tts,
  ];
}
