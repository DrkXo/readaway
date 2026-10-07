import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/features/reader/presentation/extensions/hyper_html_extensions.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/hyper_page_content.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/reader_style_resolver.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/reflowable_image_cache.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/widgets/hyper_reflowable_image.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

Future<Uint8List> _createTestPngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFF0000FF);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderStyleResolver maxImageHeight CSS injection', () {
    const prefs = ReaderPreferences();
    const styleResolver = ReaderStyleResolver();

    test(
      'injects max-height and object-fit when maxImageHeight is provided',
      () {
        final css = styleResolver.buildCustomCss(
          prefs: prefs,
          textColor: Colors.black,
          backgroundColor: Colors.white,
          linkColor: Colors.blue,
          maxImageHeight: 650.0,
        );

        expect(css, contains('img, svg'));
        expect(css, contains('max-height: 650.0px;'));
        expect(css, contains('object-fit: contain;'));
      },
    );

    test('omits max-height when maxImageHeight is not provided', () {
      final css = styleResolver.buildCustomCss(
        prefs: prefs,
        textColor: Colors.black,
        backgroundColor: Colors.white,
        linkColor: Colors.blue,
      );

      expect(css, isNot(contains('max-height:')));
    });
  });

  group('applyReaderPreferences image and paragraph styling', () {
    const prefs = ReaderPreferences(
      paragraphMargin: 1.5,
      fontSize: 16.0,
    );

    test('collapses margins to zero for image-only paragraphs', () {
      const html = '''
<div>
  <p><img src="pic.jpg" /></p>
  <p>Normal text paragraph.</p>
</div>
''';
      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);

      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
        maxImageHeight: 500.0,
      );

      final paragraphs = <BlockNode>[];
      docNode.traverse((node) {
        if (node is BlockNode && node.tagName == 'p') {
          paragraphs.add(node);
        }
      });

      expect(paragraphs, hasLength(2));

      final imgP = paragraphs[0];
      expect(imgP.style.margin, equals(EdgeInsets.zero));

      final textP = paragraphs[1];
      expect(textP.style.margin.top, greaterThan(0));
      expect(textP.style.margin.bottom, greaterThan(0));
    });

    test('clamps explicit image height and scales width proportionally', () {
      const html =
          '<img src="portrait.jpg" style="width: 400px; height: 800px;" />';
      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);

      final resolver = StyleResolver();
      resolver.resolveStyles(docNode);

      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
        maxImageHeight: 400.0,
      );

      AtomicNode? imgNode;
      docNode.traverse((node) {
        if (node is AtomicNode && node.tagName == 'img') {
          imgNode = node;
        }
      });

      expect(imgNode, isNotNull);
      expect(imgNode!.style.height, equals(400.0));
      expect(imgNode!.style.width, equals(200.0));
      expect(imgNode!.style.maxHeight, equals(400.0));
    });

    test('clamps explicit maxHeight on image nodes', () {
      const html = '<img src="portrait.jpg" style="max-height: 900px;" />';
      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);

      final resolver = StyleResolver();
      resolver.resolveStyles(docNode);

      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
        maxImageHeight: 500.0,
      );

      AtomicNode? imgNode;
      docNode.traverse((node) {
        if (node is AtomicNode && node.tagName == 'img') {
          imgNode = node;
        }
      });

      expect(imgNode, isNotNull);
      expect(imgNode!.style.maxHeight, equals(500.0));
    });
  });

  group('HyperPageContent.seedImageDimensions scaling', () {
    final cache = ReflowableImageCache.instance;

    setUp(cache.clear);
    tearDown(cache.clear);

    test('scales oversized cached image to fit within availableHeight and availableWidth', () async {
      // 400x800 image
      final pngBytes = await _createTestPngBytes(400, 800);
      await cache.decode(
        'book1',
        0,
        'tall.png',
        load: () async => pngBytes,
      );

      final doc = DocumentNode(
        children: [
          AtomicNode.img(src: 'tall.png'),
        ],
      );

      HyperPageContent.seedImageDimensions(
        doc,
        cacheNamespace: 'book1',
        chapterIndex: 0,
        availableWidth: 300.0,
        availableHeight: 500.0,
      );

      final imgNode = doc.children[0] as AtomicNode;
      expect(imgNode.style.height, isNotNull);
      expect(imgNode.style.width, isNotNull);
      // Scaled by 500 / 800 = 0.625: height = 500.0, width = 250.0 (<= 300.0)
      expect(imgNode.style.height!, lessThanOrEqualTo(500.0));
      expect(imgNode.style.width!, lessThanOrEqualTo(300.0));
      expect(imgNode.style.height, equals(500.0));
      expect(imgNode.style.width, equals(250.0));
    });

    test('scales oversized wide image to fit within availableWidth', () async {
      // 800x400 image
      final pngBytes = await _createTestPngBytes(800, 400);
      await cache.decode(
        'book1',
        0,
        'wide.png',
        load: () async => pngBytes,
      );

      final doc = DocumentNode(
        children: [
          AtomicNode.img(src: 'wide.png'),
        ],
      );

      HyperPageContent.seedImageDimensions(
        doc,
        cacheNamespace: 'book1',
        chapterIndex: 0,
        availableWidth: 400.0,
        availableHeight: 600.0,
      );

      final imgNode = doc.children[0] as AtomicNode;
      // Scaled by 400 / 800 = 0.5: width = 400.0, height = 200.0
      expect(imgNode.style.width, equals(400.0));
      expect(imgNode.style.height, equals(200.0));
    });
  });

  group('HyperReflowableImage async decode notification and sizing', () {
    testWidgets(
      'triggers onImageDecoded and renders image within constraints',
      (tester) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 800), Paint());
        final testImage = await recorder.endRecording().toImage(400, 800);

        var decodedCallbackCount = 0;

        final node = AtomicNode.img(src: 'test_tall.png');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: HyperReflowableImage(
                  node: node,
                  availableWidth: 300.0,
                  availableHeight: 500.0,
                  onResolveDecoded: () async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 10),
                    );
                    return testImage;
                  },
                  onImageDecoded: () {
                    decodedCallbackCount++;
                  },
                ),
              ),
            ),
          ),
        );

        // Initially shows placeholder
        expect(find.byType(HyperReflowableImage), findsOneWidget);
        expect(decodedCallbackCount, equals(0));

        // Settle the async decode
        await tester.pumpAndSettle();

        // Callback should have been called
        expect(decodedCallbackCount, equals(1));

        // The image widget should be sized within constraints
        final rawImageFinder = find.byType(RawImage);
        expect(rawImageFinder, findsOneWidget);
        final rawImageWidget = tester.widget<RawImage>(rawImageFinder);
        expect(rawImageWidget.width, equals(250.0));
        expect(rawImageWidget.height, equals(500.0));
      },
    );
  });
}
