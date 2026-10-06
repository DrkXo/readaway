import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/settings/domain/entity/settings.dart';
import 'package:readaway/src/features/settings/domain/entity/tts_lyric_style.dart';

void main() {
  group('TtsLyricStyle', () {
    test('defaults to what the lyric view already rendered', () {
      // Every reader is looking at centred sentences today, because that is
      // what `LyricStyles.default1` ships and nothing has ever overridden it.
      // A default that drifted from that would silently restyle the whole
      // installed base the first time the app updated.
      const style = TtsLyricStyle();

      expect(style.lineAlign, LyricLineAlign.center);
      expect(style.contentAlign, LyricContentAlign.center);
      expect(style.selectionAnchorAlign, LyricAnchorAlign.center);
      expect(style.activeAnchorAlign, LyricAnchorAlign.center);
    });

    test('serializes and deserializes each alignment', () {
      const style = TtsLyricStyle(
        lineAlign: LyricLineAlign.justify,
        contentAlign: LyricContentAlign.end,
        selectionAnchorAlign: LyricAnchorAlign.start,
        activeAnchorAlign: LyricAnchorAlign.end,
      );

      final json = style.toJson();
      expect(json['lineAlign'], 'justify');
      expect(json['contentAlign'], 'end');
      expect(json['selectionAnchorAlign'], 'start');
      expect(json['activeAnchorAlign'], 'end');

      expect(TtsLyricStyle.fromJson(json), style);
    });

    test('falls back to the default for an alignment it no longer knows', () {
      // Written settings outlive the versions that produced them: a build that
      // renames or drops one of these enums must not fail to read the whole
      // app's settings back, and must not silently pick something the reader
      // never chose.
      final style = TtsLyricStyle.fromJson({
        'lineAlign': 'diagonal',
        'selectionAnchorAlign': 'bottom',
      });

      expect(style.lineAlign, LyricLineAlign.center);
      expect(style.selectionAnchorAlign, LyricAnchorAlign.center);
      expect(style.contentAlign, LyricContentAlign.center);
      expect(style.activeAnchorAlign, LyricAnchorAlign.center);
    });

    test('reads settings written before these options existed', () {
      final style = TtsLyricStyle.fromJson(const <String, dynamic>{});

      expect(style, const TtsLyricStyle());
    });

    test('compares by value so an unchanged preference is not a change', () {
      // The view keys the package's layout on this object, so a rebuilt
      // Settings carrying equal values must not be mistaken for an edit.
      expect(
        const TtsLyricStyle().copyWith(contentAlign: LyricContentAlign.end),
        const TtsLyricStyle(contentAlign: LyricContentAlign.end),
      );
      expect(
        const TtsLyricStyle(),
        isNot(const TtsLyricStyle(contentAlign: LyricContentAlign.end)),
      );
    });
  });

  group('GlobalViewSettings.ttsLyricStyle', () {
    test('is centred until a reader changes it', () {
      const settings = GlobalViewSettings();

      expect(settings.ttsLyricStyle, const TtsLyricStyle());
    });

    test('survives a round trip through stored settings', () {
      const lyric = TtsLyricStyle(
        lineAlign: LyricLineAlign.left,
        contentAlign: LyricContentAlign.start,
        selectionAnchorAlign: LyricAnchorAlign.start,
        activeAnchorAlign: LyricAnchorAlign.end,
      );

      final stored = settingsToJson(
        const Settings(
          globalViewSettings: GlobalViewSettings(ttsLyricStyle: lyric),
        ),
      );

      expect(settingsFromJson(stored).globalViewSettings.ttsLyricStyle, lyric);
    });

    test('reads settings stored before the option existed', () {
      // The whole settings blob predates this key. Reading it back must land on
      // the same centred defaults the reader was already seeing, not on a
      // partially-populated style that would restyle the lyric view on upgrade.
      const stored =
          '{"schemaVersion":1,"version":1,"migrationVersion":1,'
          '"screenWakeLock":false,"customFonts":[],'
          '"globalViewSettings":{"theme":"system"}}';

      expect(
        settingsFromJson(stored).globalViewSettings.ttsLyricStyle,
        const TtsLyricStyle(),
      );
    });
  });

  group('GlobalViewSettings.uiFont', () {
    test('defaults to Madimi One for the app chrome', () {
      const settings = GlobalViewSettings();

      expect(settings.uiFont, 'Madimi One');
    });

    test('survives a round trip through stored settings', () {
      final stored = settingsToJson(
        const Settings(
          globalViewSettings: GlobalViewSettings(uiFont: 'system'),
        ),
      );

      expect(settingsFromJson(stored).globalViewSettings.uiFont, 'system');
    });

    test('reads settings stored before the option existed', () {
      // Older blobs lack the key entirely; reading them back must resolve to
      // the brand-new default, not a null that would silently blank the theme.
      const stored =
          '{"schemaVersion":1,"version":1,"migrationVersion":1,'
          '"screenWakeLock":false,"customFonts":[],'
          '"globalViewSettings":{"theme":"system"}}';

      expect(settingsFromJson(stored).globalViewSettings.uiFont, 'Madimi One');
    });
  });
}
