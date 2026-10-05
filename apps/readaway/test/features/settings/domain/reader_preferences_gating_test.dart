import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

void main() {
  group('ReaderPreferences.appliesTextAlignment', () {
    test('is true with layout overrides on and book alignment not kept', () {
      expect(const ReaderPreferences().appliesTextAlignment, isTrue);
    });

    test('is false when the book layout is respected', () {
      expect(
        const ReaderPreferences(overrideLayout: false).appliesTextAlignment,
        isFalse,
      );
    });

    test('is false when the book alignment is kept', () {
      expect(
        const ReaderPreferences(keepTextAlignment: true).appliesTextAlignment,
        isFalse,
      );
    });

    test('is false when both overrides are off', () {
      expect(
        const ReaderPreferences(
          overrideLayout: false,
          keepTextAlignment: true,
        ).appliesTextAlignment,
        isFalse,
      );
    });
  });

  group('ReaderPreferences layout defaults', () {
    test('layout overrides are on by default', () {
      expect(const ReaderPreferences().overrideLayout, isTrue);
    });

    test('header and footer start visible', () {
      const prefs = ReaderPreferences();
      expect(prefs.showHeader, isTrue);
      expect(prefs.showFooter, isTrue);
    });
  });
}
