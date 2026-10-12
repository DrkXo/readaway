import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';

/// Schema regression guard for the tracked Hive adapter ledger.
///
/// `hive_adapters.g.yaml` is committed and `hive_ce_generator` reuses each
/// field's index **by name** from the previous yaml. Removing a field leaves
/// an index gap but must never renumber surviving fields, or stored data would
/// be read with the wrong values. These tests lock the key indices and prove
/// that JSON payloads written by older app versions (which can still contain
/// the removed keys) load cleanly with constructor defaults.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('legacy Settings payloads', () {
    test('reads legacy JSON with removed keys and applies defaults', () {
      final parsed = Settings.fromJson(const {
        'schemaVersion': 3,
        'version': 2,
        'migrationVersion': 1,
        'screenWakeLock': true,
        'librarySortBy': 'title',
        'globalViewSettings': {
          'theme': 'dark',
          'selectedScheme': 'token',
          'uiFont': 'Madimi One',
          'highlightOpacity': 0.9,
          'pageTurnStyle': 'curl',
          'ttsRate': 1.25,
          'ttsMaxCacheSizeMb': 500,
          'ttsPrecacheNextChapter': false,
        },
      });

      // Surviving fields keep their stored values.
      expect(parsed.screenWakeLock, isTrue);
      expect(parsed.librarySortBy, 'title');
      expect(parsed.globalViewSettings.theme, 'dark');
      expect(parsed.globalViewSettings.ttsRate, 1.25);

      // Keys that are removed today are ignored, and surviving fields the old
      // payload does not set fall back to their constructor defaults.
      expect(parsed.globalViewSettings.ttsHighlightStyle, 'highlight');
    });

    test('toJson no longer emits removed keys', () {
      const settings = Settings(screenWakeLock: true);
      final json = settings.toJson();
      expect(json.containsKey('schemaVersion'), isFalse);
      expect(json.containsKey('highlightOpacity'), isFalse);
      expect(json.containsKey('pageTurnStyle'), isFalse);
      expect(json.containsKey('ttsPrecacheNextChapter'), isFalse);

      final gvs = json['globalViewSettings'] as Map<String, dynamic>;
      expect(gvs.containsKey('highlightOpacity'), isFalse);
      expect(gvs.containsKey('pageTurnStyle'), isFalse);
      expect(gvs.containsKey('ttsPrecacheNextChapter'), isFalse);
    });
  });

  group('legacy ReaderPreferences payloads', () {
    test('reads legacy JSON with removed keys and applies defaults', () {
      final parsed = ReaderPreferences.fromJson(const {
        'overrideColor': true,
        'showStatusBar': false,
        'fontSize': 24.0,
        'showHeader': false,
        'headerFontSize': 13.0,
      });

      expect(parsed.fontSize, 24.0);
      expect(parsed.showHeader, isFalse);
      expect(parsed.headerFontSize, 13.0);
      // Removed fields fall back to defaults.
      expect(parsed.overrideLayout, isTrue);
    });

    test('toJson no longer emits removed keys', () {
      const prefs = ReaderPreferences(fontSize: 24.0);
      final json = prefs.toJson();
      expect(json.containsKey('overrideColor'), isFalse);
      expect(json.containsKey('showStatusBar'), isFalse);
    });
  });

  group('hive_adapters.g.yaml index ledger', () {
    test('surviving field indices are pinned', () {
      final yaml = File(
        'lib/src/core/services/storage/hive/hive_adapters.g.yaml',
      ).readAsStringSync();

      // ReaderPreferences: removed overrideColor (was 10) and showStatusBar
      // (was 31) must not renumber surviving fields.
      expect(_indexOf(yaml, 'ReaderPreferences', 'fontSize'), 11);
      expect(_indexOf(yaml, 'ReaderPreferences', 'showHeader'), 32);

      // Settings: removed schemaVersion/version/migrationVersion (0-2) must
      // not renumber surviving fields.
      expect(_indexOf(yaml, 'Settings', 'screenWakeLock'), 13);
      expect(_indexOf(yaml, 'Settings', 'globalViewSettings'), 57);

      // GlobalViewSettings: removed highlightOpacity (was 36), pageTurnStyle
      // (was 71) and ttsPrecacheNextChapter (was 118) must not renumber the
      // TTS block.
      expect(_indexOf(yaml, 'GlobalViewSettings', 'ttsRate'), 80);
      expect(_indexOf(yaml, 'GlobalViewSettings', 'ttsVoice'), 84);
      expect(_indexOf(yaml, 'GlobalViewSettings', 'ttsLyricStyle'), 119);
    });
  });
}

/// Reads the `index: N` line for [field] inside the `[type]:` block from the
/// generated yaml ledger.
int _indexOf(String yaml, String type, String field) {
  final typeMatch = RegExp(
    '^  $type:\n'
    '(?:    typeId: \\d+\n)?'
    '    nextIndex: \\d+\n'
    '    fields:\n',
    multiLine: true,
  ).firstMatch(yaml);
  expect(
    typeMatch,
    isNotNull,
    reason: 'type $type must appear in the ledger',
  );
  final block = yaml.substring(
    typeMatch!.end,
    _nextTypeStart(yaml, typeMatch.end),
  );
  final fieldMatch = RegExp(
    '^      $field:\n        index: (\\d+)\n',
    multiLine: true,
  ).firstMatch(block);
  expect(
    fieldMatch,
    isNotNull,
    reason: 'field $field must be pinned in the ledger',
  );
  return int.parse(fieldMatch!.group(1)!);
}

int _nextTypeStart(String yaml, int from) {
  final next = RegExp(
    '^  [A-Z]',
    multiLine: true,
  ).firstMatch(yaml.substring(from));
  return next == null ? yaml.length : from + next.start;
}
