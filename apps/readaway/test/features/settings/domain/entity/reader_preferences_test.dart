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

  group('ReaderPreferences Non-Reflowable Preferences Tests', () {
    test('default non-reflowable preferences are initialized correctly', () {
      const prefs = ReaderPreferences();
      expect(prefs.scrollDirection, ReaderScrollDirection.horizontal);
      expect(prefs.nonReflowableScrollDirection, ReaderScrollDirection.vertical);
      expect(prefs.pageSnap, isTrue);
      expect(prefs.nonReflowablePageSnap, isTrue);
      expect(prefs.pageTransition, ReaderPageTransition.slide);
      expect(prefs.nonReflowablePageTransition, ReaderPageTransition.slide);
    });

    test('effective preference helpers resolve correctly based on reflowability', () {
      const prefs = ReaderPreferences(
        scrollDirection: ReaderScrollDirection.horizontal,
        nonReflowableScrollDirection: ReaderScrollDirection.vertical,
        pageSnap: true,
        nonReflowablePageSnap: false,
        pageTransition: ReaderPageTransition.sharedAxis,
        nonReflowablePageTransition: ReaderPageTransition.none,
      );

      // Reflowable (EPUB, TXT, HTML)
      expect(prefs.effectiveScrollDirection(isReflowable: true), ReaderScrollDirection.horizontal);
      expect(prefs.effectivePageSnap(isReflowable: true), isTrue);
      expect(prefs.effectivePageTransition(isReflowable: true), ReaderPageTransition.sharedAxis);

      // Non-Reflowable (PDF, CBZ, CBR)
      expect(prefs.effectiveScrollDirection(isReflowable: false), ReaderScrollDirection.vertical);
      expect(prefs.effectivePageSnap(isReflowable: false), isFalse);
      expect(prefs.effectivePageTransition(isReflowable: false), ReaderPageTransition.none);
    });

    test('serializes and deserializes non-reflowable options correctly', () {
      const prefs = ReaderPreferences(
        scrollDirection: ReaderScrollDirection.vertical,
        nonReflowableScrollDirection: ReaderScrollDirection.horizontal,
        nonReflowablePageSnap: false,
        nonReflowablePageTransition: ReaderPageTransition.fade,
      );

      final json = prefs.toJson();
      expect(json['scrollDirection'], 'vertical');
      expect(json['nonReflowableScrollDirection'], 'horizontal');
      expect(json['nonReflowablePageSnap'], isFalse);
      expect(json['nonReflowablePageTransition'], 'fade');

      final fromJson = ReaderPreferences.fromJson(json);
      expect(fromJson.scrollDirection, ReaderScrollDirection.vertical);
      expect(fromJson.nonReflowableScrollDirection, ReaderScrollDirection.horizontal);
      expect(fromJson.nonReflowablePageSnap, isFalse);
      expect(fromJson.nonReflowablePageTransition, ReaderPageTransition.fade);
    });
  });
}
