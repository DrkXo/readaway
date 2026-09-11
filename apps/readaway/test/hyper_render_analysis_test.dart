// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:mupdf/mupdf.dart';

void main() {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

  late String mupdfSampleHtml;

  setUpAll(() {
    if (File(epubPath).existsSync()) {
      final doc = MuPdfDocument.openFile(epubPath);
      doc.layout(width: 400, height: 800, em: 14);
      final page = doc.loadPage(10);
      mupdfSampleHtml = page.extractHtml(preserveImages: false) ?? '';
      page.dispose();
      doc.dispose();
    } else {
      mupdfSampleHtml = '''
        <!DOCTYPE html>
        <html>
        <head><style>p{position:absolute;margin:0}</style></head>
        <body>
        <div id="page1" style="width:400pt;height:800pt">
          <p style="top:40pt;left:50pt;line-height:14pt">
            <span style="font-family:Charis SIL;font-size:14pt;color:#333333">Chapter 1: The heart of a demon</span>
          </p>
        </div>
        </body>
        </html>
      ''';
    }
  });

  group('HyperRender - Unified Document Tree (UDT) & Adapter Analysis', () {
    test('HtmlAdapter parses MuPDF extracted HTML into UDT correctly', () {
      final sw = Stopwatch()..start();
      final adapter = HtmlAdapter();
      final docNode = adapter.parse(mupdfSampleHtml);
      final elapsedMs = sw.elapsedMilliseconds;

      print('[Benchmark] Parsed MuPDF HTML (${mupdfSampleHtml.length} chars) in ${elapsedMs}ms');
      expect(docNode, isNotNull);
      expect(docNode.type, equals(NodeType.document));
      expect(docNode.children, isNotEmpty);

      // Walk UDT
      int blockCount = 0;
      int inlineCount = 0;
      int textCount = 0;
      docNode.traverse((node) {
        if (node is BlockNode) blockCount++;
        if (node is InlineNode) inlineCount++;
        if (node is TextNode) textCount++;
      });

      print('  UDT Node statistics:');
      print('    Blocks: $blockCount');
      print('    Inlines: $inlineCount');
      print('    TextNodes: $textCount');
      print('    Total text extracted from UDT: ${docNode.textContent.length} chars');

      expect(blockCount, greaterThan(0));
      expect(textCount, greaterThan(0));
    });

    test('CSS cascade and computed styles resolution on UDT nodes', () {
      const styledHtml = '''
        <style>
          .chapter-title { font-size: 22px; color: #1E88E5; margin-bottom: 12px; }
          .highlight { background-color: #FFF9C4; }
          p { line-height: 1.6; }
        </style>
        <div class="content">
          <h1 class="chapter-title">Chapter 1</h1>
          <p>This is a <span class="highlight">crucial</span> observation.</p>
        </div>
      ''';

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(styledHtml);
      final css = adapter.extractCss(styledHtml);
      final resolver = StyleResolver()..parseCss(css);
      resolver.resolveStyles(docNode);

      UDTNode? titleNode;
      UDTNode? highlightNode;
      docNode.traverse((node) {
        if (node.classList.contains('chapter-title')) titleNode = node;
        if (node.classList.contains('highlight')) highlightNode = node;
      });

      expect(titleNode, isNotNull);
      expect(titleNode!.style.fontSize, equals(22.0));
      expect(titleNode!.style.color, equals(const Color(0xFF1E88E5)));

      expect(highlightNode, isNotNull);
      expect(highlightNode!.style.backgroundColor, equals(const Color(0xFFFFF9C4)));
    });
  });

  group('HyperRender - Extensibility Architecture', () {
    testWidgets('HyperPluginRegistry intercepts custom tags (Block & Inline)', (tester) async {
      // Custom block plugin: Callout / Note box
      final registry = HyperPluginRegistry()
        ..register(_TestCalloutPlugin())
        ..register(_TestBadgePlugin());

      const customHtml = '''
        <p>Normal text before.</p>
        <callout type="warning">Important warning message here</callout>
        <p>User status: <user-badge status="active">VIP</user-badge></p>
      ''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: customHtml,
              pluginRegistry: registry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom callout widget rendered
      expect(find.byKey(const Key('test_callout_widget')), findsOneWidget);
      expect(find.text('Important warning message here'), findsOneWidget);

      // Verify custom inline badge rendered
      expect(find.byKey(const Key('test_badge_widget')), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
    });

    testWidgets('widgetBuilder allows granular node interception without plugins', (tester) async {
      const htmlWithAudio = '''
        <p>Listen to pronunciation:</p>
        <audio src="audio/test.mp3" controls></audio>
      ''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: htmlWithAudio,
              widgetBuilder: (node) {
                if (node is AtomicNode && node.tagName == 'audio') {
                  return Container(
                    key: const Key('custom_audio_player'),
                    child: Text('Custom Audio: ${node.attributes['src']}'),
                  );
                }
                return null; // Fall back to default
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_audio_player')), findsOneWidget);
      expect(find.text('Custom Audio: audio/test.mp3'), findsOneWidget);
    });

    testWidgets('HyperImageLoader hooks image decoding from custom source', (tester) async {
      // Mock custom image loader (e.g. for EPUB archive memory zip or MuPDF pixmaps)
      var customLoaderCalled = false;
      void customLoader(String src, void Function(ui.Image) onLoad, void Function(Object) onError) {
        customLoaderCalled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: '<img src="epub://cover.jpg" width="100" height="100" />',
              imageLoader: customLoader,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(customLoaderCalled, isTrue);
    });

    testWidgets('HyperViewerController drives scroll to ID / anchor and TOC extraction', (tester) async {
      final controller = HyperViewerController();

      const docWithAnchors = '''
        <h1 id="top">Title</h1>
        <p>Paragraph 1</p>
        <h2 id="sec-1">Section 1</h2>
        <p>Content of section 1</p>
        <h2 id="sec-2">Section 2</h2>
        <p>Content of section 2</p>
      ''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: docWithAnchors,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Heading anchors extracted
      final headings = controller.headings;
      print('Extracted headings via HyperViewerController: ${headings.length}');
      for (final h in headings) {
        print('  Level ${h.level}: cssId="${h.cssId}", text="${h.text}"');
      }

      expect(headings.length, greaterThanOrEqualTo(3));
      expect(headings.map((h) => h.cssId), containsAll(['top', 'sec-1', 'sec-2']));
    });

    testWidgets('HyperPageController controls paged mode navigation', (tester) async {
      final pageCtrl = HyperPageController();

      final chaptersHtml = List.generate(
        5,
        (i) => '<div id="ch-$i"><h1>Chapter $i</h1><p>Content for page $i</p></div>',
      ).join('<hr>');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HyperViewer(
              html: chaptersHtml,
              mode: HyperRenderMode.paged,
              pageController: pageCtrl,
              renderConfig: const HyperRenderConfig(useMicrotaskParsing: true),
              placeholderBuilder: (_) => const SizedBox(key: Key('placeholder')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(pageCtrl.pageCount, greaterThan(0));
      expect(pageCtrl.currentPage.value, equals(0));

      if (pageCtrl.pageCount > 1) {
        pageCtrl.nextPage();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(pageCtrl.currentPage.value, equals(1));
      }
    });
  });

  group('HyperRender - Security & Heuristics', () {
    test('HtmlSanitizer strips scripts, onload, and dangerous javascript URIs', () {
      const maliciousHtml = '''
        <p>Normal text</p>
        <script>alert("XSS")</script>
        <img src="valid.jpg" onerror="stealCookies()" />
        <a href="javascript:doEvil()">Click me</a>
      ''';

      final sanitized = HtmlSanitizer.sanitize(maliciousHtml);
      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, isNot(contains('onerror')));
      expect(sanitized, isNot(contains('javascript:')));
      expect(sanitized, contains('<p>Normal text</p>'));
      expect(sanitized, contains('<img src="valid.jpg">'));
    });

    test('HtmlHeuristics detects complexity (unsupported CSS, forms, tables)', () {
      const simple = '<p>Simple text</p>';
      expect(HtmlHeuristics.isComplex(simple), isFalse);

      // MuPDF HTML uses position:absolute, which is detected by hasUnsupportedCss
      const mupdfAbsoluteHtml = '<p style="position:absolute;margin:0">Page text</p>';
      expect(HtmlHeuristics.hasUnsupportedCss(mupdfAbsoluteHtml), isTrue);
      expect(HtmlHeuristics.isComplex(mupdfAbsoluteHtml), isTrue);

      const formHtml = '<form><input type="text" /></form>';
      expect(HtmlHeuristics.hasForms(formHtml), isTrue);
      expect(HtmlHeuristics.hasUnsupportedElements(formHtml), isTrue);
      expect(HtmlHeuristics.isComplex(formHtml), isTrue);
    });
  });
}

// Custom block-tier plugin
class _TestCalloutPlugin extends HyperNodePlugin {
  @override
  List<String> get tagNames => ['callout'];

  @override
  bool get isInline => false;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    return Container(
      key: const Key('test_callout_widget'),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade800),
      ),
      child: Text(
        node.textContent,
        style: ctx.baseStyle.copyWith(color: Colors.black87),
      ),
    );
  }
}

// Custom inline-tier plugin
class _TestBadgePlugin extends HyperNodePlugin {
  @override
  List<String> get tagNames => ['user-badge'];

  @override
  bool get isInline => true;

  @override
  Widget? buildWidget(UDTNode node, HyperPluginBuildContext ctx) {
    return Container(
      key: const Key('test_badge_widget'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        node.textContent,
        style: ctx.baseStyle.copyWith(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
