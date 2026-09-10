// ignore_for_file: avoid_print
import 'dart:io';
import 'package:mupdf/mupdf.dart';

void main() {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

  if (!File(epubPath).existsSync()) {
    stderr.writeln('EPUB file not found: $epubPath');
    exit(1);
  }

  print('=== Opening EPUB ===');
  final doc = MuPdfDocument.openFile(epubPath);

  try {
    print('isReflowable: ${doc.isReflowable}');
    print('Initial page count (before layout): ${doc.pageCount}');
    print('Chapter count: ${doc.chapterCount}');

    // Test layout for typical mobile / reader screen:
    // e.g. 400x800 points, 12pt font
    print('\n=== Applying Document Layout (400 x 800, 12pt font) ===');
    final stopwatch = Stopwatch()..start();
    doc.layout(width: 400, height: 800, em: 12.0);
    stopwatch.stop();
    print('Layout completed in ${stopwatch.elapsedMilliseconds} ms');

    final postLayoutPageCount = doc.pageCount;
    print('Page count after layout: $postLayoutPageCount');

    // Test Table of Contents (Outline)
    print('\n=== Reading Outline / TOC ===');
    final outline = doc.outline;
    print('Total outline items: ${outline.length}');
    if (outline.isNotEmpty) {
      print('First 5 TOC items:');
      for (var i = 0; i < outline.length && i < 5; i++) {
        final item = outline[i];
        print('  [$i] "${item.title}" -> chapter: ${item.chapter}, page: ${item.page}, uri: ${item.uri}');
      }
    }

    // Test Chapters and Chapter Pages
    print('\n=== Chapter Inspection ===');
    final chCount = doc.chapterCount;
    print('Total chapters: $chCount');
    for (var ch = 0; ch < chCount && ch < 3; ch++) {
      final pagesInCh = doc.chapterPageCount(ch);
      print('  Chapter $ch has $pagesInCh page(s)');
    }

    // Load first page and extract text & HTML
    print('\n=== Page 0 Extraction & Rendering ===');
    final page0 = doc.loadPage(0);
    try {
      print('Page 0 dimensions: ${page0.width} x ${page0.height}');
      final text = page0.extractText();
      final textPreview = (text != null && text.length > 200)
          ? '${text.substring(0, 200)}...'
          : text;
      print('Page 0 plain text preview:\n---\n$textPreview\n---');

      final html = page0.extractHtml(preserveImages: false);
      final htmlPreview = (html != null && html.length > 200)
          ? '${html.substring(0, 200)}...'
          : html;
      print('Page 0 HTML preview:\n---\n$htmlPreview\n---');

      // Test rendering to pixmap
      final renderWatch = Stopwatch()..start();
      final rendered = page0.render(scaleX: 1.5, scaleY: 1.5);
      renderWatch.stop();
      print('Rendered Page 0 in ${renderWatch.elapsedMilliseconds} ms: '
          '${rendered.width}x${rendered.height} px, ${rendered.pixels.length} bytes');

      // Test display list
      final dlWatch = Stopwatch()..start();
      final dl = page0.toDisplayList();
      final dlRender = dl.render(scaleX: 1.0, scaleY: 1.0);
      dlWatch.stop();
      print('Display list created and rendered in ${dlWatch.elapsedMilliseconds} ms: '
          '${dlRender.width}x${dlRender.height} px');
      dl.dispose();
    } finally {
      page0.dispose();
    }

    // Test interactive links on Page 0 or first few pages
    print('\n=== Checking Links on first few pages ===');
    for (var p = 0; p < postLayoutPageCount && p < 5; p++) {
      final links = doc.pageLinks(p);
      if (links.isNotEmpty) {
        print('Page $p has ${links.length} link(s):');
        for (final l in links.take(3)) {
          print('  uri: ${l.uri}, targetPage: ${l.pageNumber}, isInternal: ${l.isInternal}');
        }
      }
    }

    // Load Page 14 (Chapter 1)
    print('\n=== Chapter 1 (Page 14) Content & Search Verification ===');
    final ch1Page = doc.loadPage(14);
    try {
      final ch1Text = ch1Page.extractText() ?? '';
      print('Chapter 1 Page 14 text length: ${ch1Text.length} chars');
      final snippet = ch1Text.length > 300 ? ch1Text.substring(0, 300) : ch1Text;
      print('Chapter 1 snippet:\n$snippet\n...');

      // Search inside Chapter 1
      final hits = ch1Page.searchQuads('demon');
      print('Found ${hits.length} hit(s) for word "demon"');
    } finally {
      ch1Page.dispose();
    }

    // Test CSS Customization & Dynamic Layout
    print('\n=== Testing CSS Customization & Dynamic Reflow ===');
    
    // Layout 1: Small font (10pt)
    doc.layout(width: 400, height: 800, em: 10.0);
    final smallFontPages = doc.pageCount;
    print('Pages with 10pt font: $smallFontPages');

    // Layout 2: Large font (20pt)
    doc.layout(width: 400, height: 800, em: 20.0);
    final largeFontPages = doc.pageCount;
    print('Pages with 20pt font: $largeFontPages');
    assert(largeFontPages > smallFontPages, 'Larger font must produce more pages');

    // Layout 3: Wide tablet screen (800x1200, 14pt)
    doc.layout(width: 800, height: 1200, em: 14.0);
    final tabletPages = doc.pageCount;
    print('Pages with tablet layout (800x1200, 14pt): $tabletPages');
    assert(tabletPages < largeFontPages, 'Larger viewport must produce fewer pages');

    // Test User CSS injection (e.g. override publisher fonts, line-height, and dark mode)
    print('\n=== Applying Custom User CSS ===');
    const customDarkCss = '''
      body {
        background-color: #181818;
        color: #e0e0e0;
        font-family: serif;
        line-height: 2.0;
        margin: 2em;
      }
      p {
        text-indent: 1.5em;
        font-size: 1.2em;
      }
    ''';
    doc.style(usePublisherCss: false, userCss: customDarkCss);
    doc.layout(width: 400, height: 800, em: 14.0);
    final styledPages = doc.pageCount;
    print('Pages with custom dark CSS & 2.0 line-height: $styledPages');

    // Render Page 14 with custom CSS applied
    final ch1StyledPage = doc.loadPage(14);
    final styledRender = ch1StyledPage.render(scaleX: 1.0, scaleY: 1.0);
    print('Rendered Page 14 with custom CSS: ${styledRender.width}x${styledRender.height} px');
    ch1StyledPage.dispose();

    print('\nALL EPUB CHECKS PASSED SUCCESSFULLY!');
  } finally {
    doc.dispose();
  }
}
