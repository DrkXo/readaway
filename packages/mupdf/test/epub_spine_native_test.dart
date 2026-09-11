import 'dart:io';

import 'package:mupdf/mupdf.dart';
import 'package:test/test.dart';

void main() {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

  group('Native MuPdfEpubSpine', () {
    test('opens EPUB and reads all 504 spine items directly from native C Fitz archive', () {
      final file = File(epubPath);
      if (!file.existsSync()) {
        return;
      }

      final spine = MuPdfEpubSpine.openFile(epubPath);
      try {
        expect(spine.count, equals(504));

        final items = spine.items;
        expect(items.length, equals(504));

        // First item
        final first = items.first;
        expect(first.index, equals(0));
        expect(first.path, isNotEmpty);
        expect(first.mediaType, contains('xhtml'));

        // Load chapter 0 XHTML
        final ch0Html = spine.readChapterXhtml(0);
        expect(ch0Html, isNotEmpty);
        expect(ch0Html.toLowerCase(), contains('<html'));
        expect(ch0Html.toLowerCase(), contains('<body'));
        // Verify it is raw author XHTML, not Fitz stext coordinates
        expect(ch0Html.contains('position: absolute'), isFalse);

        // Load chapter 1 XHTML
        final ch1Html = spine.readChapterXhtml(1);
        expect(ch1Html, isNotEmpty);
        expect(ch1Html, contains('<p'));

        // Read asset
        final asset = spine.readAsset('mimetype');
        expect(asset, isNotNull);
        expect(String.fromCharCodes(asset!), contains('application/epub+zip'));
      } finally {
        spine.dispose();
      }
    });

    test('MuPdfDocument exposes epubSpine and readChapterXhtml', () {
      final file = File(epubPath);
      if (!file.existsSync()) {
        return;
      }

      final doc = MuPdfDocument.openFile(epubPath);
      try {
        expect(doc.isReflowable, isTrue);
        expect(doc.epubSpine, isNotNull);
        expect(doc.epubSpine!.count, equals(504));

        final html = doc.readChapterXhtml(0);
        expect(html, isNotNull);
        expect(html!.toLowerCase(), contains('<html'));
      } finally {
        doc.dispose();
      }
    });
  });

  group('Native MuPdfArchive', () {
    test('lists entries and reads entry bytes', () {
      final file = File(epubPath);
      if (!file.existsSync()) {
        return;
      }

      final arch = MuPdfArchive.openFile(epubPath);
      try {
        expect(arch.count, isPositive);
        expect(arch.hasEntry('mimetype'), isTrue);

        final bytes = arch.readEntry('mimetype');
        expect(bytes, isNotNull);
        expect(String.fromCharCodes(bytes!), contains('application/epub+zip'));
      } finally {
        arch.dispose();
      }
    });
  });
}
