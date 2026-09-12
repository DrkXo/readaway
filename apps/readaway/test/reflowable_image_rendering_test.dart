import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readaway/src/core/services/document_cover_service.dart';
import 'package:readaway/src/core/services/isolate_service.dart';
import 'package:readaway/src/core/services/logging_service.dart';
import 'package:readaway/src/core/services/mupdf_service.dart';
import 'package:readaway/src/core/services/notification_service.dart';
import 'package:readaway/src/core/services/reader/epub_document_reader.dart';
import 'package:readaway/src/core/services/window_service.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/library/domain/repositories/library_repository.dart';
import 'package:readaway/src/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/page_content/html/hyper_page_content.dart';

class MockWindowService extends Mock implements WindowService {}
class MockNotificationService extends Mock implements NotificationService {}
class MockDocumentCoverService extends Mock implements DocumentCoverService {}
class MockLibraryRepository extends Mock implements LibraryRepository {}
class MockLoggingService extends Mock implements LoggingService {}

void main() {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

  group('Reflowable Image Loading & Resolution Tests', () {
    late ReaderRepositoryImpl repository;
    late MuPdfService muPdfService;

    setUpAll(() async {
      final loggingService = MockLoggingService();
      when(() => loggingService.logger).thenReturn(Logger.detached('test'));
      final isolateService = IsolateService(loggingService: loggingService);

      muPdfService = MuPdfService(
        isolateService: isolateService,
        loggingService: loggingService,
      );

      final windowService = MockWindowService();
      when(() => windowService.setTitle(any())).thenAnswer((_) async {});
      when(() => windowService.setDefaultTitle()).thenAnswer((_) async {});

      repository = ReaderRepositoryImpl(
        muPdfService,
        windowService,
        MockNotificationService(),
        MockDocumentCoverService(),
        MockLibraryRepository(),
      );
      await repository.openDocument(epubPath).run();
    });

    tearDownAll(() async {
      await repository.closeDocument().run();
      await muPdfService.dispose();
    });

    test('EpubDocumentReader resolves chapter-relative image paths', () async {
      final reader = await EpubDocumentReader.fromFile(epubPath);
      // Chapter 0 is "OEBPS/front-cover.html"
      // Image in HTML is "../OEBPS/cover-image.jpg"
      final resolved = reader.resolveAssetPath(0, '../OEBPS/cover-image.jpg');
      expect(resolved, equals('OEBPS/cover-image.jpg'));

      final bytes = reader.loadAssetBytes(resolved);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(10000));
      reader.dispose();
    });

    test('ReaderRepository.loadAssetBytes resolves relative image with pageIndex', () async {
      // Direct raw query without pageIndex succeeds via fallback
      final fallbackRes = await repository.loadAssetBytes('../OEBPS/cover-image.jpg').run();
      expect(fallbackRes.isRight(), isTrue);
      expect(fallbackRes.getRight().toNullable(), isNotNull);

      // Query with pageIndex 0 resolves relative to chapter 0
      final pageRes = await repository.loadAssetBytes('../OEBPS/cover-image.jpg', pageIndex: 0).run();
      expect(pageRes.isRight(), isTrue);
      final bytes = pageRes.getRight().toNullable();
      expect(bytes, isNotNull);
      expect(bytes!.length, equals(83303));
    });

    testWidgets('HyperPageContent renders image successfully without errors', (tester) async {
      final reader = await EpubDocumentReader.fromFile(epubPath);
      final html = reader.loadSectionHtml(0);

      var resolvedCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: HyperPageContent(
              html: html,
              prefs: const ReaderPreferences(),
              onLinkTap: (_) {},
              onResolveAssetBytes: (src) async {
                resolvedCalled = true;
                final res = await repository.loadAssetBytes(src, pageIndex: 0).run();
                return res.getRight().toNullable();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(resolvedCalled, isTrue);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsNothing);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      reader.dispose();
    });

    testWidgets('HyperPageContent pre-processes SVG image wrappers and triggers asset resolution', (tester) async {
      const svgCoverHtml = '''
        <div id="page1" class="dp">
          <div class="dp">
            <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="99%" width="100%" viewBox="0 0 599 922">
              <image xlink:href="cover-svg-test.jpg" class="calibre"/>
            </svg>
          </div>
        </div>
      ''';

      var resolvedCalled = false;
      String? requestedSrc;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.light],
          ),
          home: Scaffold(
            body: HyperPageContent(
              html: svgCoverHtml,
              prefs: const ReaderPreferences(),
              onLinkTap: (_) {},
              onResolveAssetBytes: (src) async {
                resolvedCalled = true;
                requestedSrc = src;
                // Return valid 1x1 png bytes so Image renders without error
                return [
                  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
                  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
                  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
                  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
                ];
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(resolvedCalled, isTrue);
      expect(requestedSrc, equals('cover-svg-test.jpg'));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsNothing);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    });

    test('The Fellowship of the Ring EPUB cover image loads and decodes', () async {
      const fellowshipPath =
          '/home/drkxo/Documents/Ebooks/The Fellowship of the Ring (Tolkien, John Ronald Reuel) (Z-Library).epub';
      final reader = await EpubDocumentReader.fromFile(fellowshipPath);
      final resolved = reader.resolveAssetPath(0, 'cover.jpeg');
      final bytes = reader.loadAssetBytes(resolved);
      expect(bytes, isNotNull);
      expect(bytes!.length, equals(34018));

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, equals(510));
      expect(frame.image.height, equals(664));
      reader.dispose();
    });
  });
}
