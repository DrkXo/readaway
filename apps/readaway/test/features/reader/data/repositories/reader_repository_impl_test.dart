import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:readaway/src/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/reader_style_resolver.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

import '../../../../helpers/test_mocks.dart';

String? _resolveTestDocPath(String primaryKey, [String? fallbackKey]) {
  final envVal =
      Platform.environment[primaryKey] ??
      (fallbackKey != null ? Platform.environment[fallbackKey] : null);
  if (envVal != null && envVal.isNotEmpty) return envVal;

  final defineVal = String.fromEnvironment(primaryKey);
  if (defineVal.isNotEmpty) return defineVal;

  if (fallbackKey != null) {
    final fallbackDefine = String.fromEnvironment(fallbackKey);
    if (fallbackDefine.isNotEmpty) return fallbackDefine;
  }

  return null;
}

void main() {
  setUpAll(registerMockitoDummies);
  final epubPath = _resolveTestDocPath('TEST_EPUB_PATH', 'EPUB_PATH');
  final hasEpub = epubPath != null && File(epubPath).existsSync();

  group('ReaderStyleResolver Tests', () {
    const resolver = ReaderStyleResolver();

    test('compiles custom font and layout overrides correctly', () {
      const prefs = ReaderPreferences(
        fontFamily: 'Literata',
        overrideFont: true,
        fontSize: 18.0,
        lineHeight: 1.8,
        letterSpacing: 0.5,
        wordSpacing: 1.0,
        textIndent: 2.0,
        paragraphMargin: 1.0,
        textAlign: ReaderTextAlign.justify,
        overrideLayout: true,
        overrideColor: true,
      );

      final css = resolver.buildCustomCss(
        prefs: prefs,
        textColor: Colors.white,
        backgroundColor: Colors.black,
        linkColor: Colors.blue,
        isDarkMode: true,
      );

      expect(css, contains('font-family: "Literata"'));
      expect(css, contains('font-size: 18.0px !important'));
      expect(css, contains('line-height: 1.8 !important'));
      expect(css, contains('word-spacing: 1.0px !important'));
      expect(css, contains('letter-spacing: 0.5px !important'));
      expect(css, contains('text-indent: 2.0em !important'));
      // text-align is intentionally NOT emitted in CSS — it is applied on the
      // AST in applyReaderPreferences so authored alignment can be preserved.
      expect(css, isNot(contains('text-align:')));
      expect(css, contains('margin-top: 1.0em !important'));
      expect(css, contains('margin-bottom: 1.0em !important'));
    });

    test('respects publisher styling when overrideFont is false', () {
      const prefs = ReaderPreferences(
        overrideFont: false,
        fontSize: 16.0,
      );

      final css = resolver.buildCustomCss(
        prefs: prefs,
        textColor: Colors.black,
        backgroundColor: Colors.white,
        linkColor: Colors.blue,
      );

      expect(css, isNot(contains('font-size: 16.0px !important')));
    });

    test('builds base TextStyle matching preferences', () {
      const prefs = ReaderPreferences(
        fontFamily: 'Bookerly',
        overrideFont: true,
        fontSize: 20.0,
        lineHeight: 1.6,
        fontWeight: 'bold',
      );

      final style = resolver.buildBaseTextStyle(
        prefs: prefs,
        textColor: Colors.black,
      );

      expect(style.fontFamily, equals('Bookerly'));
      expect(style.fontSize, equals(20.0));
      expect(style.height, equals(1.6));
      expect(style.fontWeight, equals(FontWeight.bold));
    });
  });

  group(
    'Reflowable Document Reader Repository Tests',
    () {
      late ReaderRepository repository;

      setUpAll(() async {
        if (!hasEpub) return;

        final windowService = MockWindowService();
        when(windowService.setTitle(any)).thenAnswer((_) async {});
        when(windowService.setDefaultTitle()).thenAnswer((_) async {});

        final notifService = MockNotificationService();
        final pathService = MockAppPathService();
        final libRepo = MockLibraryRepository();

        repository = ReaderRepositoryImpl(
          windowService,
          notifService,
          pathService,
          libRepo,
        );
      });

      tearDownAll(() async {
        if (hasEpub) {
          await repository.closeDocument();
        }
      });

      test('opens EPUB with readaway_core', () async {
        final openResult = await repository.openDocument(epubPath!);

        expect(openResult.isSuccess, isTrue);
        final info = openResult.dataOrNull!;
        expect(info.pageCount, greaterThan(0));
        expect(info.title, isNotEmpty);
        expect(info.outline.length, greaterThanOrEqualTo(0));
        if (info.outline.isNotEmpty) {
          expect(info.outline.first.title, isNotEmpty);
        }
      });

      test('loads chapter HTML directly from readaway_core', () async {
        final pageDataResult = await repository.loadPage(0);

        expect(pageDataResult.isSuccess, isTrue);
        final pageData = pageDataResult.dataOrNull!;
        expect(pageData.html, isNotNull);
        expect(pageData.html, isNotEmpty);
        expect(pageData.html!.contains('position: absolute'), isFalse);
      });

      test(
        'extracts text from section HTML directly from readaway_core',
        () async {
          final openResult = await repository.openDocument(epubPath!);
          final info = openResult.dataOrNull!;
          final targetSection = info.pageCount > 1 ? 1 : 0;

          final textResult = await repository.extractPageText(targetSection);
          expect(textResult.isSuccess, isTrue);
          final text = textResult.dataOrNull!;
          expect(text, isNotEmpty);
        },
      );

      test('resolves asset bytes from EPUB archive directly', () async {
        final bytesResult = await repository.loadAssetBytes('mimetype');
        expect(bytesResult.isSuccess, isTrue);
        final bytes = bytesResult.dataOrNull;
        expect(bytes, isNotNull);
        expect(String.fromCharCodes(bytes!), contains('application/epub+zip'));
      });
    },
    skip: !hasEpub
        ? 'EPUB file not provided or not found (set TEST_EPUB_PATH or EPUB_PATH)'
        : null,
  );
}
