import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart'
    show AtomicNode, HtmlAdapter, HyperSelectionOverlay, RenderHyperBox;
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/hyper_page_content.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway_core/readaway_core.dart';

RenderHyperBox? _findHyperBox(RenderObject? root) {
  if (root == null) return null;
  if (root is RenderHyperBox) return root;
  RenderHyperBox? found;
  root.visitChildren((child) => found ??= _findHyperBox(child));
  return found;
}

void main() {
  group('XHTML Self-Closing and Background Image Regressions', () {
    test('Self-closing script and style do not swallow body content', () {
      const xhtml = '''
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Test</title>
  <script src="js/book.js"/>
  <style type="text/css"/>
</head>
<body>
  <h1>Chapter Heading</h1>
  <p>Visible chapter text that must not be swallowed.</p>
</body>
</html>''';

      const transformer = HtmlCleanupTransformer();
      final cleaned = transformer.transform(
        const TransformContext(content: xhtml),
      );

      final adapter = HtmlAdapter();
      final doc = adapter.parse(cleaned);

      expect(doc.textContent, contains('Chapter Heading'));
      expect(
        doc.textContent,
        contains('Visible chapter text that must not be swallowed.'),
      );
      expect(doc.children, isNotEmpty);
    });

    testWidgets('HyperPageContent renders text from self-closing XHTML', (
      tester,
    ) async {
      const xhtml = '''
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <script src="js/book.js"/>
</head>
<body>
  <p>Rendered paragraph content.</p>
</body>
</html>''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: HyperPageContent(
                html: xhtml,
                prefs: const ReaderPreferences(),
                chapterIndex: 0,
                cacheNamespace: 'xhtml_test',
                onLinkTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = _findHyperBox(
        tester.renderObject(find.byType(HyperSelectionOverlay)),
      );
      expect(box, isNotNull);
      expect(box!.debugFragments(), isNotEmpty);
    });

    test('Background image cover div converted to img tag', () {
      const coverHtml = '''
<div id="cover-image" style="background-image:url('images/tbbcover.png'); background-size: 100% 100%; width: 100%; height: 100%;"/>
''';

      final bgImgRegex = RegExp(
        r'''<div\b[^>]*style=["'][^"']*background-image:\s*url\(['"]?([^'"\)]+)['"]?\)[^"']*["'][^>]*>(?:<\/div>)?''',
        caseSensitive: false,
      );

      final converted = coverHtml.replaceAllMapped(bgImgRegex, (m) {
        final src = m.group(1);
        return '<img src="$src" style="max-width: 100%; height: auto;" />';
      });

      final adapter = HtmlAdapter();
      final doc = adapter.parse(converted);

      int imgCount = 0;
      doc.traverse((n) {
        if (n is AtomicNode && n.tagName == 'img') {
          imgCount++;
          expect(n.src, equals('images/tbbcover.png'));
        }
      });
      expect(imgCount, equals(1));
    });
  });

  group("The Beauty's Blade EPUBs Real File Verification", () {
    const reflowPath =
        "/home/drkxo/Documents/Ebooks/The Beauty's Blade (Reflowable) [HZF-B].epub";
    const fixedPath =
        "/home/drkxo/Documents/Ebooks/The Beauty's Blade (Fixed) [HZF-B].epub";

    final hasReflow = File(reflowPath).existsSync();
    final hasFixed = File(fixedPath).existsSync();

    testWidgets(
      'Reflowable EPUB loads and renders content without blank pages',
      (tester) async {
        if (!hasReflow) return;

        final reader = await EpubDocumentReader.open(reflowPath);
        expect(reader.sectionCount, greaterThan(2));

        // Section 2 is Chapter 1
        final html = reader.loadSectionHtml(2);
        expect(html, isNot(contains('<script src="js/book.js"/>')));
        expect(html, contains('<script src="js/book.js"></script>'));

        final text = HtmlTextExtractor.extractPageText(html);
        expect(text.length, greaterThan(1000));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: HyperPageContent(
                  html: html,
                  prefs: const ReaderPreferences(),
                  chapterIndex: 2,
                  cacheNamespace: 'reflow_real_test',
                  onLinkTap: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final box = _findHyperBox(
          tester.renderObject(find.byType(HyperSelectionOverlay)),
        );
        expect(box, isNotNull);
        expect(box!.debugFragments().length, greaterThan(50));
      },
    );

    testWidgets('Fixed EPUB loads and renders cover and page 1 content', (
      tester,
    ) async {
      if (!hasFixed) return;

      final reader = await EpubDocumentReader.open(fixedPath);
      expect(reader.sectionCount, greaterThan(1));

      // Section 1 is Page 1
      final page1Html = reader.loadSectionHtml(1);
      final page1Text = HtmlTextExtractor.extractPageText(page1Html);
      expect(page1Text.length, greaterThan(500));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 612,
              height: 792,
              child: HyperPageContent(
                html: page1Html,
                prefs: const ReaderPreferences(),
                chapterIndex: 1,
                cacheNamespace: 'fixed_real_test',
                onLinkTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = _findHyperBox(
        tester.renderObject(find.byType(HyperSelectionOverlay)),
      );
      expect(box, isNotNull);
      expect(box!.debugFragments().length, greaterThan(50));
    });
  });
}
