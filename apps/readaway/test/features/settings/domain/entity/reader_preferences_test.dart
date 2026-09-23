import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

void main() {
  group('ReaderPreferences Header & Footer Tests', () {
    test('default header and footer preferences are initialized correctly', () {
      const prefs = ReaderPreferences();
      expect(prefs.showHeader, isTrue);
      expect(prefs.headerAlignment, ReaderHeaderAlignment.left);
      expect(prefs.headerFontSize, 11.0);
      expect(prefs.showFooter, isTrue);
      expect(prefs.footerProgressStyle, ReaderProgressStyle.pageNumber);
      expect(prefs.showRemainingPages, isTrue);
      expect(prefs.showCurrentTime, isFalse);
      expect(prefs.showBatteryStatus, isFalse);
      expect(prefs.showFooterProgressBar, isFalse);
      expect(prefs.footerFontSize, 11.0);
    });

    test('serializes and deserializes header and footer fields correctly', () {
      const prefs = ReaderPreferences(
        showHeader: false,
        headerAlignment: ReaderHeaderAlignment.left,
        headerFontSize: 13.5,
        showFooter: true,
        footerProgressStyle: ReaderProgressStyle.percentage,
        showRemainingPages: false,
        showCurrentTime: true,
        showBatteryStatus: true,
        showFooterProgressBar: true,
        footerFontSize: 12.0,
      );

      final json = prefs.toJson();
      expect(json['showHeader'], isFalse);
      expect(json['headerAlignment'], 'left');
      expect(json['headerFontSize'], 13.5);
      expect(json['showFooter'], isTrue);
      expect(json['footerProgressStyle'], 'percentage');
      expect(json['showRemainingPages'], isFalse);
      expect(json['showCurrentTime'], isTrue);
      expect(json['showBatteryStatus'], isTrue);
      expect(json['showFooterProgressBar'], isTrue);
      expect(json['footerFontSize'], 12.0);

      final fromJson = ReaderPreferences.fromJson(json);
      expect(fromJson.showHeader, isFalse);
      expect(fromJson.headerAlignment, ReaderHeaderAlignment.left);
      expect(fromJson.headerFontSize, 13.5);
      expect(fromJson.showFooter, isTrue);
      expect(fromJson.footerProgressStyle, ReaderProgressStyle.percentage);
      expect(fromJson.showRemainingPages, isFalse);
      expect(fromJson.showCurrentTime, isTrue);
      expect(fromJson.showBatteryStatus, isTrue);
      expect(fromJson.showFooterProgressBar, isTrue);
      expect(fromJson.footerFontSize, 12.0);
    });
  });
}
