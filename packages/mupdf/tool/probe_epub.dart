// ignore_for_file: avoid_print
import 'dart:io';

import 'package:mupdf/mupdf.dart';

void main() async {
  const epubPath =
      '/home/drkxo/Documents/Ebooks/Reverend Insanity/Reverend Insanity [c1-500].epub';
  final file = File(epubPath);
  if (!file.existsSync()) {
    print('ERROR: EPUB file not found at $epubPath');
    exit(1);
  }

  print('================================================================');
  print('          MuPDF EPUB In-Depth Probing & Capability Test         ');
  print('================================================================');
  print('Target: ${file.path}');
  print('Size: ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB\n');

  final sw = Stopwatch()..start();
  final doc = MuPdfDocument.openFile(file.path);
  final openTime = sw.elapsedMilliseconds;
  print('==> [1] Document Initialization & Metadata');
  print('  Opened in: ${openTime}ms');
  print('  isReflowable: ${doc.isReflowable}');
  print('  needsPassword: ${doc.needsPassword}');
  print('  chapterCount: ${doc.chapterCount}');

  for (final key in [
    'info:Title',
    'info:Author',
    'info:Creator',
    'info:Subject',
    'format',
    'encryption',
  ]) {
    final val = doc.metadata(key);
    if (val != null && val.isNotEmpty) {
      print('  metadata($key): $val');
    }
  }

  // Pre-layout page count
  print('  Pre-layout page count: ${doc.pageCount}');

  print('\n==> [2] Table of Contents & Outline Navigation');
  sw.reset();
  sw.start();
  final outline = doc.outline;
  final outlineTime = sw.elapsedMilliseconds;
  print('  Parsed ${outline.length} outline items in ${outlineTime}ms');

  if (outline.isNotEmpty) {
    print('  Sample outline entries (first 5 and last 3):');
    for (var i = 0; i < outline.length && i < 5; i++) {
      final it = outline[i];
      print('    [$i] Level ${it.level}: "${it.title}" -> chapter=${it.chapter}, page=${it.page}, uri="${it.uri}"');
    }
    if (outline.length > 5) {
      print('    ...');
      for (var i = outline.length - 3; i < outline.length; i++) {
        final it = outline[i];
        print('    [$i] Level ${it.level}: "${it.title}" -> chapter=${it.chapter}, page=${it.page}, uri="${it.uri}"');
      }
    }

    // URI Resolution test
    final firstUri = outline.firstWhere((o) => (o.uri?.isNotEmpty ?? false), orElse: () => outline.first);
    if (firstUri.uri != null && firstUri.uri!.isNotEmpty) {
      final resolved = doc.resolveUri(firstUri.uri!);
      print('  URI Resolution test: "${firstUri.uri}" -> resolved page: $resolved (item.page=${firstUri.page})');
    }
  }

  print('\n==> [3] Dynamic Layout, Viewports & Pagination');
  // Layout Benchmarks across viewports and font sizes
  final testLayouts = [
    {'name': 'Mobile Compact (390x844, 10pt)', 'w': 390.0, 'h': 844.0, 'em': 10.0},
    {'name': 'Mobile Standard (390x844, 14pt)', 'w': 390.0, 'h': 844.0, 'em': 14.0},
    {'name': 'Mobile Large Font (390x844, 20pt)', 'w': 390.0, 'h': 844.0, 'em': 20.0},
    {'name': 'Tablet Portrait (820x1180, 15pt)', 'w': 820.0, 'h': 1180.0, 'em': 15.0},
    {'name': 'Desktop Landscape (1200x800, 14pt)', 'w': 1200.0, 'h': 800.0, 'em': 14.0},
  ];

  for (final l in testLayouts) {
    sw.reset();
    sw.start();
    doc.layout(width: l['w'] as double, height: l['h'] as double, em: l['em'] as double);
    final elapsed = sw.elapsedMilliseconds;
    final pages = doc.pageCount;
    print('  - ${l['name']}: $pages pages (computed in ${elapsed}ms)');
  }

  // Standard Mobile layout for subsequent tests
  print('\n  Applying standard layout (400x800, 14pt)...');
  doc.layout(width: 400.0, height: 800.0, em: 14.0);
  final stdPageCount = doc.pageCount;
  print('  Total pages in 400x800: $stdPageCount');

  // Chapter page distribution sample
  print('  Chapter page counts (first 10 chapters):');
  for (var ch = 0; ch < doc.chapterCount && ch < 10; ch++) {
    final cp = doc.chapterPageCount(ch);
    print('    Chapter $ch: $cp pages');
  }

  // Bookmark stability across reflow
  print('\n==> [4] Bookmark Durability Across Layout Changes');
  final testLoc = doc.locationFromPage(25);
  final bookmark = doc.makeBookmark(testLoc);
  print('  Created bookmark at page 25 -> (chapter ${testLoc.chapter}, page ${testLoc.page}), markId=$bookmark');

  // Change layout radically (double font size)
  doc.layout(width: 400.0, height: 800.0, em: 24.0);
  final relaidPageCount = doc.pageCount;
  final restoredLoc = doc.lookupBookmark(bookmark);
  print('  Re-laid out with 24pt font (total pages: $stdPageCount -> $relaidPageCount)');
  print('  Bookmark resolved to: chapter ${restoredLoc.chapter}, page ${restoredLoc.page}');
  final restoredFlatPage = doc.pageFromLocation(restoredLoc);
  print('  Restored flat page index: $restoredFlatPage');

  // Restore standard layout
  doc.layout(width: 400.0, height: 800.0, em: 14.0);

  print('\n==> [5] HTML & SText Extraction Structure');
  // Probe page 0 (usually cover or title) and page 10 (chapter content)
  for (final pgIdx in [0, 1, 10]) {
    if (pgIdx >= doc.pageCount) continue;
    final page = doc.loadPage(pgIdx);
    try {
      final bb = page.boundBox;
      final text = page.extractText() ?? '';
      final htmlNoImg = page.extractHtml(preserveImages: false) ?? '';
      final htmlWithImg = page.extractHtml(preserveImages: true) ?? '';

      print('  --- Page $pgIdx (${bb.width.toStringAsFixed(1)} x ${bb.height.toStringAsFixed(1)}) ---');
      print('    Plain text length: ${text.length} chars');
      final textPreview = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      print('    Plain text preview: "${textPreview.length > 80 ? '${textPreview.substring(0, 80)}...' : textPreview}"');
      print('    HTML (no images) length: ${htmlNoImg.length} bytes');
      print('    HTML (with images) length: ${htmlWithImg.length} bytes');
      final hasDataUri = htmlWithImg.contains('data:image/');
      print('    Contains embedded base64 image: $hasDataUri');

      // Sample HTML snippet
      final snippet = htmlNoImg.length > 400 ? htmlNoImg.substring(0, 400) : htmlNoImg;
      print('    HTML Head snippet:\n${snippet.replaceAll('\n', '\n      ')}...');
    } finally {
      page.dispose();
    }
  }

  print('\n==> [6] CSS Styling & Dark Mode Capabilities');
  // Test publisher CSS vs custom CSS
  const userCssDarkMode = '''
    body {
      background-color: #121212 !important;
      color: #E0E0E0 !important;
      font-family: sans-serif !important;
      line-height: 1.8 !important;
      margin: 1.5em !important;
    }
    p {
      text-indent: 1.5em !important;
      margin-bottom: 0.8em !important;
    }
  ''';

  sw.reset();
  sw.start();
  doc.style(usePublisherCss: false, userCss: userCssDarkMode);
  doc.layout(width: 400.0, height: 800.0, em: 14.0);
  final styleTime = sw.elapsedMilliseconds;
  print('  Applied custom dark mode CSS & re-laid out in ${styleTime}ms');
  print('  Page count with custom CSS: ${doc.pageCount}');

  // Render a sample page to verify pixel colors in dark mode
  final darkPage = doc.loadPage(10);
  try {
    final rendered = darkPage.render(scaleX: 1.0, scaleY: 1.0, alpha: false);
    print('  Rendered dark mode page: ${rendered.width}x${rendered.height}, stride=${rendered.stride}');
    // Sample top-left corner pixel (should be dark: ~0x12)
    final r0 = rendered.pixels[0];
    final g0 = rendered.pixels[1];
    final b0 = rendered.pixels[2];
    print('  Pixel sample (top-left background): R=$r0, G=$g0, B=$b0 (Dark background confirmed: ${r0 < 50 && g0 < 50 && b0 < 50})');
  } finally {
    darkPage.dispose();
  }

  // Restore light publisher style
  doc.style(usePublisherCss: true, userCss: null);
  doc.layout(width: 400.0, height: 800.0, em: 14.0);
  final lightPage = doc.loadPage(10);
  try {
    final rendered = lightPage.render(scaleX: 1.0, scaleY: 1.0, alpha: false);
    final r0 = rendered.pixels[0];
    final g0 = rendered.pixels[1];
    final b0 = rendered.pixels[2];
    print('  Pixel sample in publisher style: R=$r0, G=$g0, B=$b0 (White/light background confirmed: ${r0 > 200 && g0 > 200 && b0 > 200})');
  } finally {
    lightPage.dispose();
  }

  print('\n==> [7] Structured Words, Coordinates & TTS Sync');
  final testPage = doc.loadPage(10);
  try {
    sw.reset();
    sw.start();
    final words = testPage.extractWords();
    final wordTime = sw.elapsedMicroseconds;
    print('  Extracted ${words.length} structured words in $wordTime\u03bcs');
    if (words.isNotEmpty) {
      print('  First 5 extracted words with bounding boxes:');
      for (var i = 0; i < words.length && i < 5; i++) {
        final w = words[i];
        print('    [$i] "${w.text}" -> [${w.x0.toStringAsFixed(1)}, ${w.y0.toStringAsFixed(1)}, ${w.x1.toStringAsFixed(1)}, ${w.y1.toStringAsFixed(1)}] (${w.width.toStringAsFixed(1)} x ${w.height.toStringAsFixed(1)})');
      }
    }

    print('\n==> [8] Text Search & Quads');
    // Search for a common term in Reverend Insanity
    for (final term in ['Fang Yuan', 'Gu', 'Moonlight', 'immortal']) {
      sw.reset();
      sw.start();
      final quads = testPage.searchQuads(term);
      final searchTime = sw.elapsedMicroseconds;
      print('  Search "$term" on page 10: ${quads.length} hits ($searchTime\u03bcs)');
      if (quads.isNotEmpty) {
        final q = quads.first;
        print('    Hit 0 quad: ul=(${q.ulX.toStringAsFixed(1)}, ${q.ulY.toStringAsFixed(1)}) lr=(${q.lrX.toStringAsFixed(1)}, ${q.lrY.toStringAsFixed(1)})');
      }
    }

    print('\n==> [9] Interactive Text Selection');
    if (words.length >= 6) {
      final wStart = words[1];
      final wEnd = words[5];
      final sel = testPage.selectText(
        MuPdfPoint(wStart.x0, wStart.y0 + 5),
        MuPdfPoint(wEnd.x1, wEnd.y1),
        mode: MuPdfSelectMode.words,
      );
      print('  Selected text between word "${wStart.text}" and "${wEnd.text}":');
      print('    Selected text: "${sel.text}"');
      print('    Selection quads count: ${sel.quads.length}');
      print('    Snapped start: ${sel.snappedStart}, Snapped end: ${sel.snappedEnd}');
    }

    print('\n==> [10] Display List & Vector Rendering Performance');
    sw.reset();
    sw.start();
    final dl = testPage.toDisplayList();
    final dlCreateTime = sw.elapsedMilliseconds;

    sw.reset();
    sw.start();
    final rendered1x = dl.render(scaleX: 1.0, scaleY: 1.0);
    final render1xTime = sw.elapsedMilliseconds;

    sw.reset();
    sw.start();
    final rendered2x = dl.render(scaleX: 2.0, scaleY: 2.0);
    final render2xTime = sw.elapsedMilliseconds;

    sw.reset();
    sw.start();
    final tile = dl.renderRect(
      x0: 50,
      y0: 50,
      x1: 250,
      y1: 250,
      scaleX: 2.0,
      scaleY: 2.0,
    );
    final tileTime = sw.elapsedMilliseconds;

    print('  Display List created in: ${dlCreateTime}ms');
    print('  DL Render 1x (400x800): ${render1xTime}ms, ${rendered1x.pixels.length ~/ 1024} KB');
    print('  DL Render 2x (800x1600): ${render2xTime}ms, ${rendered2x.pixels.length ~/ 1024} KB');
    print('  DL Render Rect/Tile (400x400): ${tileTime}ms, ${tile.pixels.length ~/ 1024} KB');

    dl.dispose();
  } finally {
    testPage.dispose();
  }

  print('\n==> [11] Image & Cover Page Inspection');
  // Check if page 0 or chapter 0 has images
  final page0 = doc.loadPage(0);
  try {
    final bb = page0.boundBox;
    final html = page0.extractHtml(preserveImages: true) ?? '';
    final hasImg = html.contains('<img') || html.contains('data:image/');
    print('  Page 0 bounds: ${bb.width} x ${bb.height}, contains image: $hasImg');
    final rendered = page0.render(scaleX: 1.0, scaleY: 1.0);
    print('  Page 0 rendered: ${rendered.width} x ${rendered.height}, stride=${rendered.stride}');
  } finally {
    page0.dispose();
  }

  doc.dispose();
  print('\n================================================================');
  print('                  Probe Complete & Successful                   ');
  print('================================================================');
}
