import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mupdf/mupdf.dart';
import 'package:test/test.dart';

void main() {
  late Uint8List samplePdfBytes;
  late File tempPdfFile;

  setUpAll(() {
    samplePdfBytes = _buildTestPdf();
    tempPdfFile = File('${Directory.systemTemp.path}/mupdf_unit_test.pdf');
    tempPdfFile.writeAsBytesSync(samplePdfBytes);
  });

  tearDownAll(() {
    if (tempPdfFile.existsSync()) {
      tempPdfFile.deleteSync();
    }
  });

  group('MuPdfDocument Lifecycle & Inspection', () {
    test('openBytes succeeds and reports valid page count', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        expect(doc.pageCount, equals(2));
        expect(doc.needsPassword, isFalse);
        expect(doc.isReflowable, isFalse);
      } finally {
        doc.dispose();
      }
    });

    test('openFile succeeds from temp file', () {
      final doc = MuPdfDocument.openFile(tempPdfFile.path);
      try {
        expect(doc.pageCount, equals(2));
      } finally {
        doc.dispose();
      }
    });

    test('open non-existent file throws MuPdfException cleanly', () {
      expect(
        () => MuPdfDocument.openFile('/non_existent_file_path.pdf'),
        throwsA(isA<MuPdfException>()),
      );
    });

    test('open corrupt bytes throws MuPdfException cleanly without crash', () {
      final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(
        () => MuPdfDocument.openBytes(corruptBytes),
        throwsA(isA<MuPdfException>()),
      );
    });

    test('clone creates thread-safe handle sharing store', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final clone = doc.clone();
        try {
          expect(clone.pageCount, equals(2));
          final page = clone.loadPage(0);
          expect(page.width, greaterThan(0));
          page.dispose();
        } finally {
          clone.dispose();
        }
      } finally {
        doc.dispose();
      }
    });
  });

  group('MuPdfPage Properties & Rendering', () {
    test('page dimensions and bounds', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          expect(page.width, equals(612.0));
          expect(page.height, equals(792.0));
          expect(page.rotation, equals(0));

          final bb = page.boundBox;
          expect(bb.width, equals(612.0));
          expect(bb.height, equals(792.0));
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });

    test('page rendering produces valid pixel buffer', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          final rendered = page.render(scaleX: 1.0, scaleY: 1.0);
          expect(rendered.width, equals(612));
          expect(rendered.height, equals(792));
          expect(rendered.components, equals(3)); // RGB
          expect(rendered.stride, greaterThanOrEqualTo(612 * 3));
          expect(rendered.pixels.length, equals(rendered.height * rendered.stride));
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });

    test('page rendering with alpha and colorspaces', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          final renderedRgba = page.render(scaleX: 0.5, scaleY: 0.5, alpha: true);
          expect(renderedRgba.components, equals(4)); // RGBA
          expect(renderedRgba.width, equals(306));
          expect(renderedRgba.height, equals(396));

          final renderedGray = page.render(scaleX: 0.5, scaleY: 0.5, cs: csGray);
          expect(renderedGray.components, equals(1)); // Gray
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });
  });

  group('Display Lists (Vector Caching & Tile Rendering)', () {
    test('creates display list, renders full page and sub-rectangle tile', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final page = doc.loadPage(0);
        final dl = page.toDisplayList();
        page.dispose(); // Can safely dispose page; display list retains vector data!

        try {
          // Full render from display list
          final full = dl.render(scaleX: 1.0, scaleY: 1.0);
          expect(full.width, equals(612));
          expect(full.height, equals(792));

          // Tile render: render a 200x200 crop area at 2x scale
          final tile = dl.renderRect(
            x0: 50,
            y0: 50,
            x1: 250,
            y1: 250,
            scaleX: 2.0,
            scaleY: 2.0,
          );
          expect(tile.width, equals(400));
          expect(tile.height, equals(400));
          expect(tile.pixels.isNotEmpty, isTrue);
        } finally {
          dl.dispose();
        }
      } finally {
        doc.dispose();
      }
    });
  });

  group('Cancellation via MuPdfCookie', () {
    test('cookie abort flag can be set safely', () {
      final cookie = MuPdfCookie();
      try {
        cookie.abort();
        final doc = MuPdfDocument.openBytes(samplePdfBytes);
        try {
          final page = doc.loadPage(0);
          try {
            // Rendering with already-aborted cookie terminates safely
            final rendered = page.render(scaleX: 1.0, scaleY: 1.0, cookie: cookie);
            expect(rendered.width, greaterThan(0));
          } finally {
            page.dispose();
          }
        } finally {
          doc.dispose();
        }
      } finally {
        cookie.dispose();
      }
    });
  });

  group('Text Extraction & Search Quads', () {
    test('plain text and HTML extraction', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          final text = page.extractText();
          expect(text, isNotNull);
          expect(text, contains('Hello MuPDF World'));

          final html = page.extractHtml(preserveImages: false);
          expect(html, isNotNull);
          expect(html, contains('Hello MuPDF World'));
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });

    test('searchQuads finds text and returns 4-corner quads', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          final hits = page.searchQuads('World');
          expect(hits.length, equals(1));
          final hit = hits.first;
          expect(hit.urX, greaterThan(hit.ulX));
          expect(hit.llY, greaterThanOrEqualTo(hit.ulY));
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });
  });

  group('Interactive Links and URI Resolution', () {
    test('extracts links with internal and external targets safely', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        final links = doc.pageLinks(0);
        expect(links.length, equals(2));

        final internal = links.where((l) => l.isInternal).toList();
        expect(internal.length, equals(1));
        expect(internal.single.pageNumber, equals(1)); // Targets Page 2 (index 1)

        final external = links.where((l) => !l.isInternal).toList();
        expect(external.length, equals(1));
        expect(external.single.uri, equals('https://example.com'));

        // Resolve URI
        final resolvedPage = doc.resolveUri(internal.single.uri);
        expect(resolvedPage, equals(1));
      } finally {
        doc.dispose();
      }
    });
  });

  group('CSS Customization & Dynamic Layout', () {
    const sampleEpubPath =
        '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';

    test('layout on fixed-layout PDF executes without error', () {
      final doc = MuPdfDocument.openBytes(samplePdfBytes);
      try {
        expect(() => doc.layout(width: 400, height: 800, em: 12.0), returnsNormally);
      } finally {
        doc.dispose();
      }
    });

    test('reflowable EPUB dynamic pagination based on font size & viewport', () {
      if (!File(sampleEpubPath).existsSync()) return;

      final doc = MuPdfDocument.openFile(sampleEpubPath);
      try {
        expect(doc.isReflowable, isTrue);

        // Layout 1: Compact font (10pt)
        doc.layout(width: 400, height: 800, em: 10.0);
        final smallFontPages = doc.pageCount;

        // Layout 2: Large font (20pt)
        doc.layout(width: 400, height: 800, em: 20.0);
        final largeFontPages = doc.pageCount;

        expect(largeFontPages, greaterThan(smallFontPages));

        // Layout 3: Tablet screen (800x1200)
        doc.layout(width: 800, height: 1200, em: 14.0);
        final tabletPages = doc.pageCount;

        expect(tabletPages, lessThan(largeFontPages));
      } finally {
        doc.dispose();
      }
    });

    test('custom user CSS styling and dark mode injection', () {
      if (!File(sampleEpubPath).existsSync()) return;

      final doc = MuPdfDocument.openFile(sampleEpubPath);
      try {
        const darkThemeCss = '''
          body {
            background-color: #1a1a1a;
            color: #f0f0f0;
            font-family: serif;
            line-height: 2.2;
            margin: 3em;
          }
          p {
            text-indent: 2em;
          }
        ''';

        // Apply custom stylesheet overriding publisher styles
        expect(
          () => doc.style(usePublisherCss: false, userCss: darkThemeCss),
          returnsNormally,
        );

        // Apply layout with custom style
        doc.layout(width: 400, height: 800, em: 14.0);
        expect(doc.pageCount, greaterThan(0));

        // Verify page rendering with custom styles
        final page = doc.loadPage(14);
        try {
          final rendered = page.render(scaleX: 1.0, scaleY: 1.0);
          expect(rendered.width, equals(400));
          expect(rendered.height, equals(800));
          expect(rendered.pixels.isNotEmpty, isTrue);
        } finally {
          page.dispose();
        }

        // Test global setUserCss
        expect(
          () => doc.setUserCss('p { line-height: 1.8; }'),
          returnsNormally,
        );
      } finally {
        doc.dispose();
      }
    });
  });

  group('Reader Features: Bookmarks, Selection & Word Extraction', () {
    late Uint8List pdfBytes;

    setUpAll(() {
      pdfBytes = _buildTestPdf();
    });

    test('Location conversions (flat page <-> chapter/page tuple)', () {
      final doc = MuPdfDocument.openBytes(pdfBytes);
      try {
        final loc0 = doc.locationFromPage(0);
        expect(loc0.chapter, equals(0));
        expect(loc0.page, equals(0));

        final loc1 = doc.locationFromPage(1);
        expect(loc1.chapter, equals(0));
        expect(loc1.page, equals(1));

        final page0 = doc.pageFromLocation(loc0);
        expect(page0, equals(0));

        final page1 = doc.pageFromLocation(loc1);
        expect(page1, equals(1));
      } finally {
        doc.dispose();
      }
    });

    test('Interactive text selection returns snapped points, quads and text', () {
      final doc = MuPdfDocument.openBytes(pdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          final words = page.extractWords();
          expect(words, isNotEmpty);
          final hello = words.firstWhere((w) => w.text == 'Hello');

          // Select region starting at "Hello" and dragging past it
          final sel = page.selectText(
            MuPdfPoint(hello.x0, hello.y0 + (hello.height / 2)),
            MuPdfPoint(hello.x1 + 100, hello.y1),
            mode: MuPdfSelectMode.words,
          );
          expect(sel.isNotEmpty, isTrue);
          expect(sel.text, contains('Hello'));
          expect(sel.quads, isNotEmpty);
          expect(sel.snappedStart.x, isNotNull);
          expect(sel.snappedEnd.x, isNotNull);
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });

    test('Structured word extraction returns word bounding boxes for TTS sync', () {
      final doc = MuPdfDocument.openBytes(pdfBytes);
      try {
        final page = doc.loadPage(0);
        try {
          final words = page.extractWords();
          expect(words, isNotEmpty);
          final wordTexts = words.map((w) => w.text).toList();
          expect(wordTexts, contains('Hello'));
          expect(wordTexts, contains('World'));

          // Check coordinates
          final helloWord = words.firstWhere((w) => w.text == 'Hello');
          expect(helloWord.width, greaterThan(0));
          expect(helloWord.height, greaterThan(0));
          expect(helloWord.x0, greaterThanOrEqualTo(0));
          expect(helloWord.y0, greaterThanOrEqualTo(0));
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });

    test('Reflow Bookmarks persist reading location across layout changes', () {
      const epubPath =
          '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';
      if (!File(epubPath).existsSync()) return;

      final doc = MuPdfDocument.openFile(epubPath);
      try {
        // Step 1: Layout at 10pt font
        doc.layout(width: 400, height: 800, em: 10.0);
        final initialPages = doc.pageCount;
        expect(initialPages, greaterThan(1000));

        // Step 2: Pick a location and create a bookmark
        final loc50 = doc.locationFromPage(50);
        final bookmark = doc.makeBookmark(loc50);
        expect(bookmark, isNonZero);

        // Immediate lookup matches
        final resolvedBefore = doc.lookupBookmark(bookmark);
        expect(resolvedBefore.chapter, equals(loc50.chapter));

        // Step 3: Re-layout at 20pt font (font size doubled -> pagination changes)
        doc.layout(width: 400, height: 800, em: 20.0);
        final newPages = doc.pageCount;
        expect(newPages, greaterThan(initialPages));

        // Step 4: Lookup bookmark in the newly laid out document
        final resolvedAfter = doc.lookupBookmark(bookmark);
        expect(resolvedAfter.chapter, equals(loc50.chapter));
        expect(resolvedAfter.page, greaterThanOrEqualTo(0));

        // Verify page can be loaded at the restored location
        final page = doc.loadChapterPage(
          resolvedAfter.chapter,
          resolvedAfter.page,
        );
        try {
          final words = page.extractWords();
          expect(words, isNotEmpty);
        } finally {
          page.dispose();
        }
      } finally {
        doc.dispose();
      }
    });
  });
}

/// Generates a valid 2-page PDF 1.4 with text, an internal link, and an external link.
Uint8List _buildTestPdf() {
  String obj(int num, String body) => '$num 0 obj\n$body\nendobj\n';

  final objects = <String>[
    obj(1, '<< /Type /Catalog /Pages 2 0 R >>'),
    obj(2, '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>'),
    obj(
      3,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents 5 0 R /Annots [6 0 R 7 0 R] '
      '/Resources << /Font << /F1 8 0 R >> >> >>',
    ),
    obj(
      4,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents 9 0 R /Resources << /Font << /F1 8 0 R >> >> >>',
    ),
    obj(5, _stream('BT /F1 24 Tf 72 700 Td (Hello MuPDF World) Tj ET')),
    obj(
      6,
      '<< /Type /Annot /Subtype /Link /Rect [72 600 300 640] '
      '/Border [0 0 0] /Dest [4 0 R /XYZ 0 792 null] >>',
    ),
    obj(
      7,
      '<< /Type /Annot /Subtype /Link /Rect [72 500 250 540] '
      '/Border [0 0 0] /A << /S /URI /URI (https://example.com) >> >>',
    ),
    obj(8, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'),
    obj(9, _stream('BT /F1 24 Tf 72 700 Td (Second Page) Tj ET')),
  ];

  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int, int>{};
  for (var i = 0; i < objects.length; i++) {
    offsets[i + 1] = out.length;
    out.write(objects[i]);
  }
  final xrefPos = out.length;
  final count = objects.length + 1;
  out.write('xref\n0 $count\n0000000000 65535 f \n');
  for (var n = 1; n < count; n++) {
    out.write('${offsets[n]!.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.write('trailer\n<< /Size $count /Root 1 0 R >>\n'
      'startxref\n$xrefPos\n%%EOF\n');
  return Uint8List.fromList(latin1.encode(out.toString()));
}

String _stream(String contents) {
  final bytes = latin1.encode(contents);
  return '<< /Length ${bytes.length} >>\nstream\n$contents\nendstream\n';
}
