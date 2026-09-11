import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mupdf/mupdf.dart';
import 'package:readaway/src/core/services/epub/epub_spine_reader.dart';

void main() {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

  test('EpubSpineReader parses Reverend Insanity spine items correctly', () async {
    final file = File(epubPath);
    if (!await file.exists()) {
      return;
    }

    final reader = await EpubSpineReader.fromFile(epubPath);
    expect(reader.spineCount, equals(504));

    final firstSpine = reader.spineItems.first;
    expect(firstSpine.index, equals(0));
    expect(firstSpine.href, isNotEmpty);

    // Load first chapter XHTML
    final html = reader.loadSpineHtml(0);
    expect(html, isNotEmpty);
    expect(html.toLowerCase(), contains('<html'));
    expect(html.toLowerCase(), contains('<body'));

    // Verify it is clean semantic HTML, not MuPDF absolute-positioned stext HTML
    expect(html.contains('position: absolute'), isFalse);

    // Verify loading chapter 1 (index 1)
    final chapter1Html = reader.loadSpineHtml(1);
    expect(chapter1Html, isNotEmpty);
    expect(chapter1Html, contains('<p'));
  });

  test('MuPDF chapter count and location synchronization matches EpubSpineReader', () async {
    final file = File(epubPath);
    if (!await file.exists()) {
      return;
    }

    final reader = await EpubSpineReader.fromFile(epubPath);
    final doc = MuPdfDocument.openFile(epubPath);

    try {
      // 1. Chapters in MuPDF equal spine items in EPUB
      expect(doc.chapterCount, equals(reader.spineCount));

      // 2. Initial page is in chapter 0
      final loc0 = doc.locationFromPage(0);
      expect(loc0.chapter, equals(0));

      // 3. Mapping spine index 10 to MuPDF page
      final page10 = doc.pageFromLocation(const MuPdfLocation(chapter: 10, page: 0));
      expect(page10, isNonNegative);

      // And round-trip back
      final locBack = doc.locationFromPage(page10);
      expect(locBack.chapter, equals(10));

      // 4. Verify Mode A renderPage works on reflowable EPUB
      final page = doc.loadPage(0);
      final rendered = page.render(scaleX: 1.0, scaleY: 1.0);
      expect(rendered.width, isPositive);
      expect(rendered.height, isPositive);
      expect(rendered.pixels, isNotEmpty);
      page.dispose();
    } finally {
      doc.dispose();
    }
  });
}
