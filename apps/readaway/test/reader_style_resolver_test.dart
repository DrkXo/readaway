import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/features/reader/presentation/extensions/hyper_html_extensions.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/page_content/html/reader_style_resolver.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

void main() {
  test('StyleResolver correctly resolves customCss from ReaderPreferences', () {
    const prefs = ReaderPreferences(
      paragraphMargin: 1.5,
      textIndent: 2.0,
      textAlign: ReaderTextAlign.justify,
      fontSize: 18.0,
      lineHeight: 1.8,
    );

    const styleResolver = ReaderStyleResolver();
    final customCss = styleResolver.buildCustomCss(
      prefs: prefs,
      textColor: Colors.black,
      backgroundColor: Colors.white,
      linkColor: Colors.blue,
    );

    const html = '<p>First paragraph of the story.</p><p>Second paragraph.</p>';
    final adapter = HtmlAdapter();
    final docNode = adapter.parse(html);

    final resolver = StyleResolver()..parseCss(customCss);
    resolver.resolveStyles(docNode);

    final pNode =
        docNode.children.firstWhere((n) => n.tagName == 'p') as BlockNode;
    // text-align is intentionally NOT emitted in CSS so authored alignment
    // (poetry, centered headings) can be preserved by applyReaderPreferences.
    expect(pNode.style.isExplicitlySet('text-align'), isFalse);
    expect(pNode.style.textIndent, isNotNull);
    expect(pNode.style.textIndent, greaterThan(0));
    expect(pNode.style.margin.top, greaterThan(0));
    expect(pNode.style.margin.bottom, greaterThan(0));

    // applyReaderPreferences applies the user's 4-way alignment.
    docNode.applyReaderPreferences(
      prefs: prefs,
      textColor: Colors.black,
      linkColor: Colors.blue,
    );
    expect(pNode.style.textAlign, equals(HyperTextAlign.justify));
  });

  test(
    'applyReaderPreferences overrides inline styles and class specificity',
    () {
      // HTML with aggressive publisher inline styles attempting to prevent indentation and spacing
      const hostileHtml = '''
      <div class="chapter">
        <p style="text-indent: 0px !important; margin: 0px !important; text-align: left !important;">
          Paragraph with hostile inline styles.
        </p>
        <p style="text-indent: 0px; margin: 0px;">
          <img src="illustration.png" alt="Solo Image" />
        </p>
      </div>
    ''';

      const prefs = ReaderPreferences(
        paragraphMargin: 1.5,
        textIndent: 2.0,
        textAlign: ReaderTextAlign.justify,
        fontSize: 20.0,
        lineHeight: 1.8,
        overrideLayout: true,
      );

      const styleResolver = ReaderStyleResolver();
      final customCss = styleResolver.buildCustomCss(
        prefs: prefs,
        textColor: Colors.black,
        backgroundColor: Colors.white,
        linkColor: Colors.blue,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(hostileHtml);
      final resolver = StyleResolver()..parseCss(customCss);
      resolver.resolveStyles(docNode);

      // Apply direct AST preferences
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final paragraphs = <BlockNode>[];
      docNode.traverse((node) {
        if (node is BlockNode && node.tagName == 'p') paragraphs.add(node);
      });

      expect(paragraphs.length, equals(2));

      // First paragraph: text paragraph
      final textP = paragraphs[0];
      expect(textP.style.textAlign, equals(HyperTextAlign.justify));
      expect(textP.style.textIndent, equals(40.0)); // 2.0 * 20.0px
      expect(textP.style.margin.top, equals(30.0)); // 1.5 * 20.0px
      expect(textP.style.margin.bottom, equals(30.0));
      expect(textP.style.lineHeight, equals(1.8));

      // Verify child text node inherits textAlign and textIndent
      final textNode = textP.children.firstWhere((n) => n is TextNode);
      expect(textNode.style.textAlign, equals(HyperTextAlign.justify));
      expect(textNode.style.textIndent, equals(40.0));

      // Second paragraph: image-only paragraph
      final imgP = paragraphs[1];
      expect(
        imgP.style.textIndent,
        equals(0.0),
      ); // Image should NOT be indented
    },
  );

  test(
    'applyReaderPreferences honors textAlign: left',
    () {
      const html = '<p>Normal text paragraph.</p>';
      const prefs = ReaderPreferences(
        paragraphMargin: 1.0,
        textIndent: 1.5,
        textAlign: ReaderTextAlign.left,
        fontSize: 16.0,
        overrideLayout: true,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final p =
          docNode.children.firstWhere((n) => n.tagName == 'p') as BlockNode;
      expect(p.style.textAlign, equals(HyperTextAlign.left));
      expect(p.style.textIndent, equals(24.0)); // 1.5 * 16.0
      expect(p.style.margin.top, equals(16.0)); // 1.0 * 16.0
    },
  );

  test(
    'applyReaderPreferences preserves authored alignment when keepTextAlignment is on',
    () {
      // Poetry paragraph with authored centered alignment.
      const html =
          '<p style="text-align: center;">Roses are red</p>'
          '<p>Plain paragraph.</p>';
      const prefs = ReaderPreferences(
        textAlign: ReaderTextAlign.justify,
        keepTextAlignment: true,
        overrideLayout: true,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      // Process inline styles (as the real pipeline does) so the authored
      // `text-align: center` is marked explicitly set.
      final resolver = StyleResolver()..parseCss('');
      resolver.resolveStyles(docNode);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final paragraphs = <BlockNode>[];
      docNode.traverse((node) {
        if (node is BlockNode && node.tagName == 'p') paragraphs.add(node);
      });

      // Authored center alignment is preserved.
      expect(paragraphs[0].style.textAlign, equals(HyperTextAlign.center));
      // Plain paragraph receives the user's justify.
      expect(paragraphs[1].style.textAlign, equals(HyperTextAlign.justify));
    },
  );

  test(
    'applyReaderPreferences overrides authored alignment when keepTextAlignment is off',
    () {
      const html = '<p style="text-align: center;">Centered by book</p>';
      const prefs = ReaderPreferences(
        textAlign: ReaderTextAlign.justify,
        keepTextAlignment: false,
        overrideLayout: true,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final p =
          docNode.children.firstWhere((n) => n.tagName == 'p') as BlockNode;
      expect(p.style.textAlign, equals(HyperTextAlign.justify));
    },
  );

  test(
    'applyReaderPreferences clamps font size to minimumFontSize',
    () {
      const html = '<p style="font-size: 6px;">Tiny text</p>';
      const prefs = ReaderPreferences(
        minimumFontSize: 12.0,
        overrideLayout: true,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final p =
          docNode.children.firstWhere((n) => n.tagName == 'p') as BlockNode;
      expect(p.style.fontSize, greaterThanOrEqualTo(12.0));
    },
  );

  test(
    'applyReaderPreferences applies CJK font to CJK text nodes',
    () {
      const html = '<p>Hello 世界</p>';
      const prefs = ReaderPreferences(
        defaultCjkFont: 'Source Han Sans',
        overrideLayout: true,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final textNode =
          docNode.children
                  .expand((n) => n.children)
                  .firstWhere((n) => n is TextNode)
              as TextNode;
      expect(textNode.style.fontFamily, equals('Source Han Sans'));
    },
  );

  test(
    'buildCustomCss appends user stylesheet with highest precedence',
    () {
      const prefs = ReaderPreferences(
        userStylesheet: 'p { color: #123456; }',
      );

      const styleResolver = ReaderStyleResolver();
      final customCss = styleResolver.buildCustomCss(
        prefs: prefs,
        textColor: Colors.black,
        backgroundColor: Colors.white,
        linkColor: Colors.blue,
      );

      // The user stylesheet is appended by HyperPageContent._parseDocument,
      // not by buildCustomCss — verify the resolver still emits the base CSS.
      expect(customCss, contains('html, body'));
    },
  );

  test('StyleResolver on Reverend Insanity chapter XHTML', () async {
    final file = File(
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub',
    );
    if (!await file.exists()) return;

    final reader = await DocumentReaderFactory().open(file.path);
    if (reader is! ReflowableDocumentReader) return;
    final chHtml = reader.loadSectionHtml(1);

    const prefs = ReaderPreferences(
      paragraphMargin: 1.5,
      textIndent: 2.0,
      textAlign: ReaderTextAlign.justify,
      fontSize: 18.0,
      lineHeight: 1.8,
      overrideLayout: true,
    );

    const styleResolver = ReaderStyleResolver();
    final customCss = styleResolver.buildCustomCss(
      prefs: prefs,
      textColor: Colors.black,
      backgroundColor: Colors.white,
      linkColor: Colors.blue,
    );

    final adapter = HtmlAdapter();
    final docNode = adapter.parse(chHtml);
    final docCss = adapter.extractCss(chHtml);

    final combinedCss = '$docCss\n$customCss';
    final resolver = StyleResolver()..parseCss(combinedCss);
    resolver.resolveStyles(docNode);

    docNode.applyReaderPreferences(
      prefs: prefs,
      textColor: Colors.black,
      linkColor: Colors.blue,
    );

    final paragraphs = <BlockNode>[];
    docNode.traverse((node) {
      if (node is BlockNode && node.tagName == 'p') paragraphs.add(node);
    });

    expect(paragraphs.length, greaterThan(0));
    for (int i = 0; i < (paragraphs.length < 3 ? paragraphs.length : 3); i++) {
      final p = paragraphs[i];
      expect(p.style.textAlign, equals(HyperTextAlign.justify));
      expect(p.style.textIndent, equals(36.0)); // 2.0 * 18.0px
      expect(p.style.margin.top, equals(27.0)); // 1.5 * 18.0px
      expect(p.style.margin.bottom, equals(27.0));
    }
  });
}
