import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readaway/src/core/services/document_cover_service.dart';
import 'package:readaway/src/core/services/mupdf_service.dart';
import 'package:readaway/src/core/services/notification_service.dart';
import 'package:readaway/src/core/services/window_service.dart';
import 'package:readaway/src/features/library/domain/repositories/library_repository.dart';
import 'package:readaway/src/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/page_content/html/reader_style_resolver.dart';

class MockWindowService extends Mock implements WindowService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockDocumentCoverService extends Mock implements DocumentCoverService {}
class MockLibraryRepository extends Mock implements LibraryRepository {}
class MockMuPdfService extends Mock implements MuPdfService {}

void main() {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

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
        fullJustification: true,
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
      expect(css, contains('text-align: justify !important'));
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

  group('Reflowable Document Reader Repository Tests', () {
    late MockMuPdfService mockMuPdfService;
    late ReaderRepository repository;

    setUpAll(() async {
      final file = File(epubPath);
      if (!await file.exists()) return;

      mockMuPdfService = MockMuPdfService();
      when(() => mockMuPdfService.closeDocument()).thenAnswer((_) async {});

      final windowService = MockWindowService();
      when(() => windowService.setTitle(any())).thenAnswer((_) async {});
      when(() => windowService.setDefaultTitle()).thenAnswer((_) async {});

      final notifService = MockNotificationService();
      final coverService = MockDocumentCoverService();
      final libRepo = MockLibraryRepository();

      repository = ReaderRepositoryImpl(
        mockMuPdfService,
        windowService,
        notifService,
        coverService,
        libRepo,
      );
    });

    tearDownAll(() async {
      await repository.closeDocument().run();
    });

    test('opens EPUB with ReflowableDocumentReader without opening MuPdfService', () async {
      final file = File(epubPath);
      if (!await file.exists()) return;

      final openResult = await repository
          .openDocument(epubPath)
          .run();

      expect(openResult.isRight(), isTrue);
      final info = openResult.getRight().toNullable()!;
      expect(info.isReflowable, isTrue);
      expect(info.pageCount, equals(504));
      expect(info.title, equals('Reverend Insanity'));
      expect(info.outline.length, greaterThan(400));
      expect(info.outline.first.title, isNotEmpty);

      // Verify MuPdfService was never opened for reflowable documents!
      verifyNever(() => mockMuPdfService.openDocument(any()));
      verifyNever(() => mockMuPdfService.getOutLine());
      verifyNever(() => mockMuPdfService.getMetaData(any()));
    });

    test('loads chapter HTML directly without MuPdfService render engine', () async {
      final file = File(epubPath);
      if (!await file.exists()) return;

      final pageDataResult = await repository
          .loadPage(
            0,
            isReflowable: true,
          )
          .run();

      expect(pageDataResult.isRight(), isTrue);
      final pageData = pageDataResult.getRight().toNullable()!;
      expect(pageData.html, isNotNull);
      expect(pageData.html, isNotEmpty);
      expect(pageData.html!.contains('position: absolute'), isFalse);

      verifyNever(() => mockMuPdfService.renderPage(any()));
    });

    test('extracts text from section HTML directly without MuPdfService', () async {
      final file = File(epubPath);
      if (!await file.exists()) return;

      // Section 0 is the front cover image, section 1 has text content
      final textResult = await repository.extractPageText(1).run();
      expect(textResult.isRight(), isTrue);
      final text = textResult.getRight().toNullable()!;
      expect(text, isNotEmpty);
      expect(text, contains('Reverend Insanity'));

      verifyNever(() => mockMuPdfService.extractPageText(any()));
    });

    test('resolves asset bytes from EPUB archive directly', () async {
      final file = File(epubPath);
      if (!await file.exists()) return;

      final bytesResult = await repository.loadAssetBytes('mimetype').run();
      expect(bytesResult.isRight(), isTrue);
      final bytes = bytesResult.getRight().toNullable();
      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes!), contains('application/epub+zip'));
    });
  });
}
