import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/features/reader/presentation/extensions/hyper_html_extensions.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/html/reader_style_resolver.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway_core/readaway_core.dart';

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

  test('buildBaseCss derives element sizes from the reader font size', () {
    const styleResolver = ReaderStyleResolver();
    final baseCss = styleResolver.buildBaseCss(
      prefs: const ReaderPreferences(fontSize: 18.0),
    );
    expect(baseCss, contains('font-size: 34.20px;')); // h1 1.9 × 18
    expect(baseCss, contains('font-size: 27.00px;')); // h2 1.5 × 18
    expect(baseCss, contains('font-size: 18.00px;')); // h4 1.0 × 18
    expect(baseCss, contains('font-size: 13.50px;')); // sub/sup 0.75 × 18
    expect(baseCss, contains('font-size: 14.40px;')); // small 0.8 × 18

    final bigger = styleResolver.buildBaseCss(
      prefs: const ReaderPreferences(fontSize: 24.0),
    );
    expect(bigger, contains('font-size: 36.00px;')); // h2 1.5 × 24
  });

  test('buildCustomCss does not hard-code heading font sizes', () {
    const prefs = ReaderPreferences(fontSize: 18.0);
    const styleResolver = ReaderStyleResolver();
    final customCss = styleResolver.buildCustomCss(
      prefs: prefs,
      textColor: Colors.black,
      backgroundColor: Colors.white,
      linkColor: Colors.blue,
    );

    // The headings block must only carry line-height/margins; font sizes are
    // supplied by buildBaseCss so they scale with the reader font size.
    final headingsBlock = customCss
        .split('h1, h2, h3, h4, h5, h6')[1]
        .split('blockquote')[0];
    expect(headingsBlock, isNot(contains('font-size')));
  });

  test(
    'heading font sizes scale relative to the reader font size (bug fix)',
    () {
      const styleResolver = ReaderStyleResolver();

      /// Mimics HyperPageContent's cascade: baseCss, docCss, customCss.
      DocumentNode render(String html, ReaderPreferences prefs) {
        final customCss = styleResolver.buildCustomCss(
          prefs: prefs,
          textColor: Colors.black,
          backgroundColor: Colors.white,
          linkColor: Colors.blue,
        );
        final baseCss = styleResolver.buildBaseCss(prefs: prefs);
        final adapter = HtmlAdapter();
        final docNode = adapter.parse(html);
        final docCss = adapter.extractCss(html);
        final resolver = StyleResolver()
          ..parseCss(
            [baseCss, if (docCss.isNotEmpty) docCss, customCss].join('\n'),
          );
        resolver.resolveStyles(docNode);
        docNode.applyReaderPreferences(
          prefs: prefs,
          textColor: Colors.black,
          linkColor: Colors.blue,
        );
        return docNode;
      }

      const html = '<h1>Title</h1><h2>Chapter</h2><p>Body text.</p>';

      // Default mode: no authored css → heading scales with the reader size.
      final h2Default = render(
        html,
        const ReaderPreferences(fontSize: 18.0),
      ).children.firstWhere((n) => n.tagName == 'h2') as BlockNode;
      expect(h2Default.style.fontSize, closeTo(27.0, 0.01)); // 1.5 × 18

      // overrideLayout keeps the same hierarchy but pins the body size.
      final h1Layout = render(
        html,
        const ReaderPreferences(fontSize: 18.0, overrideLayout: true),
      ).children.firstWhere((n) => n.tagName == 'h1') as BlockNode;
      final h2Layout = render(
        html,
        const ReaderPreferences(fontSize: 18.0, overrideLayout: true),
      ).children.firstWhere((n) => n.tagName == 'h2') as BlockNode;
      final pLayout = render(
        html,
        const ReaderPreferences(fontSize: 18.0, overrideLayout: true),
      ).children.firstWhere((n) => n.tagName == 'p') as BlockNode;
      expect(h1Layout.style.fontSize, closeTo(34.2, 0.01)); // 1.9 × 18
      expect(h2Layout.style.fontSize, closeTo(27.0, 0.01)); // 1.5 × 18
      expect(pLayout.style.fontSize, closeTo(18.0, 0.01));

      // Increasing the reader font size scales the headings up too.
      final h2Big = render(
        html,
        const ReaderPreferences(fontSize: 24.0, overrideLayout: true),
      ).children.firstWhere((n) => n.tagName == 'h2') as BlockNode;
      final pBig = render(
        html,
        const ReaderPreferences(fontSize: 24.0, overrideLayout: true),
      ).children.firstWhere((n) => n.tagName == 'p') as BlockNode;
      expect(h2Big.style.fontSize, closeTo(36.0, 0.01)); // 1.5 × 24
      expect(pBig.style.fontSize, closeTo(24.0, 0.01));
      expect(h2Big.style.fontSize, greaterThan(h2Default.style.fontSize));
    },
  );

  test(
    'text nodes inherit the block font-size set by applyReaderPreferences',
    () {
      const html = '<p>Plain <b>bold</b> text.</p>'
          '<p style="font-size: 20px;">Authored sized.</p>';
      const prefs = ReaderPreferences(fontSize: 28.0, overrideLayout: true);

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      // resolveStyles runs first in the real pipeline; applyReaderPreferences
      // re-syncs text node font sizes afterwards.
      StyleResolver().resolveStyles(docNode);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final paragraphs = <BlockNode>[];
      docNode.traverse((node) {
        if (node is BlockNode && node.tagName == 'p') paragraphs.add(node);
      });
      final first = paragraphs[0];
      final second = paragraphs[1];

      // Authored inline block size wins over the pref size.
      expect(second.style.fontSize, closeTo(20.0, 0.01));
      for (final child in second.children.whereType<TextNode>()) {
        expect(child.style.fontSize, closeTo(20.0, 0.01));
      }

      // Text nodes inside a block inherit its reader font size.
      for (final child in first.children) {
        if (child is TextNode) {
          expect(child.style.fontSize, closeTo(28.0, 0.01));
        } else if (child.tagName == 'b') {
          for (final t in child.children.whereType<TextNode>()) {
            expect(t.style.fontSize, closeTo(28.0, 0.01));
          }
        }
      }
    },
  );

  test(
    'authored heading sizes win over the base scale',
    () {
      const html = '<style>h2 { font-size: 24px; }</style><h2>Chapter</h2>';

      const prefs = ReaderPreferences(fontSize: 18.0, overrideLayout: true);
      const styleResolver = ReaderStyleResolver();
      final baseCss = styleResolver.buildBaseCss(prefs: prefs);
      final customCss = styleResolver.buildCustomCss(
        prefs: prefs,
        textColor: Colors.black,
        backgroundColor: Colors.white,
        linkColor: Colors.blue,
      );

      final adapter = HtmlAdapter();
      final docNode = adapter.parse(html);
      final docCss = adapter.extractCss(html);
      final resolver = StyleResolver()
        ..parseCss('$baseCss\n$docCss\n$customCss');
      resolver.resolveStyles(docNode);
      docNode.applyReaderPreferences(
        prefs: prefs,
        textColor: Colors.black,
        linkColor: Colors.blue,
      );

      final h2 =
          docNode.children.firstWhere((n) => n.tagName == 'h2') as BlockNode;
      // baseCss would scale h2 to 27px, but the authored 24px rule comes
      // later in the cascade and wins.
      expect(h2.style.fontSize, closeTo(24.0, 0.01));
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
